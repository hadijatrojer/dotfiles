# sensor-logger

Periodically samples `sensors -j` and stores hardware readings (temperatures,
power, voltages, currents, fans) in a SQLite database for later analysis.

- **Script:** `scripts/sensor-logger.py`
- **Units:** `systemd/.config/systemd/user/sensor-logger.{service,timer}`
- **Cadence:** every 5 min (`OnUnitActiveSec=5min`, `OnBootSec=2min`)
- **Database:** `${XDG_STATE_HOME:-~/.local/state}/sensor-logger/sensors.db`
  (WAL mode)

## Data model

Every `*_input` subfeature reported by lm_sensors is captured and classified by
prefix into a `kind`/`unit`:

| prefix | kind    | unit |
|--------|---------|------|
| `temp` | temp    | C    |
| `power`| power   | W    |
| `in`   | voltage | V    |
| `curr` | current | A    |
| `fan`  | fan     | RPM  |
| (other)| other   | ""   |

Non-finite values (NaN/inf from sensor glitches) are dropped before insert.

### Storage tiers

Instead of a hard TTL, older data is progressively downsampled so long-term
history stays small while recent data keeps full resolution:

| table / span        | resolution | default retention        |
|---------------------|------------|--------------------------|
| `readings`          | raw, 5 min | 14 days                  |
| `readings_rollup` @ 3600  | hourly | 90 days                  |
| `readings_rollup` @ 86400 | daily  | forever (0 = keep)       |

On each run the script:
1. aggregates raw rows older than `RAW_TTL_DAYS` into hourly buckets, then deletes them;
2. aggregates hourly buckets older than `HOURLY_TTL_DAYS` into daily buckets, then deletes them;
3. optionally deletes daily buckets older than `DAILY_TTL_DAYS`.

Rollups store `mn` (min), `mx` (max), `sm` (sum) and `cnt` (count) — **not**
average. Sum+count is associative, so re-runs and hourly→daily merges stay
exact and idempotent. Compute the average at query time as `sm / cnt`; `mn`/`mx`
preserve the thermal envelope and outliers. Bucket boundaries are UTC-aligned
(`(ts / span) * span`), so daily buckets are UTC days, not local days.

### Tuning (env vars, set in the `.service`)

| variable                        | default | meaning                          |
|---------------------------------|---------|----------------------------------|
| `SENSOR_LOGGER_RAW_TTL_DAYS`    | 14      | raw → hourly cutoff (0 = keep raw forever) |
| `SENSOR_LOGGER_HOURLY_TTL_DAYS` | 90      | hourly → daily cutoff (0 = keep hourly forever) |
| `SENSOR_LOGGER_DAILY_TTL_DAYS`  | 0       | daily prune (0 = keep forever)   |
| `XDG_STATE_HOME`                | `~/.local/state` | DB parent directory     |

## Alerting

Each run checks the sampled temperatures and fires a desktop notification via
`notify-send`. Only temperatures are alerted (power/voltage safe limits are too
device-specific to generalise). Two thresholds give three severities, each with
a distinct `notify-send` urgency:

| severity | condition                 | urgency    | icon | note |
|----------|---------------------------|------------|------|------|
| warning  | `WARN_C <= temp < CRIT_C` | `normal`   | warn | times out |
| critical | `temp >= CRIT_C`          | `critical` | fire | persists until dismissed |
| recovery | dropped back below a level| `low`      | ok   | one-shot |

State is tracked per sensor in `alert_state` (`level`: 0=ok, 1=warn, 2=crit) so
notifications are not spammed every run:

- **escalation** (e.g. warn -> crit) alerts immediately, ignoring the cooldown.
- **steady** at a non-ok level re-reminds only after the cooldown for that level
  (`CRIT_COOLDOWN_S` for critical, `ALERT_COOLDOWN_S` otherwise).
- **de-escalation / recovery** requires the value to fall a full
  `TEMP_HYSTERESIS_C` below a level's entry threshold, which avoids flapping.

Notifications use friendly device labels (CPU, GPU, RAM, SSD, WiFi, Ethernet,
Mainboard) resolved from the chip name by prefix via `FRIENDLY_LABELS` in the
script; unmapped sensors fall back to `"<chip> <feature>"`.

If `notify-send` is not on `PATH` (e.g. headless run) alerting silently no-ops.

| variable                          | default | meaning                        |
|-----------------------------------|---------|--------------------------------|
| `SENSOR_LOGGER_ALERTS`            | 1       | set `0` to disable alerting    |
| `SENSOR_LOGGER_TEMP_WARN_C`       | 85      | warning threshold (C)          |
| `SENSOR_LOGGER_TEMP_CRIT_C`       | 95      | critical threshold (C)         |
| `SENSOR_LOGGER_TEMP_HYSTERESIS_C` | 5       | drop below level-this to leave it |
| `SENSOR_LOGGER_ALERT_COOLDOWN_S`  | 1800    | repeat interval for warnings   |
| `SENSOR_LOGGER_CRIT_COOLDOWN_S`   | 300     | repeat interval for criticals  |

## Schema versioning & migrations

The schema version is tracked with SQLite's `PRAGMA user_version`. On each run,
`init_db` applies only the migrations newer than the DB's current version, each
in its own transaction, so **existing data is preserved across upgrades** (no
more `rm` needed once the DB holds real history).

To evolve the schema:

1. Append a new function to the `MIGRATIONS` list in `sensor-logger.py`. Index
   `i` upgrades the DB from version `i` to `i+1` (so `MIGRATIONS[0]` builds v1).
2. Write it as additive DDL (`ALTER TABLE` / `CREATE TABLE`); **never edit or
   reorder an already-released migration** or drop data.
3. `SCHEMA_VERSION` is derived from the list length automatically.

A DB whose `user_version` is *newer* than the script supports aborts with a
clear error rather than risking corruption.

## Schema

```sql
CREATE TABLE readings (
    ts       INTEGER NOT NULL,  -- unix epoch seconds (UTC)
    chip     TEXT    NOT NULL,  -- e.g. k10temp-pci-00c3, amdgpu-pci-7500
    adapter  TEXT,              -- lm_sensors adapter string
    feature  TEXT    NOT NULL,  -- e.g. Tctl, edge, Composite, temp1
    kind     TEXT    NOT NULL,  -- temp | power | voltage | current | fan | other
    value    REAL    NOT NULL,
    unit     TEXT               -- C | W | V | A | RPM
);
CREATE INDEX idx_readings_ts ON readings(ts);
CREATE INDEX idx_readings_chip_feature_ts ON readings(chip, feature, ts, value);

CREATE TABLE readings_rollup (
    span    INTEGER NOT NULL,   -- bucket width in seconds (3600 / 86400)
    bucket  INTEGER NOT NULL,   -- bucket start: (ts / span) * span (UTC)
    chip    TEXT    NOT NULL,
    feature TEXT    NOT NULL,
    kind    TEXT    NOT NULL,
    unit    TEXT,
    mn      REAL    NOT NULL,   -- min value in bucket
    mx      REAL    NOT NULL,   -- max value in bucket
    sm      REAL    NOT NULL,   -- sum of values (avg = sm / cnt)
    cnt     INTEGER NOT NULL,   -- number of samples
    PRIMARY KEY (span, chip, feature, bucket)
);
CREATE INDEX idx_rollup_span_bucket ON readings_rollup(span, bucket);

CREATE TABLE alert_state (
    chip        TEXT    NOT NULL,
    feature     TEXT    NOT NULL,
    level       INTEGER NOT NULL,  -- 0=ok, 1=warn, 2=crit
    last_notify INTEGER NOT NULL,  -- unix ts of last notification
    PRIMARY KEY (chip, feature)
);
```

## Common queries

Identify what sensors exist:

```sql
SELECT DISTINCT chip, feature, kind, unit FROM readings ORDER BY chip, feature;
```

Common `chip`/`feature` pairs on this host:

| component | chip                    | feature              |
|-----------|-------------------------|----------------------|
| CPU       | `k10temp-pci-00c3`      | `Tctl`               |
| GPU       | `amdgpu-pci-7500`       | `edge`, `PPT`, `vddgfx` |
| DDR       | `spd5118-i2c-14-50/51`  | `temp1`              |
| SSD       | `nvme-pci-0400`         | `Composite`, `Sensor 1`, `Sensor 2` |
| WiFi      | `iwlwifi_1-virtual-0`   | `temp1`              |
| NIC       | `r8169_0_100:00-mdio-0` | `temp1`              |

Raw time series for one sensor (uses the covering index, no sort):

```sql
SELECT datetime(ts, 'unixepoch', 'localtime') AS t, value
FROM readings
WHERE chip = 'k10temp-pci-00c3' AND feature = 'Tctl'
ORDER BY ts;
```

Recent snapshot (all sensors, latest sample):

```sql
SELECT chip, feature, kind, value, unit
FROM readings
WHERE ts = (SELECT max(ts) FROM readings)
ORDER BY kind, chip;
```

Daily min/max/avg from rollups (long-term trend):

```sql
SELECT date(bucket, 'unixepoch', 'localtime') AS day,
       mn AS min, mx AS max, sm / cnt AS avg
FROM readings_rollup
WHERE span = 86400 AND chip = 'k10temp-pci-00c3' AND feature = 'Tctl'
ORDER BY bucket;
```

Unified view across raw + rollups (approximate, for whole-history charts): query
`readings` for the recent window and `readings_rollup` for older periods, using
`sm / cnt` as the value for rolled-up buckets and `bucket` as the timestamp.

## From the shell

```sh
DB=~/.local/state/sensor-logger/sensors.db
sqlite3 "$DB" -header -column "SELECT DISTINCT chip, feature FROM readings;"
```
