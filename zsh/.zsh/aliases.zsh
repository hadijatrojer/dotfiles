if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons=auto'
  alias ll='eza -l --icons=auto --group-directories-first'
  alias la='eza -a --icons=auto'
  alias lt='eza --tree'
  alias l='eza -lahG --icons=auto --no-permissions --no-user'
fi

# General aliases
alias -g F='| fzf'
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L='| less'
alias -g LL='2>&1 | less'
alias -g NE='2> /dev/null'
alias -g NUL='> /dev/null 2>&1'

alias port_forward='ssh -L 8081:localhost:8081 dev'
alias serve='python3 -m http.server 8081'

# Common `less` misspellings
alias lees='less'
alias elss='less'
alias sless='less'
