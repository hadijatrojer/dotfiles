# Sway

This package owns the Sway compositor configuration and session helper scripts.

## Notes

- `config` is the behavioral entry point for outputs, input, bindings, and
  window rules.
- `theme.conf` carries the shared Catppuccin Macchiato palette in Sway syntax.
- `scripts/session-start` imports the compositor environment and starts the user
  `sway-session.target`.
- `scripts/session-quit` stops `sway-session.target` before exiting Sway.
- `scripts/session-swayidle` defines the current idle, lock, dim, and DPMS
  behavior through `swayidle`, with Noctalia handling the lock screen UI.
