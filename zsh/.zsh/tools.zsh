if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
elif [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

autoload -Uz colors && colors
setopt prompt_subst

prompt_dir_color="%F{#b7bdf8}"
prompt_accent_color="%F{#eed49f}"
prompt_error_color="%F{#ed8796}"
prompt_muted_color="%F{#6e738d}"
prompt_toolbox_color="%F{#8bd5ca}"
prompt_reset="%f"
prompt_context=""

PROMPT="${prompt_dir_color}%3~${prompt_reset} ${prompt_accent_color}>${prompt_reset} "

if [[ -f /run/.toolboxenv && -r /run/.containerenv ]]; then
  prompt_toolbox_name="$(grep -E '^name=\"' /run/.containerenv 2>/dev/null | cut -d '\"' -f 2)"
  prompt_context="${prompt_toolbox_color}${prompt_toolbox_name:-toolbox}${prompt_reset}"
fi

if [[ -n "${SSH_CONNECTION:-}" ]]; then
  prompt_context="${prompt_context:+${prompt_context} }${prompt_muted_color}%m${prompt_reset}"
fi

RPROMPT="%(?..${prompt_error_color}x${prompt_reset})"
if [[ -n "${prompt_context}" ]]; then
  RPROMPT="%(?..${prompt_error_color}x${prompt_reset} )${prompt_context}"
fi
