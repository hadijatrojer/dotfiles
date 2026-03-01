#!/usr/bin/env bash
set -euo pipefail

packages=(
  cava
  fastfetch
  fontawesome-fonts-all
  fuzzel
  ghostty
  grim
  hypridle
  hyprland
  hyprland-guiutils
  noctalia-shell
  slurp
  wlr-randr
  xdg-desktop-portal-hyprland
  xdg-terminal-exec
)

rpm-ostree install "${packages[@]}"
