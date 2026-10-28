import QtQuick
import Quickshell.Wayland

// The focused window's title, "Desktop" when there is none. Read from the
// foreign-toplevel protocol, not compositor IPC: Hyprland.activeToplevel stays
// null until the first focus change, and sway's IPC has no equivalent.
//
// ponytail: one toplevel is active shell-wide, so unfocused monitors show
// "Desktop" rather than their own window.
BarText {
    required property var screen

    readonly property string title: Compositor.focusedMonitor === screen.name ? ToplevelManager.activeToplevel?.title ?? "" : ""

    text: title === "" ? "Desktop" : title
    elide: Text.ElideRight
}
