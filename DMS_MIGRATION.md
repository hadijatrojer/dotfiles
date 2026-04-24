# DMS Migration Plan

Assumption: `DMS (dank)` replaces `noctalia-shell` as the desktop shell layer in this repo. The current Noctalia integration is concentrated in a few places, so this migration should be handled as a targeted swap rather than a full Sway rebuild.

Status: phase 1 is complete in the live session. DMS now starts with the session, the launcher and clipboard bindings work, lock works, and the Noctalia/swayidle session services are gone.
Known follow-up: keep `graphical-session.target` and the portal backends wired into the session, or screen sharing will not work.

## Current Integration Points

Noctalia is currently wired into:

- `sway/.config/sway/config`
  - launcher binding via `set $menu qs -c noctalia-shell ipc call launcher toggle`
  - shortcut bindings for launcher, emoji, clipboard, window switcher, and `swayShortcuts`
- `sway/.config/sway/scripts/session-swayidle`
  - idle, dim, lock, and DPMS behavior
  - lock command currently calls `qs -c noctalia-shell ipc call lockScreen lock`
- `systemd/.config/systemd/user/noctalia.service`
  - starts the shell process
- `systemd/.config/systemd/user/swayidle.service`
  - starts the idle manager
- `systemd/.config/systemd/user/sway-session.target`
  - currently wants both `noctalia.service` and `swayidle.service`
- `fedora/sway-packages.sh`
  - installs both `noctalia-shell` and `swayidle`
- `noctalia/.config/noctalia/`
  - repo-managed Noctalia settings and plugins

## What Noctalia Is Doing Today

In practice, Noctalia provides four main functions in this setup:

1. Launcher and related pickers:
   - app launcher
   - emoji picker
   - clipboard history
   - window switcher
2. Lock screen IPC
3. Bar and control center UI
4. Custom `sway-shortcuts` plugin for browsing Sway keybindings

## Recommended Migration Sequence

### 1. Define the replacement matrix

Before editing files, decide what replaces each Noctalia feature:

- launcher -> DMS launcher
- emoji picker -> DMS or a standalone picker
- clipboard history -> DMS or `cliphist` frontend
- window switcher -> DMS or Sway-native fallback
- lock screen -> DMS locker or `swaylock`
- bar/control center -> DMS UI
- `sway-shortcuts` -> drop, replace with a script, or reimplement later

This should be settled first so the Sway keybindings and systemd units can be migrated cleanly.

### 2. Remove idle-manager assumptions early

`swayidle` is a known removal candidate and does not need to survive the migration.

Planned changes:

- delete `sway/.config/sway/scripts/session-swayidle`
- delete `systemd/.config/systemd/user/swayidle.service`
- remove `swayidle.service` from `systemd/.config/systemd/user/sway-session.target`
- remove `swayidle` from `fedora/sway-packages.sh`

If DMS handles lock, suspend, DPMS, or screen-off behavior itself, document the new source of truth where that behavior lives.

### 3. Replace Sway bindings

Update `sway/.config/sway/config` so it no longer calls `qs -c noctalia-shell`.

Bindings to migrate:

- `set $menu ...`
- `$mod+space`
- `$mod+h`
- `$mod+e`
- `$mod+v`
- `$mod+Tab`

For each one, either:

- point it to a DMS command
- point it to a standalone tool
- remove it if the feature is no longer wanted

### 4. Swap the session service

Replace `systemd/.config/systemd/user/noctalia.service` with a DMS-managed user service if DMS is intended to be launched by systemd.

Planned changes:

- add `systemd/.config/systemd/user/dms.service` or equivalent
- update `systemd/.config/systemd/user/sway-session.target` to want `dms.service`
- remove `noctalia.service`

If DMS is not systemd-managed, then `sway-session.target` should stop owning shell startup entirely and startup should move to the appropriate Sway or DMS entry point.

### 5. Remove the Noctalia module

Once Sway bindings and user services no longer depend on Noctalia:

- remove the `noctalia/` module
- remove `noctalia-shell` from `fedora/sway-packages.sh`
- remove `fedora/etc/yum.repos.d/noctalia-shell.repo` if it exists only to support Noctalia packaging
- update README or setup docs that still mention `noctalia`

This should happen only after the rest of the session no longer references Noctalia.

### 6. Decide the fate of `sway-shortcuts`

The custom plugin in `noctalia/.config/noctalia/plugins/sway-shortcuts/` is useful only if the keybinding browser still matters after the migration.

Options:

- drop it completely
- replace it with a generated cheatsheet script or markdown doc
- reimplement it in DMS later if DMS has a plugin model worth using

Recommendation: do not block phase 1 on porting this plugin.

### 7. Validate in the right order

After changes are made:

- run `bash -n` on touched shell scripts
- run `systemd-analyze --user verify systemd/.config/systemd/user/*.service`
- run `stow -nv` for affected modules
- reload Sway and verify launcher behavior
- run `systemctl --user daemon-reload` if units changed
- test lock, suspend/resume, and screen on/off behavior manually

## Suggested Phase Split

### Phase 1: Functional migration

Target the minimum working desktop:

- DMS starts with the session
- primary launcher works
- lock screen works
- required clipboard or emoji workflow works
- `swayidle` is gone
- Noctalia services are gone

This phase is complete.

### Phase 2: Nice-to-have parity

Only after phase 1 is stable:

- restore any missing launcher submodes
- decide whether a bar/control center equivalent is needed
- replace or drop the `sway-shortcuts` plugin
- clean up leftover package, README, and theme references
- decide whether the keybind helper needs a DMS-side polish pass for friendlier labels or truncation

## Repo-Oriented Checklist

- [x] Decide the DMS command equivalents for launcher, clipboard, and lock
- [x] Remove `swayidle` script and user unit
- [x] Update `sway-session.target`
- [x] Replace Noctalia-driven Sway bindings
- [x] Add DMS user service if needed
- [x] Remove `noctalia.service`
- [x] Remove `noctalia-shell` package and repo references
- [x] Delete the `noctalia/` stow module
- [x] Update docs and stow instructions
- [x] Verify the migrated desktop manually

Next work:

- decide whether to add back emoji or window switching as DMS or standalone tools
- decide whether the helper should be polished upstream in DMS for shorter labels and friendlier names
- clean up any remaining historical references in the docs if you want the repo to read as DMS-first instead of migration-first
- keep the GTK/wlroots portal services enabled through the session target so screen sharing stays functional
