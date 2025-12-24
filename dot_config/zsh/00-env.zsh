# XDG Base Directories
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Core Utils
export VISUAL="nvim"
export EDITOR="nvim"
export PAGER="most"
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export GPG_TTY="$(tty)"

# Application Env
export PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"
export GHCUP_USE_XDG_DIRS="true"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export CMAKE_CXX_COMPILER_LAUNCHER="ccache"

# PATH Configuration
typeset -U path PATH
path=(
    "$HOME/.local/bin"
    "$HOME/.local/bin/zig"
    "$HOME/.npm-global/bin"
    "$HOME/.opencode/bin"
    "/usr/local/go/bin"
    "${path[@]}"
)

# Dynamic Paths
command -v go &>/dev/null && path+=("$(go env GOPATH)/bin")
[[ -d "$HOME/.local/share/junest/bin" ]] && path+=("$HOME/.local/share/junest/bin")

export PATH

# Data Dirs
export XDG_DATA_DIRS="/var/home/$USER/.local/share/flatpak/exports/share:/home/$USER/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:/home/$USER/.local/share"
