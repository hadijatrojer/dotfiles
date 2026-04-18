export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

plugins=(
  branch
  git
  fzf
  ssh
  sudo
  systemd
  tmux
  toolbox
  zoxide
)

if [[ -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
  plugins+=(zsh-autosuggestions)
fi

if [[ -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
  plugins+=(zsh-syntax-highlighting)
fi

[[ -f "$HOME/.zsh/exports.zsh" ]] && source "$HOME/.zsh/exports.zsh"
[[ -f "$HOME/.zsh/os-linux.zsh" ]] && source "$HOME/.zsh/os-linux.zsh"
[[ -f "$HOME/.zsh/tools.zsh" ]] && source "$HOME/.zsh/tools.zsh"

source $ZSH/oh-my-zsh.sh

[[ -f "$HOME/.zsh/aliases.zsh" ]] && source "$HOME/.zsh/aliases.zsh"
[[ -f "$HOME/.zsh/functions.zsh" ]] && source "$HOME/.zsh/functions.zsh"
[[ -f "$HOME/.zsh/overrides.zsh" ]] && source "$HOME/.zsh/overrides.zsh"

if [[ -f /run/.toolboxenv ]]; then
  export TERM=xterm-256color
fi
