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
        // On the window grid: Hyprland's gaps_out is Theme.pad too. The right
        // pad is inside the window instead, as room for a card's drift in.
        top: Theme.barHeight + Theme.pad
        right: 0
    }
    implicitWidth: 400 + Theme.pad
    implicitHeight: Math.max(1, col.implicitHeight)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Notifs.popups.length > 0
    // The pad strip at the screen edge passes clicks through.
    mask: Region {
        item: col
    }

    Column {
        id: col
        width: 400
        spacing: 6

        // A new card drifts in from the right and fades in; the ones below
        // slide down to make room. Hyprland fades only the layer, so cards
        // arriving while it is showing would otherwise pop in. `move` also
        // finishes the opacity of an `add` that a second card interrupts.
        add: Transition {
            NumberAnimation {
                property: "x"
                from: Theme.pad
                duration: Theme.anim
                easing.type: Theme.ease
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.anim
                easing.type: Theme.ease
            }
        }
        move: Transition {
            NumberAnimation {
                property: "y"
                duration: Theme.anim
                easing.type: Theme.ease
            }
            NumberAnimation {
                property: "opacity"
                to: 1
                duration: Theme.anim
                easing.type: Theme.ease
            }
        }

        Repeater {
            // Notifs reassigns the array on every change; ScriptModel diffs
            // it, so cards already showing are kept rather than rebuilt.
            model: ScriptModel {
                values: Notifs.popups
            }

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
