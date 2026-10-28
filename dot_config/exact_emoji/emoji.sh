#!/bin/sh
# Pick an image from this folder and copy it to the clipboard. Bound to mod+b.
LOC="$HOME/.config/emoji"
if command -v bemenu >/dev/null 2>&1; then
    MENU=bemenu
elif command -v dmenu >/dev/null 2>&1; then
    MENU=dmenu
else
    echo "could not find a suitable menu" >&2
    exit 1
fi

CHOICE=$(find "$LOC" -type f ! -name '*.sh' -printf '%f\n' | $MENU -l 10 -p "Pick")
[ -n "$CHOICE" ] || exit 0
EXT=${CHOICE##*.}
if [ -z "$WAYLAND_DISPLAY" ]; then
    xclip -selection clipboard -t image/"$EXT" <"$LOC/$CHOICE"
else
    wl-copy --type image/"$EXT" <"$LOC/$CHOICE"
fi
