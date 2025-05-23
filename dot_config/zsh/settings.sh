# Source fzf key bindings and completion
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# History settings
export HISTFILE=~/.local/state/.zsh_history
HISTSIZE=500000
SAVEHIST=500000
setopt appendhistory
setopt INC_APPEND_HISTORY  
setopt SHARE_HISTORY

# Pager and PATH
export PAGER="most"
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.local/bin/
export PATH="$HOME/.local/bin/zig/:$PATH"

if command -v go &> /dev/null; then
    export PATH="$PATH:$(go env GOPATH)/bin"
fi

# XDG Base Directories
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

# Specific application directories
export PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel
export LESSHISTFILE="$XDG_CACHE_HOME"/less/history
export GHCUP_USE_XDG_DIRS=true
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export CMAKE_CXX_COMPILER_LAUNCHER=ccache

# Source ghcup if available
[ -f "/home/xeome/.ghcup/env" ] && source "/home/xeome/.ghcup/env"

# Source grc.zsh if available
[[ -s "/etc/grc.zsh" ]] && source /etc/grc.zsh

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export GPG_TTY=$(tty)

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export MOZ_ENABLE_WAYLAND=1
fi

# Default editor
export VISUAL=nvim

# flatpak
XDG_DATA_DIRS="/var/home/$USER/.local/share/flatpak/exports/share:/home/$USER/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:/home/$USER/.local/share"

uptime
