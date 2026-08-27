# Evaluating Fedora COSMIC Atomic

This machine currently uses Fedora Silverblue with Sway and Dank Material
Shell (DMS). GNOME is a fallback for a small number of conventional desktop
tasks. COSMIC Atomic is being considered as a single integrated replacement
that retains Fedora's atomic system, Flatpak, and Toolbx workflow.

The aim of this evaluation is not to reproduce Sway exactly. Sway/i3 remains
substantially more capable for explicit tree manipulation, compositor IPC,
window queries, and scripted placement. The useful question is whether
COSMIC's integrated desktop replaces enough of Sway plus DMS to justify the
loss of that control.

Two workflows are hard requirements:

- Fast, reliable region screenshots with a frozen selection surface and a
  pasteable clipboard result
- Reliable Google Meet sharing of browser tabs, application windows, and full
  screens

COSMIC is not a viable replacement if either workflow is intermittently
unreliable. Annotation is useful but not mandatory; the stock screenshot tool
can replace Satty if its core capture workflow is dependable.

## Expected Result

Rebasing changes the base operating-system image. It does not replace the
user's home directory.

Expected to remain available:

- Home-directory data and this dotfiles repository
- Existing Stow symlinks and configuration files
- Flatpak applications and their data
- Toolbx and Podman containers
- SSH keys, browser profiles, and other user data
- User services, timers, mounts, and sockets
- A pinned Silverblue deployment for recovery

Expected to change:

- COSMIC replaces the Silverblue base desktop package set.
- Sway and DMS configuration remains in the home directory but may be inert
  because their executables are not part of the COSMIC image.
- Layered RPMs are carried across only when they resolve against the COSMIC
  image. Third-party repositories, drivers, and desktop packages are the most
  likely cause of a failed rebase.
- Both deployments share `/var/home`. COSMIC settings and application state
  written there remain visible after booting back into Silverblue.

The current service layout should not require pre-emptive changes. DMS starts
through `sway-session.target`; a COSMIC login does not start that target.
Cloud mounts, update timers, Podman, Toolbx, and sensor logging are shared
services and can run under either desktop.

## Safe Rebase Flow

Do not copy a COSMIC ref from an old guide without checking that it exists.
Release and update branch names can change.

1. Update Silverblue and reboot into the deployment that will be preserved.

   ```bash
   rpm-ostree upgrade
   systemctl reboot
   ```

2. Inspect the deployment and layered packages.

   ```bash
   rpm-ostree status -v
   ```

   Record the current origin, deployment checksum, layered packages, local
   packages, and active deployment index. Resolve questionable layers before
   the rebase rather than removing them blindly.

   The intended COSMIC host package set is the shared baseline in
   `fedora/base-packages.sh` plus the minimal additions in
   `fedora/cosmic-packages.sh`. COSMIC Terminal replaces Foot, and the COSMIC
   base image supplies the desktop shell, portals, settings, and screenshot
   components.

3. Pin the known-good active deployment. The active deployment is normally
   index `0`, but confirm it in the previous command.

   ```bash
   sudo ostree admin pin 0
   rpm-ostree status -v
   ```

4. Find the actual stable COSMIC Atomic ref for the installed Fedora release
   and architecture.

   ```bash
   uname -m
   ostree remote refs fedora | rg 'cosmic-atomic$'
   ```

   Use the matching stable Fedora release ref, not Rawhide, a nightly OCI
   image, or an unverified registry image. For example, a listed ref may have
   a shape such as:

   ```text
   fedora:fedora/44/x86_64/cosmic-atomic
   ```

   The output of `ostree remote refs` is authoritative; an `updates` component
   may be present in the real ref.

5. Stage the rebase using the exact ref found above.

   ```bash
   sudo rpm-ostree rebase <verified-cosmic-ref>
   rpm-ostree status -v
   ```

   A dependency-resolution failure does not replace the running deployment.
   Review the reported layered package or repository rather than forcing the
   transaction.

6. Reboot into COSMIC.

   ```bash
   systemctl reboot
   ```

7. Keep the pinned Silverblue deployment until the evaluation is complete.
   It can be selected from the bootloader. Do not unpin it merely because
   COSMIC boots successfully.

## First-Login Checks

Update the newly booted image before judging bugs that may already have been
fixed:

```bash
rpm-ostree upgrade
flatpak update
```

Confirm that the Sway shell is dormant:

```bash
systemctl --user is-active sway-session.target dms.service
systemctl --user --type=service | rg 'portal|dms|sway|cosmic'
```

`sway-session.target` and `dms.service` should be inactive. COSMIC and its
portal services are expected. If a Sway portal appears stale immediately
after the first transition, reboot once before modifying service definitions.

Then test the bread-and-butter desktop functions:

- Forget and re-pair the Bluetooth keyboard. Confirm COSMIC displays the
  generated passkey or PIN and accepts the code typed on the keyboard.
- Connect and reconnect Bluetooth audio, then confirm the intended PipeWire
  output and A2DP profile are selected.
- Apply an rpm-ostree update through COSMIC Store and confirm it stages a new
  deployment for reboot.
- Install or update a Flatpak through COSMIC Store.
- Check firmware discovery and updates through `fwupd`/COSMIC Settings.
- Test Wi-Fi, any VPN, printer/scanner devices, removable storage, and MTP.
- Test suspend, resume, lock, logout, reboot, and shutdown.
- Test Chrome, Electron applications, Google Meet, and screen sharing.
- Test both HDMI displays, mixed scaling, cold boot, hot-plug, and restoration
  after suspend.
- Open the rclone-mounted directories in COSMIC Files and Nautilus.

## Details Likely to Be Missed

This list deliberately excludes Sway's superior tree and window-manipulation
model.

### Clipboard history

DMS provides a first-class clipboard picker on `Super+V`. COSMIC does not
currently ship an equivalent integrated clipboard-history manager. Third-party
applets exist, but adopting one adds another separately maintained component.

### Night Light

COSMIC does not yet provide a mature, integrated colour-temperature/Night
Light control. Wayland workarounds depend on compositor support and are less
clean than a native implementation. This is the clearest missing conventional
desktop facility.

### Unified searchable launcher actions

The current DMS launcher combines applications with custom modes for clipboard
history, window selection, and searchable executable Sway keybindings. COSMIC
has an application launcher, window switching, and a graphical shortcut
editor, but does not reproduce this single extensible command surface. In
particular, the DMS `?` keybinding browser will be lost.

### Screenshot workflow

The current script uses Wayfreeze to freeze the desktop, Slurp for region
selection, Grim for capture, and Satty for optional annotation, clipboard
copying, and saving. COSMIC Screenshot provides the important core outcome:
a static desktop view, adjustable region/window/screen selection, and output
to the clipboard or the Screenshots directory.

Satty-level arrows, text, highlighting, drawing, blur, and redaction are not a
requirement for this migration. The stock tool is good enough if its selection
and clipboard path is fast and reliable. Do not initially attempt to port the
existing Wayfreeze/Slurp/Grim pipeline: those tools rely on wlroots-oriented
capture protocols that COSMIC does not expose in the same way.

The main risks are reported clipboard failures and incorrect output around
fractional or mixed scaling. Validate the stock tool with at least 20 real
captures:

- Capture regions on each display independently.
- Capture windows on each display.
- Capture a region that crosses the display boundary, if the UI permits it.
- Copy and paste into Chrome, a Google Meet chat, email, and an image editor.
- Save images and inspect their pixel dimensions and sharpness.
- Repeat after suspend/resume and after disconnecting/reconnecting a display.
- Take several captures in quick succession and verify every clipboard result.

Any recurring blank, stale, incorrectly scaled, or unpasteable capture is a
migration blocker. An occasional need for richer annotation is not.

### Mixed-scale multi-monitor polish

The current layout uses two HDMI displays at scales `1.0` and `1.875`.
Reported COSMIC rough edges include panel placement after monitor removal,
restoration of display arrangements, fractional-scale rendering, shell
surfaces after hot-unplug, and mixed-display animation. This is primarily a
hardware-specific validation item rather than a guaranteed failure.

### Screen sharing and portals

COSMIC has its own XDG desktop portal, but browser, Slack, Electron, and Flatpak
screen sharing has less accumulated testing than GNOME. The current Sway setup
has an explicitly configured and known-working wlr/GTK portal path. Chrome and
Google Meet deserve direct testing.

Google Meet is a hard requirement, so merely seeing the source picker once is
not sufficient. Run several real or test meetings and exercise every sharing
mode actually used:

- Share a Chrome tab, including tab audio when required.
- Share one application window and switch focus between applications.
- Share each full display independently.
- If offered, share a selected region and verify its scaling.
- Stop sharing and start a different share without leaving the meeting.
- Repeat after suspend/resume and after a monitor reconnect.
- Confirm the remote participant sees the correct source, full frame updates,
  cursor behavior, readable resolution, and no frozen or black frames.
- Confirm camera, microphone, Bluetooth audio, notifications, and screen
  sharing continue to coexist during a longer call.

Test with the actual Chrome installation and Flatpak/native packaging used in
daily work, because sandbox and portal behavior can differ. A failure that is
fixed only by restarting the portal, browser, or session counts as a blocker.

### Tray, notification, and applet resilience

COSMIC includes a status area, notification centre, calendar, media controls,
networking, Bluetooth, and audio controls. The concern is intermittent polish:
unresponsive tray menus, notification components failing to attach, audio
devices temporarily disappearing, VPN edge cases, and panel behavior after a
display disappears.

### Named audio-output shortcuts

The current `XF86Launch5` and `XF86Launch6` shortcuts select named outputs.
The Echo path additionally manages Bluetooth connection state and forces the
A2DP profile. COSMIC can perform ordinary audio selection through its UI but
will not recreate this workflow automatically. The existing script is mostly
desktop-independent and may be reusable through COSMIC custom shortcuts.

### File manager maturity

COSMIC Files is newer and less complete than Nautilus for advanced sorting,
search, properties, drag and drop, network locations, GVfs, MTP, bulk
operations, and extensions. Nautilus can remain the default file manager under
COSMIC; using COSMIC does not require replacing every GNOME application.

### Administrative and hardware edge cases

COSMIC Settings covers common Bluetooth, network, display, audio, power,
keyboard, user, locale, firmware, and application settings. GNOME remains more
battle-tested for unusual printers/scanners, colour profiles, smart cards,
online accounts, remote desktop, enterprise authentication, accessibility,
and some firmware or removable-media cases.

### Applet and extension ecosystem

DMS has a QML plugin surface already used by this repository. COSMIC supports
applets, but its APIs, documentation, ecosystem, and packaging are younger.
Rebuilding several DMS conveniences as COSMIC applets would reduce the benefit
of moving to an integrated, lower-maintenance desktop.

### Small ergonomic gaps

Potential paper cuts include a less mature emoji/symbol picker, fewer clock and
calendar options, uncommon media keys not being accepted by the shortcut
editor, less flexible lock/suspend combinations, inconsistent drag and drop,
and settings that exist in configuration files but not yet in the UI.

## Evaluation Period

Use COSMIC close to stock for two to three weeks. Recreate only essential
shortcuts initially. Keep a dated note of each fallback, workaround, crash,
or missing feature rather than relying on the general impression that the new
desktop feels better or worse.

Suggested checkpoints:

- Day 1: Bluetooth, updates, displays, audio, screenshot repetitions, Google
  Meet sharing, portals, suspend, and recovery
- Days 2-3: normal work, real meetings, screenshots, file handling, and media
- Week 1: count workarounds and inspect relevant user-session logs
- Weeks 2-3: decide whether remaining issues are habits, fixable gaps, or
  desktop-level blockers

Do not immediately rebuild the whole DMS experience. The point is to evaluate
COSMIC's integrated workflow, not to turn it into another hand-assembled shell.

## Decision Criteria

Move to COSMIC as the sole desktop when all of the following are true:

- Bluetooth keyboard passkey pairing is reliable.
- Mixed-scale displays survive boot, suspend, and reconnects.
- Stock COSMIC Screenshot reliably produces correctly scaled, pasteable region
  captures on both displays. Satty-equivalent annotation is not required.
- Google Meet reliably shares tabs, windows, and individual full displays
  across repeated calls without restarting portals, Chrome, or the session.
- COSMIC Store handles system and Flatpak updates reliably.
- Audio switching is acceptable, either in the UI or through the existing
  scripts.
- General clipboard history and Night Light have acceptable solutions.
- Missing DMS conveniences are less costly than maintaining Sway plus DMS.

Return to Sway for now when any of the following recur:

- Display, portal, input, or suspend failures disrupt normal work.
- Screenshots intermittently fail to copy, paste, or preserve the expected
  resolution on either display.
- A Google Meet share produces black/frozen frames, exposes the wrong source,
  or requires restarting a desktop component.
- Multiple third-party applets are required to make the shell usable.
- Clipboard history or Night Light lacks an acceptable solution.
- The integrated desktop still requires roughly as much custom maintenance as
  the existing setup.

If the blockers are COSMIC maturity rather than a fundamental workflow
mismatch, keep this document and reassess after later Fedora/COSMIC releases.

## References

- [Fedora COSMIC Atomic](https://fedoraproject.org/atomic-desktops/cosmic/)
- [Fedora Atomic Desktops](https://fedoraproject.org/atomic-desktops/)
- [COSMIC Epoch releases](https://github.com/pop-os/cosmic-epoch/releases)
- [COSMIC Settings](https://github.com/pop-os/cosmic-settings)
- [COSMIC applet issues](https://github.com/pop-os/cosmic-applets/issues)
- [COSMIC compositor IPC request](https://github.com/pop-os/cosmic-comp/issues/2391)
