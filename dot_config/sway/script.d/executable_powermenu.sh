#!/bin/bash
#################################################
##
#### PowerMenu
##
#################################################
#~~~ variables
WAYLAND_DISPLAY=wayland-1

#~~~ lock function
blurlock() {
    [[ -n "$(ps aux | grep -v grep | grep swaylock)" ]] && exit
    for output in $(swaymsg -t get_outputs | jq -r '.[].name'); do
        args="$args --image $output:$HOME/.config/wallpapers/lockscreen.jpg"
    done
    WAYLAND_DISPLAY=$WAYLAND_DISPLAY swaylock $args --debug &>~/.cache/swaylock-debug-$(date +%Y-%m-%d_%H-%M-%S).log &
}

#~~~ menu
[[ "$@" == "--lock" ]] && blurlock && exit
MODE=$(swaynag -m PowerMenu -Z Shutdown 'echo 0' -Z Reboot 'echo 1' -Z Suspend 'echo 2' -Z Lock 'echo 3' -Z Logout 'echo 4')
[[ ! -n "$MODE" ]] && exit
CONFIRM=$(swaynag -m Confirm? -Z No 'echo no' -Z Yes 'echo yes')
[[ $CONFIRM != "yes" ]] && exit
case $MODE in
0)
    systemctl poweroff
    ;;
1)
    systemctl reboot -i
    ;;
2)
    blurlock
    sleep 1
    systemctl suspend
    ;;
3)
    blurlock &
    ;;
4)
    swaymsg exit
    ;;
*)
    echo "No command specified..."
    ;;
esac
