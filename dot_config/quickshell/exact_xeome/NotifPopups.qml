import QtQuick
import Quickshell
import Quickshell.Wayland

// Notification popups: top-right, newest first, on the focused monitor.
PanelWindow {
    id: root

    // ponytail: follows focus live, so a popup hops screens when focus does;
    // latch the screen at spawn if that matters.
    screen: Quickshell.screens.find(s => s.name === Compositor.focusedMonitor) ?? null

    readonly property int maxVisible: 5

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
                required property int index

                // Cards past maxVisible wait hidden, with their countdown
                // stopped, until earlier ones go.
                visible: card.index < root.maxVisible

                notif: modelData
                onDismissed: Notifs.drop(card.modelData)

                Timer {
                    interval: Notifs.timeout(card.modelData)
                    // Hover restarts rather than resumes: leaving the card
                    // grants the whole timeout again.
                    running: interval > 0 && card.visible && !card.hovered
                    // expire() emits closed, which drops the card below.
                    onTriggered: card.modelData.expire()
                }

                // The notification is destroyed right after closed, so drop
                // it before the reference dangles.
                Connections {
                    target: card.modelData

                    function onClosed(): void {
                        Notifs.drop(card.modelData);
                    }
                }
            }
        }

        // Counts the cards waiting past maxVisible.
        Surface {
            width: parent.width
            implicitHeight: 24
            visible: Notifs.popups.length > root.maxVisible

            BarText {
                anchors.centerIn: parent
                text: `+${Notifs.popups.length - root.maxVisible} more`
                font.pixelSize: Theme.size - 3
                color: Theme.dim
            }
        }
    }
}
