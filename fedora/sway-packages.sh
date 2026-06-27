#!/usr/bin/env bash

# shellcheck disable=SC2034
# Packages layered for this Sway desktop setup.
# Portable developer/userland CLIs live in setup-mise.sh instead.
sway_packages=(
  brightnessctl
  distrobox
  dms
  foot
  fontawesome-fonts-all
  google-chrome-stable
  grim
  playerctl
  slurp
  sway
  # Host udev rules for Steam Input virtual gamepads and controller access.
  steam-devices
  wlr-randr
  xdg-desktop-portal-wlr
  xdg-terminal-exec
)
