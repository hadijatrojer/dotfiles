#!/usr/bin/env bash

# shellcheck disable=SC2034
# Packages layered on top of Fedora Sway Atomic (Sericea) for this setup.
# Portable developer/userland CLIs live in setup-mise.sh instead.
sway_packages=(
  alacritty
  brightnessctl
  distrobox
  dms
  fontawesome-fonts-all
  google-chrome-stable
  grim
  playerctl
  slurp
  sway
  wlr-randr
  xdg-desktop-portal-wlr
  xdg-terminal-exec
)
