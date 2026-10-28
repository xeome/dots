import QtQuick

// The notification centre's button and the do-not-disturb indicator. Left
// click toggles the centre, right click toggles DND.
BarModule {
    id: root

    required property var screen

    tone: Notifs.dnd ? "sel" : ""
    minWidth: 0
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

    // `qs ipc call notifs toggle` toggles the centre on the focused monitor.
    // Imperative so the centre's click-outside MouseArea can close it without
    // fighting a binding.
    Connections {
        target: Notifs

        function onToggleCentre(): void {
            if (Compositor.focusedMonitor === root.screen.name)
                centre.visible = !centre.visible;
        }
    }
}
