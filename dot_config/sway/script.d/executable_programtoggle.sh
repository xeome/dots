#!/bin/bash
#################################################
##
#### Program Toggler
##
#################################################

[[ ! -n "$@" ]] && exit

if [[ -n "$(ps aux | grep -vE "grep|programtoggle" | grep -i "$*")" ]]; then
    ps aux | grep -vE "grep|programtoggle" | grep "$*" | awk '{print $2}' | xargs pgrep -P | xargs kill
else
	"$@" &
fi
