# Fedora Setup

This directory holds Fedora-specific bootstrap scripts and shared package lists
for the host setup.

## Setup Flow

Typical order:

1. Run `fedora/setup-base.sh` on the host.
2. Run the desktop setup for the active Fedora Atomic image:
   - `fedora/setup-sway.sh` for Silverblue with Sway and DMS
   - `fedora/setup-cosmic.sh` for COSMIC Atomic
3. Run `fedora/setup-memory.sh` to configure zram and its VM policy.
4. Run `fedora/setup-mise.sh` to install userland tools.
5. Optionally run `fedora/setup-toolbox.sh` inside a Fedora toolbox.
6. Optionally run `fedora/setup-network.sh` to apply host network tweaks.
7. Run `./stow-all.py --apply` from the repo root.

## Host `/etc` Config

`/etc` is outside the Stow (`$HOME`) tree, so system files live under
`fedora/etc/` and are installed by dedicated setup scripts:

- `setup-network.sh`: installs `etc/NetworkManager/conf.d/wifi-powersave.conf`
  (disables Wi-Fi power save to stop Google Meet / call stutter) and restarts
  NetworkManager. Verify with `iw dev wlp2s0 get power_save`.
- `setup-memory.sh`: installs `etc/systemd/zram-generator.conf` and
  `etc/sysctl.d/99-zram.conf`. It applies the VM settings immediately; reboot
  once to recreate the zram device with the generator configuration.

## Package Lists

For per-app Flatpak setup, including the user-scoped Cider Apple Music client,
see [`flatpak/README.md`](./flatpak/README.md).

The installer scripts are thin wrappers around shared package lists:

- `base-packages.sh`: intentionally small host and toolbox bootstrap baseline
- `sway-packages.sh`: desktop/session packages for this Sway setup
- `cosmic-packages.sh`: minimal host additions for Fedora COSMIC Atomic
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
- Let the COSMIC Atomic base image provide the desktop, terminal, portals,
  screenshot tool, and settings. Its package list retains only native Chrome
  for Google Meet, sensor dependencies, and Steam device rules.

## Fedora Stow Packages

These packages are stowed only on Fedora:

- `chrome`
- `containers`
- `dms`
- `systemd`

From the repo root, `./stow-all.py --apply` handles that automatically.

If you need the raw command:

```bash
stow -t ~ chrome containers dms systemd
```

## Chrome GPU Hangs

On the Rembrandt iGPU (`1002:1681`), Chrome's default GL backend (radeonsi)
repeatedly hangs the GPU, especially during Google Meet with the camera on.
The kernel log shows `ring gfx_0.0.0 timeout ... Process chrome` followed by
a ring reset. Each reset restarts Chrome's GPU process, so video flickers or
stops.

The `chrome` package works around it:

- `.config/chrome-flags.conf` sets `--use-angle=vulkan` (ANGLE on RADV).
- `.local/bin/chrome-launch` reads that file, because the Fedora RPM ignores
  it.
- The `.local/share/applications/google-chrome.desktop` override and the
  Sway/swayward `Super+b` bindings launch Chrome through the wrapper. DMS's
  launcher reads the same override.
- `.local/bin/chrome-pwa-wrap` rewrites Chrome-generated web-app launchers
  (`chrome-*.desktop`: Meet, Chat, YouTube, ...) to use the wrapper. Chrome
  owns and rewrites those files, so they are not stowed. Instead,
  `chrome-pwa-wrap.path` in the `systemd` package reruns the script whenever
  `~/.local/share/applications` changes.

Flags only apply when the wrapper starts the first Chrome process, so quit
Chrome fully after changing them. Verify in `chrome://gpu`:
`GL implementation parts` should read `(gl=egl-angle,angle=vulkan)`.
Count hangs per boot with:

```bash
journalctl -k -b | grep 'ring gfx.*timeout'
```

If hangs continue, turn off Settings -> System -> "Use graphics acceleration
when available".
