# Sway

This package owns the Sway compositor configuration and session helper scripts.

## Notes

- `config` is the behavioral entry point for outputs, input, bindings, and
  window rules.
- `theme.conf` carries the shared Catppuccin Latte palette in Sway syntax.
- `scripts/session-start` imports the compositor environment and starts the user
  `sway-session.target`.
- `scripts/session-quit` stops `sway-session.target` before exiting Sway.
- Launcher, clipboard, lock, and keybinding browser integrations are handled
  through DMS IPC calls from `config`.
