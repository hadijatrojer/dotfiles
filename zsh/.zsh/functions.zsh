zknew() {
  local title
  read "title?Enter note title: "
  (
    cd "$HOME/notes" || return 1
    zk new --group inbox --title "$title"
  )
}

nv() {
  if [[ -e /tmp/nvim.pipe ]]; then
    nvim --server /tmp/nvim.pipe --remote "$(realpath "$1")"
  else
    nvim --listen /tmp/nvim.pipe "$@"
  fi
}

mvln() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: mvln <source> <destination>"
    return 1
  fi

  set -x
  mv -iv "$1" "$2" && ln -s "$(realpath "$2")" "$1"
  set +x
}

y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return 1
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

rmhist() {
  if (( $# != 1 )); then
    echo "Usage: rmhist <pattern>"
    return 1
  fi

  local histfile tmpfile
  histfile="${HISTFILE:-$HOME/.zsh_history}"
  tmpfile="$(mktemp)" || return 1
  grep -v -- "$1" "$histfile" > "$tmpfile" && mv -- "$tmpfile" "$histfile"
  fc -R "$histfile"
  echo "Removed history lines matching: $1"
}

m() {
  glow -p -w "$(($(tput cols) - 6))" "$@"
}
