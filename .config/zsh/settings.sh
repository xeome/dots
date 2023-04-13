HISTSIZE=10000000
SAVEHIST=10000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.

export PAGER="most"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.zig/:$PATH"

export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

export PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel
export LESSHISTFILE="$XDG_CACHE_HOME"/less/history
export GHCUP_USE_XDG_DIRS=true
#export HISTFILE="$XDG_STATE_HOME"/zsh/history
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export PATH=$PATH:/usr/local/go/bin
export PATH="$PATH:$(go env GOBIN):$(go env GOPATH)/bin"
[ -f "/home/xeome/.ghcup/env" ] && source "/home/xeome/.ghcup/env" # ghcup-env

[[ -s "/etc/grc.zsh" ]] && source /etc/grc.zsh
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


export $(/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
dbus-update-activation-environment --systemd --all
