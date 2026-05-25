#!/usr/bin/env bash

# shellcheck disable=SC2034
base_packages=(
  # Native build/link toolchain needed by source installs and mise plugins.
  binutils
  gcc
  gcc-c++
  make

  # Baseline repo and dotfile tooling.
  git
  git-lfs
  rclone
  stow
  tmux
  zsh
)
