import QtQuick
import Quickshell.Hyprland

// Not a waybar module. swaync was toggled by a keybind with nothing on screen;
// the centre needs something to hang off, and DND needs somewhere to be
// visible. Left click toggles the centre, right click toggles DND.
BarModule {
    id: root

    required property var screen

    inverted: Notifs.dnd
    tooltipText: Notifs.dnd ? "Do not disturb is on\nRight-click to turn off" : `${Notifs.history.length === 0 ? "No notifications" : Notifs.history.length === 1 ? "1 notification" : `${Notifs.history.length} notifications`}\nRight-click for do not disturb`

    onClicked: button => {
        if (button === Qt.RightButton)
            Notifs.dnd = !Notifs.dnd;
        else
            centre.visible = !centre.visible;
    }

    BarText {
        text: Notifs.dnd ? "󰂛" : Notifs.history.length > 0 ? "󱅫" : "󰂚"
        color: root.fg
    }

    NotifCenter {
        id: centre
        screen: root.screen
    }

    // `qs ipc call notifs toggle` opens the centre on whichever monitor has
    // focus. Kept imperative so PopupWindow.grabFocus can close it without
    // fighting a binding on `visible`.
    Connections {
        target: Notifs

        function onToggleCentre(): void {
            if (Hyprland.focusedMonitor?.name === root.screen.name)
                centre.visible = !centre.visible;
        }
    }
}
