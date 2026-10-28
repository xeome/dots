#!/bin/bash
# Now-playing fields for the lock screen (hyprlock.conf), one per flag.
# --arturl caches remote art in ~/.cache/playerctlock-art under a hash of its
# URL and points latest.png at the current one. Old files are never cleaned up.

usage="Usage: $0 --title | --arturl | --artist | --length | --status | --album | --source"

metadata() {
	playerctl metadata --format "{{ $1 }}" 2>/dev/null
}

case "$1" in
--title)
	title=$(metadata xesam:title)
	echo "${title:0:28}"
	;;
--arturl)
	url=$(metadata mpris:artUrl)
	cache_dir="$HOME/.cache/playerctlock-art"
	if [[ $url == file://* ]]; then
		art_path=${url#file://}
	elif [ -n "$url" ]; then
		mkdir -p "$cache_dir"
		cache_file="$cache_dir/$(echo -n "$url" | sha1sum | awk '{print $1}')"
		if [ ! -f "$cache_file" ]; then
			curl --silent --max-time 4 --output "$cache_file" "$url"
		fi
		if [ -f "$cache_file" ]; then
			art_path=$cache_file
		fi
	fi
	if [ -n "$art_path" ] && [ "$(readlink "$cache_dir/latest.png")" != "$art_path" ]; then
		mkdir -p "$cache_dir"
		ln -sf "$art_path" "$cache_dir/latest.png"
	fi
	echo "$art_path"
	;;
--artist)
	artist=$(metadata xesam:artist)
	echo "${artist:0:30}"
	;;
--length)
	length=$(metadata mpris:length)
	if [ -n "$length" ]; then
		# mpris:length is in microseconds.
		echo "$(echo "scale=2; $length / 1000000 / 60" | bc) m"
	else
		echo
	fi
	;;
--status)
	case "$(playerctl status 2>/dev/null)" in
	Playing) echo "󰎆" ;;
	Paused) echo "󱑽" ;;
	*) echo ;;
	esac
	;;
--album)
	album=$(metadata xesam:album)
	if [ -n "$album" ]; then
		echo "$album"
	elif [ -n "$(playerctl status 2>/dev/null)" ]; then
		echo "Not album"
	else
		echo
	fi
	;;
--source)
	case "$(metadata mpris:trackid)" in
	*firefox*) echo "Firefox 󰈹" ;;
	*spotify*) echo "Spotify " ;;
	*chromium*) echo "Chrome " ;;
	*) echo ;;
	esac
	;;
*)
	echo "$usage"
	exit 1
	;;
esac
