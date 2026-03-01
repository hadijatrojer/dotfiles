# Repository Guidelines

## Project Structure & Module Organization
This is a stow-style Linux dotfiles repo. Each top-level folder mirrors files under `$HOME`, inside nested `.config` paths.

- Window managers/compositors:
`hypr/.config/hypr/` (`hyprland.conf`, `hypridle.conf`, `theme.conf`)
- Panel/launcher/notifications/terminal:
`fuzzel/.config/fuzzel/`, `ghostty/.config/ghostty/`
- Shell/editor/tools:
`zsh/.zshrc`, `vscode/settings.json`, `btop/.config/btop/`
- Services/containers:
`systemd/.config/systemd/user/*.service|*.timer` plus `*.target.wants/` symlink trees, and `containers/.config/containers/systemd/postgres.container`
- Bootstrap/setup:
`fedora/setup-*.sh`, `fedora/flatpaks`, and helpers in `scripts/`

Important: many settings are only in nested `.config` directories, so hidden-aware scans are required.

## Build, Test, and Development Commands
There is no compiled build step; validate and deploy changes directly.

- `stow -nv <module>`: preview symlink changes (example: `stow -nv hypr`)
- `stow -v <module>`: apply a module into `$HOME`
- `rg --hidden --glob '!.git' '<pattern>'`: search nested dot-folders
- `find . -path ./.git -prune -o -type f -print | sort`: file scan including hidden paths
- `find systemd/.config/systemd/user -type l -ls`: inspect user-unit symlinks
- `bash -n fedora/setup-*.sh scripts/*.sh`: shell syntax check
- `python -m py_compile scripts/hypr-cheatsheet.py`: Python script check
- `systemd-analyze --user verify systemd/.config/systemd/user/*.service`: validate user units

## Coding Style & Naming Conventions
- Shell scripts: `#!/usr/bin/env bash` or `#!/bin/bash`, use `set -euo pipefail` for non-trivial scripts.
- Python: follow PEP 8, keep functions small and typed where practical.
- Indentation: 2 spaces in shell/JSONC/KDL where already used; 4 spaces in Python.
- File naming: lowercase with hyphens for scripts (`setup-hyprland.sh`), descriptive names for config files.

## Testing Guidelines
No formal test suite exists. Treat lint/syntax checks as required pre-PR validation.

- Run syntax checks for every touched script.
- For UI config updates (Hypr/Fuzzel), reload the target app and verify behavior manually.
- For systemd changes, run `systemctl --user daemon-reload` and test start/restart paths.

## Theming & Visual Consistency
- Start with `THEME.md` before changing colors; it documents where theme values are defined across the repo.
- Treat `hypr/.config/hypr/theme.conf` as the primary color source when updating Hypr-related theme values.
- Keep palette changes synchronized with `fuzzel/.config/fuzzel/fuzzel.ini` and your active compositor theme files.

## Commit & Pull Request Guidelines
Recent commits use short, imperative subjects (for example, `hypr tweaks`, `cleanup setup scripts`, `macchiato`).

- Keep commit subjects concise (roughly 2-6 words), lowercase is acceptable.
- Group related config changes in one commit; avoid mixing unrelated modules.
- PRs should include: purpose, affected modules/paths, manual verification steps, and screenshots for visual/theme changes.

## Security & Configuration Tips
- Never commit secrets, tokens, or machine-specific credentials.
- Keep host-specific paths, output names, and wallpaper paths parameterized or clearly documented.
- Prefer relative symlinks in `*.target.wants` where possible; avoid hardcoding machine-specific absolute paths.
- Prefer user services and local overrides instead of editing system-wide files directly.
