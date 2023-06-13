#!/bin/sh
LOC="/home/xeome/.config/emoji"
if command -v bemenu &> /dev/null
then
    MENU=bemenu
elif command -v dmenu &> /dev/null
then
    MENU=dmenu
else
    echo "could not find a suitable menu"
    exit
fi

CHOICE=$(find $LOC -name "*" -type f -printf '%f\n'| $MENU -l 10 -p "Pick" )
EXT=$(echo $CHOICE | cut -d'.' -f2)
TYPE=$(echo $WAYLAND_DISPLAY)
if [ -z ${TYPE} ];
then
    cat $LOC/$CHOICE - | xclip -selection clipboard -t image/$EXT
else
    cat $LOC/$CHOICE - | wl-copy --type image/$EXT
fi
