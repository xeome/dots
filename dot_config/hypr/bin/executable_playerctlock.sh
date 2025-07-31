#!/bin/bash
# Artwork Caching Logic:
# --arturl caches remote artwork images in ~/.cache/playerctlock-art, named with a hash of the artUrl.
# Each unique artUrl is cached separately. Cache hit: returns local file for fastest access.
# Invalidation: When the track/artwork changes, the script resolves a *new* artUrl, leading to a new cache file.
# Old files may accumulate but are never reused for a new track/art.
# Optional: A cleanup cron job or cache script can be used to routinely remove files older than a threshold.
# Hyprlock will always load the *current* cached image based on artUrl, minimizing delay.

if [ $# -eq 0 ]; then
	echo "Usage: $0 --title | --arturl | --artist | --length | --album | --source"
	exit 1
fi

# Function to get metadata using playerctl
get_metadata() {
	key=$1
	playerctl metadata --format "{{ $key }}" 2>/dev/null
}

# Check for arguments

# Function to determine the source and return an icon and text
get_source_info() {
	trackid=$(get_metadata "mpris:trackid")
	if [[ "$trackid" == *"firefox"* ]]; then
		echo -e "Firefox 󰈹"
	elif [[ "$trackid" == *"spotify"* ]]; then
		echo -e "Spotify "
	elif [[ "$trackid" == *"chromium"* ]]; then
		echo -e "Chrome "
	else
		echo ""
	fi
}

# Parse the argument
case "$1" in
--title)
	title=$(get_metadata "xesam:title")
	if [ -z "$title" ]; then
		echo ""
	else
		echo "${title:0:28}" # Limit the output to 50 characters
	fi
	;;
--arturl)
	url=$(get_metadata "mpris:artUrl")
	if [ -z "$url" ]; then
		echo ""
	else
		if [[ "$url" == file://* ]]; then
			url=${url#file://}
			art_path="$url"
		else
			# Cache remote art in ~/.cache/playerctlock-art
			cache_dir="$HOME/.cache/playerctlock-art"
			mkdir -p "$cache_dir"
			# Use URL hash as filename
			hash=$(echo -n "$url" | sha1sum | awk '{print $1}')
			cache_file="$cache_dir/$hash"
			if [ ! -f "$cache_file" ]; then
				curl --silent --max-time 4 --output "$cache_file" "$url"
			fi
			if [ -f "$cache_file" ]; then
				art_path="$cache_file"
			else
				art_path=""
			fi
		fi

		# Symlink latest.png if art_path is valid
		latest_link="$HOME/.cache/playerctlock-art/latest.png"
		if [ -n "$art_path" ]; then
			# Only relink if changed
			if [ "$(readlink "$latest_link")" != "$art_path" ]; then
				ln -sf "$art_path" "$latest_link"
			fi
			echo "$art_path"
		else
			echo ""
		fi
	fi
	;;
--artist)
	artist=$(get_metadata "xesam:artist")
	if [ -z "$artist" ]; then
		echo ""
	else
		echo "${artist:0:30}" # Limit the output to 50 characters
	fi
	;;
--length)
	length=$(get_metadata "mpris:length")
	if [ -z "$length" ]; then
		echo ""
	else
		# Convert length from microseconds to a more readable format (seconds)
		echo "$(echo "scale=2; $length / 1000000 / 60" | bc) m"
	fi
	;;
--status)
	status=$(playerctl status 2>/dev/null)
	if [[ $status == "Playing" ]]; then
		echo "󰎆"
	elif [[ $status == "Paused" ]]; then
		echo "󱑽"
	else
		echo ""
	fi
	;;
--album)
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
	;;
--source)
	get_source_info
	;;
*)
	echo "Invalid option: $1"
	echo "Usage: $0 --title | --url | --artist | --length | --album | --source"
	exit 1
	;;
esac
