#!/bin/bash
# Hotspot and battery status for the lock screen (hyprlock.conf).

bat=/sys/class/power_supply/BAT0

if pgrep -x create_ap >/dev/null; then
	hotspot="󱜠"
fi

# Machines without a battery show only the hotspot.
if [ ! -r "$bat/capacity" ]; then
	echo "$hotspot"
	exit
fi

percentage=$(<"$bat/capacity")
icons=("󰂃" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰁹")
index=$((percentage / 10))
if [ "$index" -gt 9 ]; then
	index=9
fi
icon=${icons[index]}
if [ "$(<"$bat/status")" = "Charging" ]; then
	icon="󰂄"
fi

echo "$hotspot" "$percentage% $icon"
