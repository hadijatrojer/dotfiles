#!/usr/bin/env bash

# shellcheck disable=SC2034
# Packages layered for this Sway desktop setup.
# Portable developer/userland CLIs live in setup-mise.sh instead.
sway_packages=(
  # Backlight control CLI used by desktop keybinds and shell controls.
  brightnessctl
  # Distrobox host integration for creating and entering mutable dev containers.
  distrobox
  # Dank Material Shell desktop layer for launcher, bar, and shell UI.
  dms
  # Wayland-native terminal emulator for the Sway session.
  foot
  # Font Awesome icon fonts used by desktop UI and status surfaces.
  fontawesome-fonts-all
  # Chrome browser layered on the host for desktop app integration.
  google-chrome-stable
  # Wayland screenshot capture tool used with slurp for region screenshots.
  grim
  # Sensor CLI used by status tools such as btop for CPU and board temperatures.
  lm_sensors
  # MPRIS media control CLI used by media keybind scripts.
  playerctl
  # Wayland region selector used with grim for interactive screenshots.
  slurp
  # SMART disk health CLI for checking drive errors, wear, and self-test results.
  smartmontools
  # Sway compositor and session entrypoint for the desktop.
  sway
  # Host udev rules for Steam Input virtual gamepads and controller access.
  steam-devices
  # Wayland output management CLI for display layout scripts and manual fixes.
  wlr-randr
  # XDG desktop portal backend for screen sharing and Wayland app integration.
  xdg-desktop-portal-wlr
  # Default-terminal chooser used by desktop apps that request a terminal.
  xdg-terminal-exec
)
