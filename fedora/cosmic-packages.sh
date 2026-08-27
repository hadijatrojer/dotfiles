#!/usr/bin/env bash

# shellcheck disable=SC2034
# Minimal host layers used with Fedora COSMIC Atomic.
# The COSMIC desktop and its terminal, portals, screenshot tool, settings, and
# shell components are supplied by the base image. Shared host tooling remains
# in base-packages.sh.
cosmic_packages=(
  # Native Chrome keeps the existing Google Meet and screen-sharing path while
  # COSMIC is evaluated, without adding Flatpak sandboxing as another variable.
  google-chrome-stable
  # Host sensor tools used by scripts/sensor-logger.py.
  lm_sensors
  smartmontools
  # Host udev rules for Steam Input virtual gamepads and controller access.
  steam-devices
)
