#!/bin/sh
# Bound to mod+b.
# The list is vicinae's dmenu mode, so it wears the launcher's graphite theme.
LOC="$HOME/.config/emoji"

CHOICE=$(find "$LOC" -type f ! -name '*.sh' -printf '%f\n' | vicinae dmenu -p "Pick")
[ -n "$CHOICE" ] || exit 0
wl-copy --type image/"${CHOICE##*.}" <"$LOC/$CHOICE"
