# Cider Flatpak setup

Cider (`sh.cider.Cider`) registers the `cider`, `itms`, `itmss`, `music`, and
`itunes` URL schemes at startup. Configure those defaults on the host because a
sandboxed application cannot reliably update the host's MIME associations.

The setup also replaces Cider's unfiltered session bus socket with Flatpak's
filtered proxy and denies access to `org.freedesktop.Flatpak`. Cider's MPRIS
names and standard portal access remain available under the bundle and
Flatpak's normal policy.

## Install on a new machine

Cider is distributed as a single-file Flatpak **bundle** (no Flatpak remote),
gated behind a login, so the bundle is not vendored here.

1. Download `cider-vX.Y.Z-linux-x64.flatpak` from
   [Taproom](https://taproom.cider.sh).
2. Install it for the current user:
   ```bash
   flatpak install --user -y ~/Downloads/cider-vX.Y.Z-linux-x64.flatpak
   ```
3. Configure it:
   ```bash
   fedora/flatpak/cider/setup-cider.sh
   ```

The script is idempotent. Cider 4.0.9.1 ships Electron 43, whose Linux protocol
registration uses GIO rather than the `xdg-settings` command used by Electron
42 and earlier.

## Verify

```bash
for scheme in cider itms itmss music itunes; do
  printf '%-7s ' "$scheme"
  xdg-settings get default-url-scheme-handler "$scheme"
done

flatpak override --user --show sh.cider.Cider
```

Each handler should be `sh.cider.Cider.desktop`. The override should contain
`sockets=!session-bus`, `org.freedesktop.Flatpak=none`, and
`PATH=/app/bin:/usr/bin`, with no `cider-shims` filesystem grant.

Then launch Cider, play a track, confirm the MPRIS integration works, and open
an `itms://` or `music://` link to confirm that Cider receives it.

## Limitations

- Setup deliberately makes Cider the host default for all five schemes.
- Replacing the unfiltered session bus is stricter than Cider's bundle. An
  unlisted direct D-Bus integration would need its own narrow name grant.
- Cider's exported desktop file currently omits `x-scheme-handler/itunes`.
  Desktops that require the declared association may ignore that scheme.

## Upgrading Cider

```bash
flatpak install --user -y ~/Downloads/cider-vX.Y.Z-linux-x64.flatpak
fedora/flatpak/cider/setup-cider.sh
```

Re-running setup reasserts the host defaults and sandbox hardening.
