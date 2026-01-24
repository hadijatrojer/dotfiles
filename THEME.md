Theme and color configuration audit
===================================

Scope
-----
- Searched all files including hidden directories under this repo, excluding `.git/`.

Summary
-------
- Multiple theming/color configurations are present across Wofi, Waybar, Hyprland, Sway,
  Niri, Mako, and shell prompt settings.
- A shared Catppuccin Mocha palette appears in `hypr/.config/hypr/mocha.conf`,
  `wofi/.config/wofi/style.css`, and `mako/.config/mako/config`.

Theme and color sources
-----------------------

wofi/.config/wofi/style.css
- Defines a full Catppuccin Mocha palette via `@define-color`.
- Applies colors to window background, borders, text, selection, and input styling.

waybar/.config/waybar/style.css
- Defines a small palette (`darkgrey`, `white`, `warning`, `indigo1/2/3`, `resize`).
- Applies colors to the bar background, module text, critical/warning states, tooltips,
  and the indicator bar.

waybar/.config/waybar/config.jsonc
waybar/.config/waybar/config-niri.jsonc
- Calendar tooltip markup includes explicit hex colors for months, days, weeks,
  weekdays, and today.

hypr/.config/hypr/mocha.conf
- Catppuccin Mocha palette variables (RGB + hex variants) used by Hyprland configs.

hypr/.config/hypr/hyprland.conf
- Uses palette variables for border colors (`col.active_border`, `col.inactive_border`)
  and shadow color.
- Disables default Hyprland wallpapers/logos (visual theming behavior).

hypr/.config/hypr/hyprlock.conf
- Uses palette variables for lockscreen text, input field, and status colors.
- References wallpaper images per monitor.

hypr/.config/hypr/hyprpaper.conf
- Sets wallpapers for each monitor (visual theming).

hypr/.config/hypr/*.jpg
hypr/.config/hypr/*.png
- Wallpaper assets used by Hyprpaper/Hyprlock.

mako/.config/mako/config
- Notification colors for background, text, border, progress, and urgency levels
  (Catppuccin Mocha values).

sway/.config/sway/config
- Window decoration palette (Tokyo Night) for focused/urgent states.
- Sets cursor theme (`xcursor_theme macOS`) and wallpaper path.

sway/.config/sway/swaylock.conf
- Lockscreen colors (Tokyo Night palette).

sway/.config/sway/sway-focus-visual
- Uses opacity settings (focused vs unfocused) as a visual styling mechanism.

niri/.config/niri/config.kdl
- Focus ring, border, and shadow colors (hex values).

ghostty/.config/ghostty/config
- `background-opacity` set (visual theming).

zsh/.zshrc
- Oh My Zsh theme set (`ZSH_THEME="robbyrussell"`).
- Toolbox prompt injects a magenta segment (`PROMPT="%F{magenta}..."`).

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
scripts/restart-gdrive-dropbox.sh
vscode/podman-host
fedora/flatpaks
- No theme or color configuration present.
