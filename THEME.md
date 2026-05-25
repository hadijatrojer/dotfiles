# Theme Guide

This repo currently uses a Catppuccin Latte palette across the desktop stack,
with Foot and Btop intentionally kept on Catppuccin Mocha.
Treat `sway/.config/sway/theme.conf` as the palette source of truth and propagate
changes outward from there.

## Source Of Truth

`sway/.config/sway/theme.conf`

- Defines the full named palette as Sway variables in `#RRGGBB` form.

Core shared values used elsewhere:

- Base background: `eff1f5`
- Foreground text: `4c4f69`
- Muted text: `6c6f85`, `5c5f77`
- Border and surface tones: `ccd0da`, `bcc0cc`, `9ca0b0`, `8c8fa1`
- Primary accents: `1e66f5`, `7287fd`, `ea76cb`, `179299`, `04a5e5`

## Where Theme Values Live

`sway/.config/sway/config`

- Imports the palette with `include ~/.config/sway/theme.conf`.
- Uses shared variables for active and inactive borders and focused text.
- Also contains non-palette visual behavior such as gaps, border widths, output
  layout, and window rules.

`foot/.config/foot/foot.ini`

- Intentionally uses Catppuccin Mocha instead of the shared Latte desktop palette.
- If you change the terminal palette, update:
  - `[colors-dark]` foreground/background and alpha
  - normal and bright ANSI mappings
  - selection and cursor colors
- Typography and window opacity also live here, so visual changes are not
  limited to colors.

`btop/.config/btop/btop.conf`

- Intentionally uses Catppuccin Mocha instead of the shared Latte desktop palette.
- Background transparency behavior is controlled separately by
  `theme_background`.

`btop/.config/btop/themes/catppuccin-mocha.theme`

- Contains the actual Btop color mapping.
- Uses the same Mocha palette, but the semantic mapping is Btop-specific
  rather than a direct one-to-one copy of Sway variable names.

`zsh/.zsh/tools.zsh`

- Shell startup is modular, but prompt colors are set from `zsh/.zsh/tools.zsh`.
- The prompt uses Latte-aligned accent, error, and toolbox colors.

DMS-managed shell surfaces

- DMS owns the launcher, lock screen, bar, and control-center visuals at
  runtime.
- This repo manages DMS plugins under `dms/.config/DankMaterialShell/plugins/`,
  but not the global DMS theme. Palette changes in this repo should stay
  synchronized with the local DMS theme separately.

## Update Workflow

When changing colors, keep the stack in sync in this order:

1. Update `sway/.config/sway/theme.conf`.
2. Update compositor references in `sway/.config/sway/config` if the
   semantics changed, not just the underlying palette values.
3. Mirror the Latte palette changes into:
   - `zsh/.zsh/tools.zsh` if the prompt accent should stay aligned
4. Update `foot/.config/foot/foot.ini` and
   `btop/.config/btop/themes/catppuccin-mocha.theme` separately if the Mocha
   terminal exceptions should also change.
5. Re-stow or reload the affected module and verify visually.
6. Restart DMS if shell-managed surfaces need to pick up the new palette.

## Format Conversions

The same color appears in different syntaxes depending on the target:

- Sway variable: `#1e66f5`
- Raw hex for alpha composition: `1e66f5`
- Foot hex: `89b4fa`

## Verification

- Sway: reload config and confirm borders, gaps, floating rules, and surfaces match.
- Foot: open a new terminal and verify background, cursor, and ANSI colors.
- Btop: start `btop` and confirm the custom theme still loads as expected.
- DMS: open the launcher, lock screen, or bar surfaces and verify they still
  fit the active palette.
- Zsh: open a normal shell and a toolbox shell to confirm prompt styling.

## Non-Theme Files

These paths are present in the repo but are not current palette sources:

- `vscode/settings.json`
- `fedora/setup-*.sh`
- `scripts/rclone-mount.sh`
- `containers/.config/containers/systemd/postgres.container`
- `systemd/.config/systemd/user/*`
