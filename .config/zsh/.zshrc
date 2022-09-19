# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"


# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

export PATH="$HOME/.local/bin:$PATH"

export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache


HISTSIZE=500000
SAVEHIST=500000
setopt appendhistory
setopt INC_APPEND_HISTORY  
setopt SHARE_HISTORY

export PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel
export LESSHISTFILE="$XDG_CACHE_HOME"/less/history
export GHCUP_USE_XDG_DIRS=true
export HISTFILE="$XDG_STATE_HOME"/zsh/history
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export $(/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
dbus-update-activation-environment --systemd --all

plugins=(git zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh


export PAGER="most"

alias wget=wget --hsts-file="$XDG_DATA_HOME/wget-hsts"
alias fixmouse="su -c 'echo 'on' > '/sys/bus/usb/devices/1-2/power/control''"
alias mp3="yt-dlp -x --audio-format mp3"
alias v="neovide --multigrid"
alias ironweil="mesa_glthread=true gamemoderun ironwail -basedir ~/.vkquake"
alias gamerun="mesa_glthread=true gamemoderun"
alias xdpreload="sudo xdp-loader unload -a wlan0; sudo xdp-loader load -m skb -s prog wlan0 obj/icmp_block.o"

0short() { curl -F"shorten=$1" https://envs.sh ; }

fastfetch
[ -f "/home/xeome/.ghcup/env" ] && source "/home/xeome/.ghcup/env" # ghcup-env
