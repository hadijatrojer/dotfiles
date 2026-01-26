export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode auto      # update automatically without asking

plugins=(branch git fzf zoxide)

# Initialize mise (version manager)
if command -v mise >/dev/null; then
  eval "$(mise activate zsh)"
elif test -e "${HOME}/.local/bin/mise"; then
  eval "$(~/.local/bin/mise activate zsh)"
fi

source $ZSH/oh-my-zsh.sh

export VISUAL=nvim
export EDITOR=nvim

if [[ -f /run/.toolboxenv ]]; then
    echo "You are inside a Toolbox container."
    export TERM=xterm-256color
    PROMPT="%F{#1e66f5}[⬢] %f$PROMPT"
fi
