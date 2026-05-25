# Zsh

This package keeps the interactive shell config modular without depending on
`oh-my-zsh`.

## Layout

- `.zshrc`: native zsh startup, history, completion, and direct tool/plugin hooks
- `.zsh/exports.zsh`: PATH and environment variables
- `.zsh/tools.zsh`: tool bootstrap and prompt
- `.zsh/aliases.zsh`: aliases and global aliases
- `.zsh/git-aliases.zsh`: small curated git alias set

## Notes

- `fzf` and `zoxide` are initialized directly when installed.
- `./stow-all.py --apply` clones `zsh-autosuggestions` and
  `zsh-syntax-highlighting` into `~/.local/share/zsh-plugins/` at pinned
  versions.
- Those plugins are sourced directly if they exist under
  `~/.local/share/zsh-plugins/` or the legacy `~/.oh-my-zsh/custom/plugins/`
  path.
- The prompt uses Catppuccin Latte colors to stay aligned with `THEME.md`.
- Toolbox shells are detected and shown in the prompt.
