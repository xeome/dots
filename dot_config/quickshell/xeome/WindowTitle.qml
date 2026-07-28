import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland

// waybar `hyprland/window`: borderless, "Desktop" when empty.
//
// Title comes from the wlr foreign-toplevel protocol, not Hyprland's IPC:
// Hyprland.activeToplevel stays null until the first focus change after
// startup, so the bar would read "Desktop" until you switched windows.
//
// ponytail: waybar's separate-outputs gave every monitor its own focused
// window. Only one toplevel is active shell-wide, so unfocused monitors show
// the empty state rather than their own window.
BarText {
    required property var screen

    readonly property string title: Hyprland.focusedMonitor?.name === screen.name ? ToplevelManager.activeToplevel?.title ?? "" : ""

    text: title === "" ? "Desktop" : title
    elide: Text.ElideRight
}
