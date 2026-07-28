import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// swaync's notification popups: top-right, 400px, newest first.
PanelWindow {
    id: root

    // ponytail: follows the focused monitor live, so a toast can hop screens
    // if you switch mid-popup. Latch it at spawn time if that annoys you.
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

    WlrLayershell.namespace: "quickshell-notifications"
    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.barHeight + 8
        right: 10
    }
    implicitWidth: 400
    implicitHeight: Math.max(1, col.implicitHeight)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Notifs.popups.length > 0

    Column {
        id: col
        width: parent.width
        spacing: 6

        Repeater {
            model: Notifs.popups

            delegate: NotifCard {
                id: card

                required property var modelData

                notif: modelData
                onDismissed: Notifs.drop(card.modelData)

                Timer {
                    interval: Notifs.timeout(card.modelData)
                    running: interval > 0
                    onTriggered: {
                        card.modelData.expire();
                        Notifs.drop(card.modelData);
                    }
                }

                // The object is destroyed right after this fires, so drop our
                // reference before it dangles.
                Connections {
                    target: card.modelData

                    function onClosed(): void {
                        Notifs.drop(card.modelData);
                    }
                }
            }
        }
    }
}
