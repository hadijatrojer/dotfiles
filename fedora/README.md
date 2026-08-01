# Fedora Setup

This directory holds Fedora-specific bootstrap scripts and shared package lists
for the host setup.

## Setup Flow

Typical order:

1. Run `fedora/setup-base.sh` on the host.
2. Run `fedora/setup-sway.sh` on the host.
3. Run `fedora/setup-mise.sh` to install userland tools.
4. Optionally run `fedora/setup-toolbox.sh` inside a Fedora toolbox.
5. Optionally run `fedora/setup-network.sh` to apply host network tweaks.
6. Run `./stow-all.py --apply` from the repo root.

## Host `/etc` Config

`/etc` is outside the Stow (`$HOME`) tree, so system files live under
`fedora/etc/` and are installed by dedicated setup scripts:

- `setup-network.sh`: installs `etc/NetworkManager/conf.d/wifi-powersave.conf`
  (disables Wi-Fi power save to stop Google Meet / call stutter) and restarts
  NetworkManager. Verify with `iw dev wlp2s0 get power_save`.

## Package Lists

For per-app Flatpak setup, including the user-scoped Cider Apple Music client,
see [`flatpak/README.md`](./flatpak/README.md).

The installer scripts are thin wrappers around shared package lists:

- `base-packages.sh`: intentionally small host and toolbox bootstrap baseline
- `sway-packages.sh`: desktop/session packages for this Sway setup
- `setup-mise.sh`: portable userland and development CLIs that do not need to
  be host-layered

That keeps package choices in one place while allowing different installers:

- `rpm-ostree install` on the host
- `dnf install -y` inside a toolbox

## Package Split

- Keep the host base small: native build tools, `git`, `git-lfs`, `rclone`,
  `stow`, `tmux`, and `zsh`.
- Install comfort and developer tools with `mise` where practical, including
  `bat`, `btop`, `eza`, `fd`, `fastfetch`, `fzf`, `gdu`, `glow`, `jj`,
  `lazygit`, basic `neovim`, `node@24`, `ripgrep`, shell formatting/linting
  tools, `uv`, `yazi`, and `zoxide`.
- Keep Sway packages focused on desktop/session pieces that are launched by
  the compositor or DMS workflow.

## Fedora Stow Packages

These packages are stowed only on Fedora:

- `containers`
- `dms`
- `systemd`

From the repo root, `./stow-all.py --apply` handles that automatically.

If you need the raw command:

```bash
stow -t ~ containers dms systemd
```
