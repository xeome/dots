import QtQuick

// One grouped box, hairline-divided buttons, the focused one filled with the
// accent. Per-output, so each monitor shows only its own workspaces.
Rectangle {
    id: root

    required property var screen

    // ponytail: re-filters when workspaces are created/destroyed, not when an
    // existing one is dragged to another monitor. Swap to a Connections on the
    // backend's moveworkspace event if that turns out to bite.
    readonly property var list: Compositor.workspaces.filter(w => w.monitor?.name === root.screen.name)

    implicitWidth: row.implicitWidth + 2
    implicitHeight: Theme.barHeight - Theme.gap * 2
    color: Theme.surface
    radius: Theme.radius
    border.width: 1
    border.color: Theme.border

    Row {
        id: row
        anchors.fill: parent
        anchors.margins: 1

        Repeater {
            model: root.list

            delegate: Rectangle {
                id: btn

                required property var modelData
                required property int index

                readonly property bool active: modelData.active

                width: Math.max(44, label.implicitWidth + 26)
                height: row.height
                color: active ? (ma.containsMouse ? Theme.accentHover : Theme.accent) : ma.containsMouse ? Theme.surfaceHover : "transparent"

                // The ends round themselves rather than being masked by the
                // parent: Qt's `clip` is a rectangular scissor and would put
                // the square corners straight back. One less than the parent's
                // radius, to nest inside its 1px inset.
                topLeftRadius: index === 0 ? Theme.radius - 1 : 0
                bottomLeftRadius: index === 0 ? Theme.radius - 1 : 0
                topRightRadius: index === root.list.length - 1 ? Theme.radius - 1 : 0
                bottomRightRadius: index === root.list.length - 1 ? Theme.radius - 1 : 0

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.anim
                    }
                }

                BarText {
                    id: label
                    anchors.centerIn: parent
                    // Workspace numbers are what you navigate by, so the
                    // inactive ones stay legible (fgDim) rather than dropping
                    // to the muted tier labels use.
                    text: btn.modelData.name
                    color: btn.active ? Theme.fgOnAccent : Theme.fgDim
                    weight: btn.active ? 700 : Theme.weight
                }

                // Urgent pulses in the warn colour, not the accent — an urgent
                // workspace is not the one you're on. Kept on a separate layer
                // so it can't clobber the colour binding above the way an
                // animation on `color` would.
                Rectangle {
                    anchors.fill: parent
                    color: Theme.warn
                    radius: parent.radius
                    topLeftRadius: btn.topLeftRadius
                    bottomLeftRadius: btn.bottomLeftRadius
                    topRightRadius: btn.topRightRadius
                    bottomRightRadius: btn.bottomRightRadius
                    visible: btn.modelData.urgent
                    opacity: 0.45

                    SequentialAnimation on opacity {
                        running: btn.modelData.urgent
                        loops: Animation.Infinite

                        NumberAnimation {
                            from: 0.45
                            to: 0.75
                            duration: 900
                        }
                        NumberAnimation {
                            from: 0.75
                            to: 0.45
                            duration: 900
                        }
                    }
                }

                // A divider on every button but the last
                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    visible: btn.index < root.list.length - 1
                    color: Theme.divider
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: btn.modelData.activate()
                }
            }
        }
    }
}
