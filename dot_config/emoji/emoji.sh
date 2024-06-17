#!/bin/sh
LOC="$HOME/.config/emoji"
if command -v bemenu > /dev/null 2>&1
then
    MENU=bemenu
elif command -v dmenu > /dev/null 2>&1
then
    MENU=dmenu
else
    echo "could not find a suitable menu"
    exit
fi

CHOICE=$(find $LOC -name "*" -type f -printf '%f\n'| $MENU -l 10 -p "Pick" )
EXT=$(echo "$CHOICE" | cut -d'.' -f2)
TYPE="$WAYLAND_DISPLAY"
if [ -z "${TYPE}" ];
then
    cat $LOC/"$CHOICE" - | xclip -selection clipboard -t image/"$EXT"
else
    cat $LOC/"$CHOICE" - | wl-copy --type image/"$EXT"
fi