# Scripts

Repo-managed helper scripts used by desktop workflows and user services.

## Scripts

- `rclone-mount.sh`: shared wrapper used by user services for rclone mounts
- `chatgpt-update`: creates or updates a dedicated Fedora Distrobox containing
  OpenAI's ChatGPT RPM and exports its desktop launcher
- `sensor-logger.py`: samples `sensors -j` and logs temps/power/voltage into a
  SQLite DB for later analysis. Driven by the `sensor-logger.timer` user unit
  (every 5 min); data lives at `~/.local/state/sensor-logger/sensors.db`.
  See [`SENSOR-LOGGER.md`](SENSOR-LOGGER.md) for the schema and query examples.
