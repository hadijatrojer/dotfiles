Theme and color configuration audit
===================================

Scope
-----
- Searched all files including hidden directories under this repo, excluding `.git/`.

Summary
-------
- Multiple theming/color configurations are present across Fuzzel, Hyprland,
  Btop, and shell prompt settings.
- A shared Catppuccin Macchiato palette appears in `hypr/.config/hypr/theme.conf`,
  and `fuzzel/.config/fuzzel/fuzzel.ini`.

Theme and color sources
-----------------------

fuzzel/.config/fuzzel/fuzzel.ini
- Defines launcher typography and Catppuccin Macchiato colors for background, text,
  selection, match highlighting, and border.

hypr/.config/hypr/theme.conf
- Catppuccin Macchiato palette variables (RGB + hex variants) used by Hyprland configs.

hypr/.config/hypr/hyprland.conf
- Uses palette variables for border colors (`col.active_border`, `col.inactive_border`)
  and shadow color.
- Disables default Hyprland wallpapers/logos (visual theming behavior).

btop/.config/btop/btop.conf
- Sets `color_theme = "catppuccin-macchiato"` to load a custom theme.
- Themes can be overridden via `~/.config/btop/themes`.

btop/.config/btop/themes/catppuccin-macchiato.theme
- Custom Catppuccin Macchiato palette for Btop UI and graphs.

alacritty/.config/alacritty/alacritty.toml
- Terminal font, opacity, and Catppuccin Macchiato colors.

zsh/.zshrc
- Oh My Zsh theme set (`ZSH_THEME="robbyrussell"`).
- Toolbox prompt injects a blue segment (`PROMPT="%F{blue}..."`).

Not theme-related (checked)
---------------------------

vscode/settings.json
- No color theme or customization keys present.
- UI-adjacent only: `editor.fontFamily`, `window.zoomLevel`.

fedora/setup-hyprland.sh
fedora/setup-base.sh
fedora/setup-toolbox.sh
fedora/setup-mise.sh
scripts/rclone-mount.sh
vscode/podman-host
fedora/flatpaks
- No theme or color configuration present.
