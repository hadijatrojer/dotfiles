# Theme Guide

This repo currently uses a Catppuccin Macchiato palette across the desktop stack.
Treat `hypr/.config/hypr/theme.conf` as the palette source of truth and propagate
changes outward from there.

## Source Of Truth

`hypr/.config/hypr/theme.conf`

- Defines the full named palette as Hyprland variables.
- Keeps each color in two forms:
  - `rgb(XXXXXX)` for Hypr config usage
  - `XXXXXX` as `*Alpha` values for places that need raw hex without `#`

Core shared values used elsewhere:

- Base background: `24273a`
- Foreground text: `cad3f5`
- Muted text: `a5adcb`, `b8c0e0`
- Border and surface tones: `363a4f`, `494d64`, `6e738d`, `8087a2`
- Primary accents: `8aadf4`, `b7bdf8`, `f5bde6`, `8bd5ca`, `91d7e3`

## Where Theme Values Live

`hypr/.config/hypr/hyprland.conf`

- Imports the palette with `source=~/.config/hypr/theme.conf`.
- Uses shared variables for active and inactive borders and shadow color.
- Also contains non-palette visual behavior such as rounding, blur, opacity,
  shadows, and animation tuning.

`alacritty/.config/alacritty/alacritty.toml`

- Duplicates the same palette in `#RRGGBB` form.
- If you change the base palette, update:
  - `colors.primary`
  - `colors.cursor`
  - `colors.selection`
  - `colors.normal`
  - `colors.bright`
  - `colors.dim`
- Typography and window opacity also live here, so visual changes are not
  limited to colors.

`btop/.config/btop/btop.conf`

- Selects the active theme with `color_theme = "catppuccin-macchiato"`.
- Background transparency behavior is controlled separately by
  `theme_background`.

`btop/.config/btop/themes/catppuccin-macchiato.theme`

- Contains the actual Btop color mapping.
- Uses the same Macchiato palette, but the semantic mapping is Btop-specific
  rather than a direct one-to-one copy of Hypr variable names.

`zsh/.zsh/tools.zsh`

- Shell startup is modular, but prompt colors are set from `zsh/.zsh/tools.zsh`.
- The prompt uses Macchiato-aligned accent, error, and toolbox colors.

`noctalia/.config/noctalia/plugins/`

- Repo-managed Noctalia plugins live here.
- The current Hypr shortcut popup is implemented by the
  `hypr-shortcuts` plugin.
- Plugin UIs may need to stay visually aligned with the main palette even when
  the color values are not duplicated one-to-one.
- The launcher surface itself is owned by Noctalia, so visual changes may come
  from the shell theme and not only from files in this repo.

## Update Workflow

When changing colors, keep the stack in sync in this order:

1. Update `hypr/.config/hypr/theme.conf`.
2. Update Hyprland references in `hypr/.config/hypr/hyprland.conf` if the
   semantics changed, not just the underlying palette values.
3. Mirror the palette changes into:
   - `alacritty/.config/alacritty/alacritty.toml`
   - `btop/.config/btop/themes/catppuccin-macchiato.theme`
   - `noctalia/.config/noctalia/plugins/` if a plugin has theme-specific UI
   - `zsh/.zsh/tools.zsh` if the prompt accent should stay aligned
4. Re-stow or reload the affected module and verify visually.
5. Restart Noctalia if a new plugin or launcher entry point was added.

## Format Conversions

The same color appears in different syntaxes depending on the target:

- Hypr variable: `rgb(8aadf4)`
- Raw hex for alpha composition: `8aadf4`
- Alacritty hex: `#8aadf4`

## Verification

- Hyprland: reload config and confirm borders, shadows, blur, and surfaces match.
- Alacritty: open a new terminal and verify background, cursor, and ANSI colors.
- Btop: start `btop` and confirm the custom theme still loads as expected.
- Noctalia: open the launcher or any repo-managed plugin UI and verify it still
  fits the active palette.
- Hypr shortcuts: press `Super+H` and confirm the Noctalia-backed popup still
  looks coherent with the active shell theme.
- Zsh: open a normal shell and a toolbox shell to confirm prompt styling.

## Non-Theme Files

These paths are present in the repo but are not current palette sources:

- `vscode/settings.json`
- `fedora/setup-*.sh`
- `scripts/rclone-mount.sh`
- `scripts/toggle-workspace-layout.sh`
- `containers/.config/containers/systemd/postgres.container`
- `systemd/.config/systemd/user/*`
