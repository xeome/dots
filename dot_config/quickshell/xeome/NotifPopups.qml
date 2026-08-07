import QtQuick
import Quickshell
import Quickshell.Wayland

// swaync's notification popups: top-right, 400px, newest first.
PanelWindow {
    id: root

    // ponytail: follows the focused monitor live, so a toast can hop screens
    // if you switch mid-popup. Latch it at spawn time if that annoys you.
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

                // A burst of twenty would otherwise build a column taller than
                // the screen. The rest wait their turn rather than being
                // dropped — hence the countdown below only running once a card
                // is actually on screen to be read.
                visible: card.index < root.maxVisible

                notif: modelData
                onDismissed: Notifs.drop(card.modelData)

                Timer {
                    interval: Notifs.timeout(card.modelData)
                    // Hovering restarts rather than resumes: leaving the card
                    // hands back the whole timeout, which is the behaviour you
                    // want when you moved the mouse there to read it.
                    running: interval > 0 && card.visible && !card.hovered
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

        // Without this the queued ones are simply invisible, and a burst reads
        // as "five notifications" when it was twenty.
        Rectangle {
            width: parent.width
            implicitHeight: 24
            visible: Notifs.popups.length > root.maxVisible
            color: Theme.glass
            border.width: 1
            border.color: Theme.border

            BarText {
                anchors.centerIn: parent
                text: `+${Notifs.popups.length - root.maxVisible} more`
                font.pixelSize: Theme.size - 3
                font.weight: 500
                color: Theme.fgDim
            }
        }
    }
}
