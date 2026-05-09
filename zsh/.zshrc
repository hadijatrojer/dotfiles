typeset -U path fpath

HISTFILE="$HOME/.zsh_history"
HISTSIZE=1048576
SAVEHIST=1048576

setopt auto_cd auto_pushd extended_history hist_ignore_dups hist_ignore_space
setopt interactivecomments pushd_ignore_dups pushdminus share_history

mkdir -p "$HOME/.cache/zsh"
autoload -Uz compinit
compinit -i -d "$HOME/.cache/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'

bindkey -e

[[ -f "$HOME/.zsh/exports.zsh" ]] && source "$HOME/.zsh/exports.zsh"
[[ -f "$HOME/.zsh/tools.zsh" ]] && source "$HOME/.zsh/tools.zsh"
[[ -f "$HOME/.zsh/aliases.zsh" ]] && source "$HOME/.zsh/aliases.zsh"
[[ -f "$HOME/.zsh/git-aliases.zsh" ]] && source "$HOME/.zsh/git-aliases.zsh"

command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

for plugin_file in \
  "$HOME/.local/share/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
do
  if [[ -f "$plugin_file" ]]; then
    source "$plugin_file"
    break
  fi
done

for plugin_file in \
  "$HOME/.local/share/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
do
  if [[ -f "$plugin_file" ]]; then
    source "$plugin_file"
    break
  fi
done
