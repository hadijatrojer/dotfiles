# Fedora Setup

This directory holds Fedora-specific bootstrap scripts and shared package lists
for the host setup.

## Setup Flow

Typical order:

1. Run `fedora/setup-base.sh` on the host.
2. Run `fedora/setup-hyprland.sh` on the host.
3. Run `fedora/setup-mise.sh` to install userland tools.
4. Optionally run `fedora/setup-toolbox.sh` inside a Fedora toolbox.
5. Run `./stow-all.py --apply` from the repo root.

## Package Lists

The installer scripts are thin wrappers around shared package lists:

- `base-packages.sh`: intentionally small host and toolbox CLI baseline
- `hyprland-packages.sh`: desktop/session packages for this Hyprland setup

That keeps package choices in one place while allowing different installers:

- `rpm-ostree install` on the host
- `dnf install -y` inside a toolbox

## Fedora Stow Packages

These packages are stowed only on Fedora:

- `containers`
- `systemd`

From the repo root, `./stow-all.py --apply` handles that automatically.

If you need the raw command:

```bash
stow -t ~ containers systemd
```
