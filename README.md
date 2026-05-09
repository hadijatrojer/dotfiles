# Dotfiles

GNU Stow-based Linux dotfiles with a Sway + DMS desktop stack.

## Repository Shape

- Shared shell and terminal packages:
  `alacritty`, `btop`, `vscode`, `zsh`
- Desktop behavior:
  `dms`, `sway`
- Helper scripts:
  `scripts`
- Fedora-only user assets:
  `containers`, `dms`, `systemd`

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
  `alacritty`, `btop`, `scripts`, `sway`, `vscode`, `zsh`
- Fedora-only packages when running on Fedora:
  `containers`, `dms`, `systemd`

If you prefer raw GNU Stow commands:

```bash
stow -nv alacritty btop scripts sway vscode zsh
stow -nv containers dms systemd
```

## Setup Order

Typical Fedora + Sway flow:

1. `fedora/setup-base.sh`
2. `fedora/setup-sway.sh`
3. `fedora/setup-mise.sh`
4. `./stow-all.py --apply`
5. `systemctl --user daemon-reload`

If you use a Fedora toolbox for development, also run `fedora/setup-toolbox.sh`
inside the toolbox.

The base host package set is intentionally small. Daily-driver desktop and
session packages live in `fedora/sway-packages.sh` instead of being bundled
into the base system bootstrap.

Screen sharing depends on the user session bringing up `graphical-session.target`
and the portal backends, which are wired through `systemd/.config/systemd/user/`.
The DMS shell is started by `systemd/.config/systemd/user/dms.service` through
`sway-session.target`; repo-managed DMS plugins live under
`dms/.config/DankMaterialShell/plugins/`.

## Notes

- `THEME.md` documents the Catppuccin Latte desktop palette, plus the Alacritty
  and Btop Mocha exceptions, and the synchronization points across the desktop stack.
- Package-specific setup notes live next to the package when the workflow is
  non-obvious.
