#!/bin/sh
# Pick an image from this folder and copy it to the clipboard. Bound to mod+b.
# The list is vicinae's dmenu mode, so it wears the launcher's graphite theme.
LOC="$HOME/.config/emoji"

CHOICE=$(find "$LOC" -type f ! -name '*.sh' -printf '%f\n' | vicinae dmenu -p "Pick")
[ -n "$CHOICE" ] || exit 0
EXT=${CHOICE##*.}
if [ -z "$WAYLAND_DISPLAY" ]; then
    xclip -selection clipboard -t image/"$EXT" <"$LOC/$CHOICE"
else
    wl-copy --type image/"$EXT" <"$LOC/$CHOICE"
fi
