#!/usr/bin/env python3
"""Log sensor readings from `sensors -j` into a SQLite database.

Captures temperature, power and voltage inputs from every chip reported by
lm_sensors (CPU/k10temp, GPU/amdgpu, DDR/spd5118, SSD/nvme, wifi, nic, etc.)
so the data can be analyzed later. Intended to be run periodically by a
systemd user timer.

Storage uses tiered downsampling instead of a hard TTL:

  * `readings`         raw samples, kept for RAW_TTL_DAYS.
  * `readings_rollup`  aggregated buckets (min/max/sum/count) at two spans:
                       hourly (3600s) and daily (86400s).

On each run, raw rows past RAW_TTL_DAYS are aggregated into hourly buckets and
deleted; hourly buckets past HOURLY_TTL_DAYS are aggregated into daily buckets
and deleted. Daily buckets are kept forever by default. Storing sum+count
(rather than avg) keeps the aggregation associative, so re-rolling and
hourly->daily merges stay exact and idempotent. Query-time average is sm/cnt;
mn/mx preserve the thermal envelope and outliers.
"""

from __future__ import annotations

import json
import math
import os
import sqlite3
import subprocess
import sys
import time
from pathlib import Path


def state_dir() -> Path:
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    d = Path(base) / "sensor-logger"
    d.mkdir(parents=True, exist_ok=True)
    return d


DB_PATH = state_dir() / "sensors.db"

HOUR = 3600
DAY = 86400


def _env_float(name: str, default: float) -> float:
    raw = os.environ.get(name)
    if raw is None:
        return default
    try:
        return float(raw)
    except ValueError:
        print(
            f"sensor-logger: invalid {name}={raw!r}, using default {default}",
            file=sys.stderr,
        )
        return default


# Retention tiers (in days). A value <= 0 disables that stage:
#   RAW_TTL_DAYS=0     -> never roll raw into hourly (keep raw forever)
#   HOURLY_TTL_DAYS=0  -> never roll hourly into daily
#   DAILY_TTL_DAYS=0   -> keep daily buckets forever (default)
RAW_TTL_DAYS = _env_float("SENSOR_LOGGER_RAW_TTL_DAYS", 14)
HOURLY_TTL_DAYS = _env_float("SENSOR_LOGGER_HOURLY_TTL_DAYS", 90)
DAILY_TTL_DAYS = _env_float("SENSOR_LOGGER_DAILY_TTL_DAYS", 0)

# Desktop alerting via notify-send. Only temperatures are alerted by default
# because power/voltage safe limits are too device-specific to generalise.
# Two thresholds give three severities: ok < warn <= temp < crit <= temp.
#   SENSOR_LOGGER_ALERTS=0            -> disable alerting entirely
#   SENSOR_LOGGER_TEMP_WARN_C=85     -> warning threshold (C)
#   SENSOR_LOGGER_TEMP_CRIT_C=95     -> critical threshold (C)
#   SENSOR_LOGGER_TEMP_HYSTERESIS_C=5-> must drop this far below a level to leave it
#   SENSOR_LOGGER_ALERT_COOLDOWN_S   -> min seconds between repeat alerts (warn)
#   SENSOR_LOGGER_CRIT_COOLDOWN_S    -> min seconds between repeat alerts (crit)
ALERTS_ENABLED = os.environ.get("SENSOR_LOGGER_ALERTS", "1") not in ("0", "")
TEMP_WARN_C = _env_float("SENSOR_LOGGER_TEMP_WARN_C", 85.0)
TEMP_CRIT_C = _env_float("SENSOR_LOGGER_TEMP_CRIT_C", 95.0)
TEMP_HYSTERESIS_C = _env_float("SENSOR_LOGGER_TEMP_HYSTERESIS_C", 5.0)
ALERT_COOLDOWN_S = int(_env_float("SENSOR_LOGGER_ALERT_COOLDOWN_S", 1800))
CRIT_COOLDOWN_S = int(_env_float("SENSOR_LOGGER_CRIT_COOLDOWN_S", 300))

# Severity levels stored in alert_state.level
LEVEL_OK = 0
LEVEL_WARN = 1
LEVEL_CRIT = 2

# Friendly device labels for notifications. Matched by chip-name prefix (the
# lm_sensors PCI/bus suffix varies per host); feature-specific overrides win
# over the chip-wide default. Falls back to "<chip> <feature>" if unmatched.
FRIENDLY_LABELS = {
    "k10temp": {None: "CPU"},
    "coretemp": {None: "CPU"},
    "zenpower": {None: "CPU"},
    "amdgpu": {None: "GPU"},
    "nouveau": {None: "GPU"},
    "radeon": {None: "GPU"},
    "spd5118": {None: "RAM"},
    "jc42": {None: "RAM"},
    "nvme": {None: "SSD"},
    "iwlwifi": {None: "WiFi"},
    "r8169": {None: "Ethernet"},
    "acpitz": {None: "Mainboard"},
}


def friendly_name(chip: str, feature: str) -> str:
    """Map a (chip, feature) pair to a human-friendly device label."""
    for prefix, features in FRIENDLY_LABELS.items():
        if chip.startswith(prefix):
            return features.get(feature) or features.get(None) or f"{chip} {feature}"
    return f"{chip} {feature}"


# subfeature prefix -> (kind, unit)
PREFIX_UNITS = {
    "temp": ("temp", "C"),
    "power": ("power", "W"),
    "in": ("voltage", "V"),
    "curr": ("current", "A"),
    "fan": ("fan", "RPM"),
}


def classify(subfeature: str) -> tuple[str, str] | None:
    """Return (kind, unit) for an *_input subfeature, else None."""
    if not subfeature.endswith("_input"):
        return None
    for prefix, (kind, unit) in PREFIX_UNITS.items():
        if subfeature.startswith(prefix):
            return kind, unit
    return ("other", "")


def read_sensors() -> dict:
    out = subprocess.run(
        ["sensors", "-j"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    # sensors sometimes emits stray output; try to parse the JSON portion.
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        start = out.find("{")
        end = out.rfind("}")
        if start != -1 and end != -1:
            return json.loads(out[start : end + 1])
        raise


def collect_rows(data: dict, ts: int) -> list[tuple]:
    rows = []
    for chip, chip_data in data.items():
        if not isinstance(chip_data, dict):
            continue
        adapter = chip_data.get("Adapter", "")
        for feature, feature_data in chip_data.items():
            if not isinstance(feature_data, dict):
                continue
            for subfeature, value in feature_data.items():
                kind_unit = classify(subfeature)
                if kind_unit is None:
                    continue
                if not isinstance(value, (int, float)) or not math.isfinite(value):
                    continue
                kind, unit = kind_unit
                rows.append((ts, chip, adapter, feature, kind, float(value), unit))
    return rows


def _notify(title: str, body: str, urgency: str = "critical") -> None:
    """Best-effort desktop notification; silently no-op if unavailable."""
    try:
        subprocess.run(
            ["notify-send", "-u", urgency, "-a", "sensor-logger", title, body],
            check=False,
        )
    except FileNotFoundError:
        pass


def _severity(value: float) -> int:
    """Map a temperature to a severity level using the two thresholds."""
    if value >= TEMP_CRIT_C:
        return LEVEL_CRIT
    if value >= TEMP_WARN_C:
        return LEVEL_WARN
    return LEVEL_OK


def _target_level(value: float, current: int) -> int:
    """Level to settle on, applying hysteresis when de-escalating.

    Escalation is immediate. De-escalation steps down one level at a time and
    only leaves a level once the value drops a full hysteresis band below that
    level's entry threshold, which avoids flapping around each boundary.
    """
    raw = _severity(value)
    if raw >= current:
        return raw
    # De-escalate one level at a time, honouring each level's hysteresis gate.
    level = current
    if level == LEVEL_CRIT and value <= TEMP_CRIT_C - TEMP_HYSTERESIS_C:
        level = LEVEL_WARN
    if level == LEVEL_WARN and value <= TEMP_WARN_C - TEMP_HYSTERESIS_C:
        level = LEVEL_OK
    return level


def check_alerts(conn: sqlite3.Connection, rows: list[tuple], now: int) -> None:
    """Notify on temperature severity changes, with hysteresis + cooldown.

    Three severities (ok/warn/crit) from two thresholds. Per (chip, feature):
      * escalation (higher level)        -> alert immediately
      * same non-ok level, past cooldown -> re-remind
      * de-escalation past hysteresis    -> lower-severity / recovery notice
    Critical uses -u critical (persistent) and a shorter cooldown.
    """
    if not ALERTS_ENABLED:
        return

    # Highest temp per sensor this run (row: ts,chip,adapter,feature,kind,value,unit)
    peak: dict[tuple[str, str], tuple[float, str]] = {}
    for _ts, chip, _adapter, feature, kind, value, unit in rows:
        if kind != "temp":
            continue
        key = (chip, feature)
        if key not in peak or value > peak[key][0]:
            peak[key] = (value, unit)

    state = {
        (c, f): (level, last)
        for c, f, level, last in conn.execute(
            "SELECT chip, feature, level, last_notify FROM alert_state"
        )
    }

    for (chip, feature), (value, unit) in peak.items():
        prev, last = state.get((chip, feature), (LEVEL_OK, 0))
        new = _target_level(value, prev)
        if new == prev:
            # steady state: only re-remind while hot, after the cooldown
            if new != LEVEL_OK:
                cooldown = CRIT_COOLDOWN_S if new == LEVEL_CRIT else ALERT_COOLDOWN_S
                if now - last >= cooldown:
                    _emit(chip, feature, value, unit, new, repeat=True)
                    _set_alert(conn, chip, feature, new, now)
            continue
        # level changed (escalate or de-escalate): notify and record
        _emit(chip, feature, value, unit, new, repeat=False)
        _set_alert(conn, chip, feature, new, now)
    conn.commit()


def _emit(
    chip: str, feature: str, value: float, unit: str, level: int, repeat: bool
) -> None:
    """Send a notification appropriate to the severity level."""
    name = friendly_name(chip, feature)
    if level == LEVEL_CRIT:
        verb = "still critical" if repeat else "CRITICAL"
        _notify(
            f"\U0001f525 {name} {verb}",
            f"{value:.1f}{unit} (>= {TEMP_CRIT_C:.0f}{unit})",
            urgency="critical",
        )
    elif level == LEVEL_WARN:
        verb = "still warm" if repeat else "warm"
        _notify(
            f"\u26a0\ufe0f {name} {verb}",
            f"{value:.1f}{unit} (>= {TEMP_WARN_C:.0f}{unit})",
            urgency="normal",
        )
    else:  # LEVEL_OK -> recovered
        _notify(
            f"\u2705 {name} recovered",
            f"{value:.1f}{unit}",
            urgency="low",
        )


def _set_alert(
    conn: sqlite3.Connection, chip: str, feature: str, level: int, now: int
) -> None:
    conn.execute(
        """
        INSERT INTO alert_state (chip, feature, level, last_notify)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(chip, feature) DO UPDATE SET
            level = excluded.level,
            last_notify = excluded.last_notify
        """,
        (chip, feature, level, now),
    )


def _migrate_v1(conn: sqlite3.Connection) -> None:
    """v1: raw readings, tiered rollups, and per-sensor alert state."""
    conn.execute(
        """
        CREATE TABLE readings (
            ts       INTEGER NOT NULL,
            chip     TEXT    NOT NULL,
            adapter  TEXT,
            feature  TEXT    NOT NULL,
            kind     TEXT    NOT NULL,
            value    REAL    NOT NULL,
            unit     TEXT
        )
        """
    )
    # Drives the raw->hourly rollup cutoff (WHERE ts < cutoff).
    conn.execute("CREATE INDEX idx_readings_ts ON readings(ts)")
    # Covering index for per-sensor time-series queries:
    #   SELECT ts, value ... WHERE chip=? AND feature=? ORDER BY ts
    # Serves the whole query from the index with no sort or table lookup.
    conn.execute(
        "CREATE INDEX idx_readings_chip_feature_ts "
        "ON readings(chip, feature, ts, value)"
    )

    # Aggregated buckets. sm/cnt (not avg) keep aggregation associative so
    # merges stay exact. avg = sm/cnt at query time.
    conn.execute(
        """
        CREATE TABLE readings_rollup (
            span    INTEGER NOT NULL,   -- bucket width in seconds (3600 / 86400)
            bucket  INTEGER NOT NULL,   -- bucket start: (ts / span) * span
            chip    TEXT    NOT NULL,
            feature TEXT    NOT NULL,
            kind    TEXT    NOT NULL,
            unit    TEXT,
            mn      REAL    NOT NULL,   -- min value in bucket
            mx      REAL    NOT NULL,   -- max value in bucket
            sm      REAL    NOT NULL,   -- sum of values (avg = sm / cnt)
            cnt     INTEGER NOT NULL,   -- number of samples
            PRIMARY KEY (span, chip, feature, bucket)
        )
        """
    )
    # Prune deletes filter on (span, bucket); primary key already covers
    # per-sensor time-series reads (span, chip, feature, bucket).
    conn.execute("CREATE INDEX idx_rollup_span_bucket ON readings_rollup(span, bucket)")

    # Per-sensor alert state, so we notify on threshold crossing (with
    # hysteresis) and re-remind only after a cooldown, instead of every run.
    conn.execute(
        """
        CREATE TABLE alert_state (
            chip        TEXT    NOT NULL,
            feature     TEXT    NOT NULL,
            level       INTEGER NOT NULL,  -- 0=ok, 1=warn, 2=crit
            last_notify INTEGER NOT NULL,  -- unix ts of last notification
            PRIMARY KEY (chip, feature)
        )
        """
    )


# Ordered schema migrations. Index i upgrades the DB from version i to i+1, so
# MIGRATIONS[0] creates the v1 schema. To evolve the schema, append a new
# function that ALTERs/creates without dropping existing data -- never edit an
# already-released migration. SCHEMA_VERSION is derived from the list length.
MIGRATIONS = [_migrate_v1]
SCHEMA_VERSION = len(MIGRATIONS)


def init_db(conn: sqlite3.Connection) -> None:
    """Apply any pending schema migrations, tracked via PRAGMA user_version.

    Existing data is preserved: each migration runs in its own transaction and
    only the migrations newer than the DB's current version are applied.
    """
    current = conn.execute("PRAGMA user_version").fetchone()[0]
    if current > SCHEMA_VERSION:
        raise RuntimeError(
            f"sensor-logger: DB schema v{current} is newer than supported "
            f"v{SCHEMA_VERSION}; upgrade the script or move the database aside."
        )
    for version in range(current, SCHEMA_VERSION):
        migrate = MIGRATIONS[version]
        migrate(conn)
        # PRAGMA can't be parameterised; version is an int we control.
        conn.execute(f"PRAGMA user_version = {version + 1}")
        conn.commit()


def roll_raw_to_hourly(conn: sqlite3.Connection, now: int) -> None:
    """Aggregate raw rows past RAW_TTL_DAYS into hourly buckets, then drop them."""
    if RAW_TTL_DAYS <= 0:
        return
    cutoff = now - int(RAW_TTL_DAYS * DAY)
    # INSERT + DELETE run in one implicit transaction, committed together.
    conn.execute(
        """
        INSERT INTO readings_rollup
            (span, bucket, chip, feature, kind, unit, mn, mx, sm, cnt)
        -- kind/unit are functionally dependent on (chip, feature), so the
        -- bare (non-aggregated) columns pick a consistent value per group.
        SELECT ?, (ts / ?) * ?, chip, feature, kind, unit,
               min(value), max(value), sum(value), count(*)
        FROM readings
        WHERE ts < ?
        GROUP BY (ts / ?) * ?, chip, feature
        ON CONFLICT(span, chip, feature, bucket) DO UPDATE SET
            mn  = min(readings_rollup.mn, excluded.mn),
            mx  = max(readings_rollup.mx, excluded.mx),
            sm  = readings_rollup.sm + excluded.sm,
            cnt = readings_rollup.cnt + excluded.cnt
        """,
        (HOUR, HOUR, HOUR, cutoff, HOUR, HOUR),
    )
    conn.execute("DELETE FROM readings WHERE ts < ?", (cutoff,))
    conn.commit()


def roll_hourly_to_daily(conn: sqlite3.Connection, now: int) -> None:
    """Aggregate hourly buckets past HOURLY_TTL_DAYS into daily, then drop them."""
    if HOURLY_TTL_DAYS <= 0:
        return
    cutoff = now - int(HOURLY_TTL_DAYS * DAY)
    # INSERT + DELETE run in one implicit transaction, committed together.
    conn.execute(
        """
        INSERT INTO readings_rollup
            (span, bucket, chip, feature, kind, unit, mn, mx, sm, cnt)
        -- kind/unit are functionally dependent on (chip, feature); bare
        -- columns pick a consistent value per group.
        SELECT ?, (bucket / ?) * ?, chip, feature, kind, unit,
               min(mn), max(mx), sum(sm), sum(cnt)
        FROM readings_rollup
        WHERE span = ? AND bucket < ?
        GROUP BY (bucket / ?) * ?, chip, feature
        ON CONFLICT(span, chip, feature, bucket) DO UPDATE SET
            mn  = min(readings_rollup.mn, excluded.mn),
            mx  = max(readings_rollup.mx, excluded.mx),
            sm  = readings_rollup.sm + excluded.sm,
            cnt = readings_rollup.cnt + excluded.cnt
        """,
        (DAY, DAY, DAY, HOUR, cutoff, DAY, DAY),
    )
    conn.execute(
        "DELETE FROM readings_rollup WHERE span = ? AND bucket < ?",
        (HOUR, cutoff),
    )
    conn.commit()


def prune_daily(conn: sqlite3.Connection, now: int) -> None:
    """Optionally drop daily buckets past DAILY_TTL_DAYS (0 = keep forever)."""
    if DAILY_TTL_DAYS <= 0:
        return
    cutoff = now - int(DAILY_TTL_DAYS * DAY)
    conn.execute(
        "DELETE FROM readings_rollup WHERE span = ? AND bucket < ?",
        (DAY, cutoff),
    )
    conn.commit()


def main() -> int:
    ts = int(time.time())
    try:
        data = read_sensors()
    except (
        subprocess.CalledProcessError,
        FileNotFoundError,
        json.JSONDecodeError,
    ) as e:
        print(f"sensor-logger: failed to read sensors: {e}", file=sys.stderr)
        return 1

    rows = collect_rows(data, ts)
    if not rows:
        print("sensor-logger: no sensor rows collected", file=sys.stderr)
        return 1

    conn = sqlite3.connect(DB_PATH)
    try:
        conn.execute("PRAGMA journal_mode=WAL")
        # Tolerate a concurrent/overlapping run instead of failing immediately.
        conn.execute("PRAGMA busy_timeout=5000")
        init_db(conn)
        conn.executemany(
            "INSERT INTO readings "
            "(ts, chip, adapter, feature, kind, value, unit) "
            "VALUES (?, ?, ?, ?, ?, ?, ?)",
            rows,
        )
        conn.commit()
        check_alerts(conn, rows, ts)
        roll_raw_to_hourly(conn, ts)
        roll_hourly_to_daily(conn, ts)
        prune_daily(conn, ts)
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    sys.exit(main())
