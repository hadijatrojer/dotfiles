# Systemd

User units managed by this repo live under `.config/systemd/user/`.

## Units

- `sway-session.target`: groups desktop-session services started by the Sway
  session script after compositor environment variables are imported.
- `dms.service`: runs Dank Material Shell as part of `sway-session.target`.
- `gdrive.service`: mounts the `GDrive:` rclone remote at `~/GDrive`.
- `dropbox-personal.service`: mounts the `Personal Dropbox:` rclone remote at
  `~/Personal Dropbox`.
- `dropbox-work.service`: mounts the `Work Dropbox:` rclone remote at
  `~/Work Dropbox`.
- `rclone-warm-gdrive.service`: oneshot warmup for the `~/GDrive` mount. It
  runs `ls -A ~/GDrive` with a timeout so the first interactive shell listing
  is less likely to pay the cold Google Drive directory-listing cost.
- `rclone-warm-gdrive.timer`: starts the GDrive warmup shortly after user
  systemd startup and repeats it every 15 minutes.
- `flatpak-update.service`: oneshot Flatpak update with desktop notifications.
- `flatpak-update.timer`: daily timer for `flatpak-update.service`.
- `toolbox-dev.service`: starts the `dev` Podman container and stays active
  after the start command exits.

## Enabled Links

Repo-managed `*.wants/` symlinks opt units into user targets:

- `graphical-session.target.wants/`: rclone cloud mounts for the graphical
  session.
- `default.target.wants/`: startup services that should run outside the Sway
  session target, including the cloud mounts and `toolbox-dev.service`.
- `timers.target.wants/`: enabled user timers such as
  `rclone-warm-gdrive.timer`.
- `sockets.target.wants/`: socket units supplied by the OS, such as
  `podman.socket`.

## Notes

- These units are intended to be stowed on Fedora hosts through
  `./stow-all.py --apply`.
- After changing unit files, run:

```bash
systemctl --user daemon-reload
```

- Desktop startup services are grouped under `sway-session.target`, which is
  started from the Sway session after importing compositor environment
  variables. This repo attaches `dms.service` to that target and also pulls in
  `graphical-session.target` so portal backends can start for screen sharing.
- After first install, enable the units you actually want rather than assuming
  every unit should be active on every machine.

## Common Commands

```bash
systemctl --user daemon-reload
systemctl --user status gdrive.service rclone-warm-gdrive.timer
systemctl --user list-timers
systemctl --user start rclone-warm-gdrive.service
systemctl --user restart gdrive.service
journalctl --user -u gdrive.service -u rclone-warm-gdrive.service
```
