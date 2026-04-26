# Zsh

This package keeps the interactive shell config modular instead of growing one
large `.zshrc`.

## Layout

- `.zshrc`: plugin selection and startup order
- `.zsh/exports.zsh`: PATH and environment variables
- `.zsh/tools.zsh`: tool bootstrap and prompt
- `.zsh/aliases.zsh`: aliases and global aliases
- `.zsh/functions.zsh`: small shell helpers
- `.zsh/overrides.zsh`: aliases and helpers that intentionally override defaults
- `.zsh/os-linux.zsh`: Linux-specific shell behavior

## Notes

- The prompt uses Catppuccin Latte colors to stay aligned with `THEME.md`.
- Toolbox shells are detected and shown in the prompt.
- The `tm` helper launches tmux directly when already inside tmux, attaches to
  an existing server outside tmux, and otherwise starts a fresh session.
