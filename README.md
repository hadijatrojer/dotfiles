# Dotfiles

GNU Stow-based Linux dotfiles with a Hyprland + Noctalia desktop stack.

## Repository Shape

- Shared shell and terminal packages:
  `alacritty`, `btop`, `vscode`, `zsh`
- Desktop behavior:
  `hypr`, `noctalia`
- Helper scripts:
  `scripts`
- Fedora-only user assets:
  `containers`, `systemd`

Most top-level directories are Stow packages. The main exception is `fedora/`,
which contains bootstrap scripts and package-list helpers rather than a Stow
package of its own.

## Stow

Use `./stow-all.py` to preview or apply the packages relevant to the current
system.

Examples:

```bash
./stow-all.py --check
./stow-all.py --apply
./stow-all.py --apply --target "$HOME/test-home"
```

The helper applies:

- Common packages:
  `alacritty`, `btop`, `hypr`, `noctalia`, `scripts`, `vscode`, `zsh`
- Fedora-only packages when running on Fedora:
  `containers`, `systemd`

If you prefer raw GNU Stow commands:

```bash
stow -nv alacritty btop hypr noctalia scripts vscode zsh
stow -nv containers systemd
```

## Setup Order

Typical Fedora + Hyprland flow:

1. `fedora/setup-base.sh`
2. `fedora/setup-hyprland.sh`
3. `fedora/setup-mise.sh`
4. `./stow-all.py --apply`
5. `systemctl --user daemon-reload`

If you use a Fedora toolbox for development, also run `fedora/setup-toolbox.sh`
inside the toolbox.

The base host package set is intentionally small. Daily-driver desktop and
session packages live in `fedora/hyprland-packages.sh` instead of being bundled
into the base system bootstrap.

## Notes

- `THEME.md` documents the Catppuccin Macchiato palette and synchronization
  points across the desktop stack.
- Package-specific setup notes live next to the package when the workflow is
  non-obvious.
