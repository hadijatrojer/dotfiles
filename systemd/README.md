# Systemd

User units managed by this repo live under `.config/systemd/user/`.

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
