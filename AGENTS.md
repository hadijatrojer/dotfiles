# Repository Guidelines

## Project Structure & Module Organization
This is a GNU Stow-style Linux dotfiles repo. Each top-level directory maps to
files that end up under `$HOME`, usually inside nested hidden paths such as
`.config/`.

- Window manager and desktop behavior:
  `hypr/.config/hypr/` (`hyprland.conf`, `hypridle.conf`, `theme.conf`)
- Launcher and terminal:
  `alacritty/.config/alacritty/alacritty.toml`,
  `noctalia/.config/noctalia/plugins/hypr-shortcuts/`
- Shell and editor:
  `zsh/.zshrc`, `vscode/settings.json`
- System monitor:
  `btop/.config/btop/btop.conf`, `btop/.config/btop/themes/`
- User services:
  `systemd/.config/systemd/user/*.service`, `*.timer`, and `*.target.wants/`
- Containers:
  `containers/.config/containers/systemd/postgres.container`
- Bootstrap and helpers:
  `fedora/setup-*.sh`, package-list helpers in `fedora/`, and scripts in `scripts/`
  (`open-hypr-shortcuts.sh`, `rclone-mount.sh`, `toggle-workspace-layout.sh`)

Important: hidden-aware scans are required. Many important files live under
`.config/`, and symlink trees under `systemd/.config/systemd/user/*wants/`
matter just as much as the unit files themselves.

## Build, Test, and Development Commands
There is no compiled build. Validate the changed module directly, then stow it.

- `stow -nv <module>`: preview symlink changes for one module
- `stow -v <module>`: apply a module into `$HOME`
- `rg --hidden --glob '!.git' '<pattern>'`: search nested dotfiles quickly
- `find . -path ./.git -prune -o -type f -print | sort`: full file scan
- `find systemd/.config/systemd/user -type l -ls`: inspect user-unit symlinks
- `bash -n fedora/setup-*.sh scripts/*.sh`: syntax check shell scripts
- `find noctalia/.config/noctalia/plugins -type f -print | sort`: inspect repo-managed Noctalia plugins
- `systemd-analyze --user verify systemd/.config/systemd/user/*.service`:
  validate user service files

## Coding Style & Naming Conventions
- Shell scripts: use `#!/usr/bin/env bash` or `#!/bin/bash`; add
  `set -euo pipefail` for non-trivial scripts.
- Python: follow PEP 8, prefer small functions, add type hints where useful.
- Indentation: preserve the surrounding file style.
  Use 2 spaces in shell, JSONC, and INI-style files when that is the local
  convention; use 4 spaces in Python.
- File names: lowercase and descriptive; prefer hyphenated script names such as
  `setup-hyprland.sh`.
- Comments: keep them short and only where the config is otherwise hard to
  reason about.

## Testing Guidelines
No formal automated suite exists. Validation is per-file and per-module.

- Run syntax checks for every touched shell or Python script.
- For Hyprland changes, reload the config or restart the affected component and
  verify behavior manually.
- For Alacritty or Noctalia changes, open the app and verify appearance or
  behavior directly.
- For Noctalia plugin changes, restart Noctalia once if a new plugin or entry
  point was added.
- For theming work, read `THEME.md` first and keep palette changes synchronized
  across Hypr, Alacritty, Btop, Noctalia, and any shell prompt accents.
- For systemd changes, run `systemctl --user daemon-reload` and test the
  relevant unit start or restart path.
- For Stow-impacting changes, run `stow -nv <module>` before applying.

## Theming & Visual Consistency
- Start with `THEME.md` before editing colors, opacity, or typography.
- Treat `hypr/.config/hypr/theme.conf` as the palette source of truth.
- Keep Catppuccin Macchiato values aligned across:
  - `hypr/.config/hypr/theme.conf`
  - `alacritty/.config/alacritty/alacritty.toml`
  - `btop/.config/btop/themes/catppuccin-macchiato.theme`
  - `noctalia/.config/noctalia/plugins/` when a plugin introduces theme-aware UI
  - `zsh/.zsh/tools.zsh` when prompt accent colors change
- If a visual change is semantic rather than purely palette-based, document it
  where it lives instead of forcing it into `theme.conf`.

## Commit & Pull Request Guidelines
Recent commits use short, imperative subjects such as `hypr tweaks`,
`cleanup setup scripts`, and `macchiato`.

- Keep commit subjects concise, roughly 2 to 6 words.
- Lowercase subjects are acceptable and match current history.
- Group related config changes together; avoid mixing desktop, shell, and
  systemd work in one commit unless the change is intentionally cross-cutting.
- PRs should include the purpose, affected modules, manual verification steps,
  and screenshots for visible UI or theme changes.

## Security & Configuration Tips
- Never commit secrets, tokens, or machine-specific credentials.
- Prefer parameterized or documented paths for wallpapers, output names, and
  host-specific resources.
- Prefer relative symlinks in `*.target.wants/` where practical.
- Favor user services and repo-managed overrides instead of editing system-wide
  files directly.
