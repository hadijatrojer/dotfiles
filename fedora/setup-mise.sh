#!/usr/bin/env bash
set -euo pipefail

# Install mise if not already installed
if ! command -v mise >/dev/null 2>&1; then
  curl https://mise.run | sh
  # Add mise to PATH for current session
  export PATH="$HOME/.local/bin:$PATH"
fi

eval "$(mise activate bash)"

# Install tools via mise
mise use --global \
  bat@latest \
  btop@latest \
  eza@latest \
  fd@latest \
  fastfetch@latest \
  fzf@latest \
  gdu@latest \
  glow@latest \
  jj@latest \
  lazygit@latest \
  neovim@latest \
  node@24 \
  ripgrep@latest \
  shellcheck@latest \
  shfmt@latest \
  uv@latest \
  yazi@latest \
  zoxide@latest
