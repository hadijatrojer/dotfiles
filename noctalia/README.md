# Noctalia

Repo-managed Noctalia plugins live here.

## Current Plugin

- `hypr-shortcuts`: parses `hyprland.conf` and exposes the keybinding list
  through Noctalia IPC so `Super+H` can show the shortcuts popup.

The plugin is loaded by `scripts/open-hypr-shortcuts.sh`, which installs the
plugin symlink into the user config if needed and then toggles the popup.
