# Hyprland

This package owns the compositor configuration and the shared Catppuccin
Macchiato palette source at `.config/hypr/theme.conf`.

## Notes

- `hyprland.conf` is the behavioral entry point and imports `theme.conf`.
- Noctalia remains the primary launcher surface.
- `hyprland.conf` starts `~/.config/hypr/scripts/session-start`, which imports
  the session environment and starts the user `sway-session.target`.
- `~/.config/hypr/scripts/session-swayidle` defines the current idle, lock,
  dim, and DPMS behavior through `swayidle`.
