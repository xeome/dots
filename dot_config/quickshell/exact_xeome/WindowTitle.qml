import QtQuick
import Quickshell.Wayland

// waybar `hyprland/window`: borderless, "Desktop" when empty.
//
// Title comes from the wlr foreign-toplevel protocol rather than the
// compositor's own IPC: Hyprland.activeToplevel stays null until the first
// focus change after startup, so the bar would read "Desktop" until you
// switched windows. sway's IPC has no equivalent at all, so the protocol is
// also what makes this module work on both.
//
// ponytail: waybar's separate-outputs gave every monitor its own focused
// window. Only one toplevel is active shell-wide, so unfocused monitors show
// the empty state rather than their own window.
BarText {
    required property var screen

    readonly property string title: Compositor.focusedMonitor === screen.name ? ToplevelManager.activeToplevel?.title ?? "" : ""

    text: title === "" ? "Desktop" : title
    elide: Text.ElideRight
}
