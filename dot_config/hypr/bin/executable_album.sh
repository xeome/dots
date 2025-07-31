#!/bin/bash
album=$(playerctl metadata --format "{{ xesam:album }}" 2>/dev/null)
if [[ -n $album ]]; then
	echo "$album"
else
	status=$(playerctl status 2>/dev/null)
	if [[ -n $status ]]; then
		echo "Not album"
	else
		echo ""
	fi
fi
