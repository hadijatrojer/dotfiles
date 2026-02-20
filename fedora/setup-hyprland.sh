#!/usr/bin/env bash
set -euo pipefail

packages=(
  cava
  clipman
  fastfetch
  fontawesome-fonts-all
  fuzzel
  ghostty
  grim
  hypridle
  hyprland
  hyprland-guiutils
  niri
  noctalia-shell
  slurp
  wlr-randr
  xdg-desktop-portal-hyprland
  xdg-terminal-exec
)

rpm-ostree install "${packages[@]}"
