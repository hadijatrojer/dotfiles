# DMS

This package contains repo-managed Dank Material Shell plugins.

## Layout

- `.config/DankMaterialShell/plugins/keybindActions/`: launcher action for Sway
  keybinding help
- `.config/DankMaterialShell/plugins/windowSwitcher/`: launcher action for
  window switching

## Notes

- DMS itself is started by `systemd/.config/systemd/user/dms.service` as part of
  `sway-session.target`.
- Sway invokes DMS features through `dms ipc ...` commands in
  `sway/.config/sway/config`.
- Global DMS theme settings are not currently managed by this repo.
