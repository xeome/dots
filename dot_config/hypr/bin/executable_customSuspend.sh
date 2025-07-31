#!/bin/bash/

if ! pgrep -x create_ap >/dev/null; then
	systemctl suspend
else
	pidof hyprlock | hyprlock
	exit 1
fi
