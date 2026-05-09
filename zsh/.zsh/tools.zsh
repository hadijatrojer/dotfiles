if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
elif [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

autoload -Uz colors && colors
setopt prompt_subst

prompt_dir_color="%F{#7287fd}"
prompt_accent_color="%F{#df8e1d}"
prompt_error_color="%F{#d20f39}"
prompt_muted_color="%F{#9ca0b0}"
prompt_toolbox_color="%F{#179299}"
prompt_reset="%f"
prompt_context=""

PROMPT="${prompt_dir_color}%3~${prompt_reset} ${prompt_accent_color}>${prompt_reset} "

if [[ -f /run/.toolboxenv && -r /run/.containerenv ]]; then
  prompt_toolbox_name=""
  while IFS= read -r prompt_containerenv_line; do
    if [[ "$prompt_containerenv_line" == name=* ]]; then
      prompt_toolbox_name="${prompt_containerenv_line#name=}"
      prompt_toolbox_name="${prompt_toolbox_name#\"}"
      prompt_toolbox_name="${prompt_toolbox_name%\"}"
      break
    fi
  done < /run/.containerenv
  prompt_context="${prompt_toolbox_color}${prompt_toolbox_name:-toolbox}${prompt_reset}"
fi

if [[ -n "${SSH_CONNECTION:-}" ]]; then
  prompt_context="${prompt_context:+${prompt_context} }${prompt_muted_color}%m${prompt_reset}"
fi

RPROMPT="%(?..${prompt_error_color}x${prompt_reset})"
if [[ -n "${prompt_context}" ]]; then
  RPROMPT="%(?..${prompt_error_color}x${prompt_reset} )${prompt_context}"
fi
