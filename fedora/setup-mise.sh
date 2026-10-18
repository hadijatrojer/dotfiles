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
  node@26 \
  ripgrep@latest \
  shellcheck@latest \
  shfmt@latest \
  uv@latest \
  yazi@latest \
  zoxide@latest

# Keep `npm i -g` out of the per-version node install dir so globals survive
# node bumps. ~/.local/bin is already on PATH (zsh/.zshenv).
mise set --global NPM_CONFIG_PREFIX="$HOME/.local"
export NPM_CONFIG_PREFIX="$HOME/.local"

# Global npm tools: agent tooling and LSP servers for nvim.
mise exec -- npm install -g \
  @earendil-works/pi-coding-agent \
  @mu-crew/mu \
  @mu-crew/murmur \
  bash-language-server \
  typescript \
  typescript-language-server \
  vscode-langservers-extracted

# The pi extension shims embed the install path; refresh them after a move.
mise exec -- mu link pi
mise exec -- murmur link pi
