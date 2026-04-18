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
mise use \
  bat@latest \
  eza@latest \
  fzf@latest \
  glow@latest \
  lazygit@latest \
  neovim@latest \
  node@latest \
  rust@latest \
  tree-sitter@latest \
  uv@latest \
  yazi@latest \
  github:zk-org/zk@latest \
  zoxide@latest
