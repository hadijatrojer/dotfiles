# Systemd

User units managed by this repo live under `.config/systemd/user/`.

## Notes

- These units are intended to be stowed on Fedora hosts through
  `./stow-all.py --apply`.
- After changing unit files, run:

```bash
systemctl --user daemon-reload
```

- After first install, enable the units you actually want rather than assuming
  every unit should be active on every machine.
