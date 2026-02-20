#!/usr/bin/env bash
set -euo pipefail

packages=(
  7zip
  automake
  binutils
  btop
  distrobox
  fd-find
  gcc
  gcc-c++
  gdu
  google-chrome-stable
  htop
  make
  rclone
  ripgrep
  stow
  tmux
  vim
  zsh
)

rpm-ostree install "${packages[@]}"
