if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons=auto'
  alias ll='eza -l --icons=auto --group-directories-first'
  alias la='eza -a --icons=auto'
  alias lt='eza --tree'
  alias l='eza -lahG --icons=auto --no-permissions --no-user'
fi

tm() {
  if [[ -n "$TMUX" ]]; then
    command tmux "$@"
    return
  fi

  if [[ $# -gt 0 ]]; then
    command tmux "$@"
    return
  fi

  if command tmux has-session 2>/dev/null; then
    command tmux attach
    return
  fi

  command tmux new-session
}
