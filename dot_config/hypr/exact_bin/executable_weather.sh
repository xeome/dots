#!/bin/bash
# Current weather from wttr.in, for the lock screen. Cached for a day.

cache_file="$HOME/.cache/wttr_cache.txt"

if [ -f "$cache_file" ]; then
	age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
	cached=$(<"$cache_file")
	if [ "$age" -lt 86400 ] && [ -n "$cached" ]; then
		echo "$cached"
		exit
	fi
fi

mkdir -p "${cache_file%/*}"
response=$(curl -s 'wttr.in?format=%c+%C+%t')
echo "$response" | tee "$cache_file"
