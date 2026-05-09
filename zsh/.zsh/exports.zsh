# PATH configuration
export PATH="/usr/local/sbin:$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$HOME/go/bin:$PATH"

# Let the terminal emulator set TERM. Fall back only when the current value has
# no matching terminfo entry, which is common over SSH.
if [[ -z "$TMUX" ]] && ! infocmp "$TERM" >/dev/null 2>&1; then
  export TERM=xterm-256color
fi

if [[ -f /run/.toolboxenv ]]; then
  export TERM=xterm-256color
fi

export CLICOLOR=1
export EDITOR=nvim
export VISUAL=nvim

export HISTFILESIZE=1048576
export HISTSIZE=1048576
[[ -n "${TTY:-}" ]] && export GPG_TTY="$TTY"
export ELECTRON_OZONE_PLATFORM_HINT=auto

bat_cmd=""
if command -v bat >/dev/null 2>&1; then
  bat_cmd="bat"
elif command -v batcat >/dev/null 2>&1; then
  bat_cmd="batcat"
fi

if [[ -n "$bat_cmd" ]]; then
  export PAGER="$bat_cmd"
  export MANPAGER="sh -c 'col -bx | $bat_cmd -l man -p'"
  export MANROFFOPT="-c"
fi

lesspipe_path=""
if [[ -x "$HOME/.local/bin/lesspipe.sh" ]]; then
  lesspipe_path="$HOME/.local/bin/lesspipe.sh"
elif command -v lesspipe.sh >/dev/null 2>&1; then
  lesspipe_path="$(command -v lesspipe.sh)"
elif [[ -x /usr/bin/lesspipe.sh ]]; then
  lesspipe_path="/usr/bin/lesspipe.sh"
fi

if [[ -n "$lesspipe_path" ]]; then
  export LESSOPEN="| $lesspipe_path %s"
  export LESS="-R"
fi

if [[ -n "$lesspipe_path" && -n "$bat_cmd" ]]; then
  export LESSCOLORIZER="$bat_cmd"
fi
