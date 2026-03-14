#!/usr/bin/env bash
set -euo pipefail

packages=(
  alacritty
  fastfetch
  fontawesome-fonts-all
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
