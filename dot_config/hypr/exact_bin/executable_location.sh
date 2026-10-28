#!/bin/bash
# Country and city of the public IP, for the lock screen. Cached for a day.

cache_file="$HOME/.cache/ip_cache.txt"

if [ -f "$cache_file" ]; then
	age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
	cached=$(<"$cache_file")
	if [ "$age" -lt 86400 ] && [ -n "$cached" ]; then
		echo "$cached"
		exit
	fi
fi

mkdir -p "${cache_file%/*}"
response=$(curl -s ipinfo.io | jq -r '.country + ", " + .city' 2>/dev/null)
echo "$response" | tee "$cache_file"
