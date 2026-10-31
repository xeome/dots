export HISTFILE="$XDG_STATE_HOME/.zsh_history"
export HISTSIZE=500000
export SAVEHIST=500000
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY

[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
[[ -s "/etc/grc.zsh" ]] && source /etc/grc.zsh
[[ -f "$HOME/.ghcup/env" ]] && source "$HOME/.ghcup/env"
