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
