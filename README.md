# Dotfiles

GNU Stow-based Linux dotfiles with a Sway + DMS desktop stack.

## Repository Shape

- Shared shell and terminal packages:
  `btop`, `foot`, `vscode`, `zsh`
- Agent tooling:
  `pi` (pi coding-agent extensions), `skills` (portable agent skills)
- Desktop behavior:
  `dms`, `nautilus`, `sway`
- Helper scripts:
  `scripts`
- Fedora-only user assets:
  `containers`, `dms`, `nautilus`, `systemd`

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
./stow-all.py --update
./stow-all.py --apply --target "$HOME/test-home"
```

The helper applies:

- Common packages:
  `btop`, `foot`, `pi`, `scripts`, `skills`, `sway`, `vscode`, `zsh`
- Fedora-only packages when running on Fedora:
  `containers`, `dms`, `nautilus`, `systemd`

If you prefer raw GNU Stow commands:

```bash
stow -nv btop foot pi scripts skills sway vscode zsh
stow -nv containers dms nautilus systemd
```

## Setup Order

Typical Fedora + Sway flow:

1. `fedora/setup-base.sh`
2. `fedora/setup-sway.sh`
3. `fedora/setup-mise.sh`
4. `./stow-all.py --apply`
5. `systemctl --user daemon-reload`

For Fedora COSMIC Atomic, replace step 2 with
`fedora/setup-cosmic.sh`. COSMIC supplies its own terminal, shell, portals,
screenshot tool, and settings in the base image; the setup script adds only
the small set of required host integrations.

If you use a Fedora toolbox for development, also run `fedora/setup-toolbox.sh`
inside the toolbox.

The base host package set is intentionally small. Daily-driver desktop and
session packages live in `fedora/sway-packages.sh` instead of being bundled
into the base system bootstrap.

### ChatGPT desktop app

OpenAI's official RPM bootstraps its signed `openai-chatgpt` repository and
signing key during the initial installation:

```bash
sudo rpm-ostree install \
  https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm
```

After rebooting into that deployment, `stow-all.py` verifies that the package,
repository, and key are present. For ongoing maintenance, `./stow-all.py
--update` stages Fedora Atomic system updates—including ChatGPT—through the
normal `rpm-ostree upgrade` path. Reboot when a new deployment is created.

Screen sharing depends on the user session bringing up `graphical-session.target`
and the portal backends, which are wired through `systemd/.config/systemd/user/`.
The DMS shell is started by `systemd/.config/systemd/user/dms.service` through
`sway-session.target`; repo-managed DMS plugins live under
`dms/.config/DankMaterialShell/plugins/`.

## User Services

A few background user units run via `systemd/.config/systemd/user/` (timers
wired into `timers.target.wants/`):

- `sensor-logger.timer` (every 5 min) runs `scripts/sensor-logger.py` to log
  hardware sensor readings (CPU/GPU/DDR/SSD temps, power, voltages) into a
  SQLite DB at `~/.local/state/sensor-logger/sensors.db`. Old data is
  progressively downsampled rather than dropped, and hot temperatures raise
  tiered `notify-send` alerts (warning/critical/recovery); see
  [`scripts/SENSOR-LOGGER.md`](scripts/SENSOR-LOGGER.md).

## Agent Tooling

- `pi` symlinks pi coding-agent extensions into `~/.pi/agent/extensions/`, where
  pi auto-discovers them (with `/reload`). See [`pi/README.md`](pi/README.md).
  Set `BRAVE_SEARCH_API_KEY` in the shell profile to enable the `brave_search`
  tools.
- `skills` symlinks portable agent skills into `~/.agents/skills/`, read
  natively by pi and other Agent Skills-compatible agents.

## Notes

- `THEME.md` documents the Catppuccin Latte desktop palette, plus the Foot
  and Btop Mocha exceptions, and the synchronization points across the desktop stack.
- Package-specific setup notes live next to the package when the workflow is
  non-obvious.
