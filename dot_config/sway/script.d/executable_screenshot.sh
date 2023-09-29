#!/bin/bash
#################################################
##
#### Screenshot
##
########################( optional: cursor=yes )#
#~~~ variables
showEditor="yes"
imageDirectory="$HOME/Pictures/Screenshots/grim"
_date=$(date +%Y%m%d_%H%M%S)

#~~~ checks
[[ ! -d $imageDirectory ]] && mkdir -p $imageDirectory

#~~~ take screenshot before process
takeInitialSS() {
    [[ -n $@ ]] && sleep $@

    for a in $(swaymsg -t get_outputs | jq -r ".[].name"); do
        [[ -e "/tmp/$a.png" ]] && rm /tmp/$a.png && rm /tmp/ss.png &>/dev/null
        grim -l 1 ${cursor:+-c} -o $a /tmp/$a.png
        swaymsg for_window "[title=\"imv(.*)$a.png\"]" move to output $a
        swaymsg for_window "[title=\"imv(.*)$a.png\"]" fullscreen true
        imv-wayland /tmp/$a.png &
    done
}

#~~~ merge multiple screenshots
mergePhotos() {
    for a in $(swaymsg -t get_outputs | jq -r ".[].name"); do
        files="$files /tmp/$a.png"
    done

    pushd /tmp &>/dev/null
    convert +append $files ss.png
    popd &>/dev/null
}

#~~~ main
main() {
    tempfile="$(mktemp)"
    case $2 in
    1 | 3)
        if [[ $1 == "Rectangular" ]]; then
            takeInitialSS ${3:+$3}
            grim -g "$(slurp)" - >$tempfile
            killall imv-wayland
            cat $tempfile | swappy -f - | wl-copy
            rm $tempfile
        elif [[ $1 == "Full" ]]; then
            takeInitialSS ${3:+$3}
            killall imv-wayland
            FOCUSED=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
            cat /tmp/$FOCUSED.png | swappy -f - | wl-copy
        elif [[ $1 == "Active" ]]; then
            ${3:+sleep $3}
            grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" - >$tempfile
            cat $tempfile | swappy -f - | wl-copy
            rm $tempfile
        fi
        ;;
    2 | 4)
        savedFile="$imageDirectory/${_date}"
        if [[ $1 == "Rectangular" ]]; then
            takeInitialSS ${3:+$3}
            grim -g "$(slurp)" - >"${savedFile}.png"
            killall imv-wayland
            cat "${savedFile}.png" | swappy -f - -o "${savedFile}-edited.png"
        elif [[ $1 == "Full" ]]; then
            takeInitialSS ${3:+$3}
            killall imv-wayland
            FOCUSED=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
            cat /tmp/$FOCUSED.png | swappy -f - -o "${savedFile}-edited.png"
        elif [[ $1 == "Active" ]]; then
            ${3:+sleep $3}
            grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" - >"${savedFile}.png"
            cat "${savedFile}.png" | swappy -f - -o "${savedFile}-edited.png"
        fi
        ;;
    esac
}

#~~~ arg handler
case $1 in
-r | --rec)
    main Rectangular 1
    ;;
-f | --full)
    main Full 2
    ;;
-a | --active)
    main Active 1
    ;;
*)
    MODE1=$(swaynag -t wpgtheme -m Screenshot -Z Full 'echo Full' -Z Rectangular 'echo Rectangular')
    [[ ! -n $MODE1 ]] && exit

    MODE2=$(swaynag -t wpgtheme -m "$MODE1 Screenshot" -Z 'Copy' 'echo 1' -Z 'Save' 'echo 2' -Z 'Timeout and Copy' 'echo 3' -Z 'Timeout and Save' 'echo 4')
    if [[ "$MODE2" == "3" ]] || [[ "$MODE2" == "4" ]]; then
        TIMEOUT=$(swaynag -t wpgtheme -m Timeout -Z 2 'echo 2' -Z 3 'echo 3' -Z 5 'echo 5' -Z 10 'echo 10' -Z 15 'echo 15' -Z 30 'echo 30')
        [[ ! -n $TIMEOUT ]] && exit
    elif [[ ! -n $MODE2 ]]; then
        exit
    fi
    main $MODE1 $MODE2 $TIMEOUT
    ;;
esac
