import QtQuick
import Quickshell.Hyprland

// waybar `hyprland/workspaces`: one grouped box, hairline-divided buttons,
// active button inverted. Per-output, matching waybar's `all-outputs: false`.
Rectangle {
    id: root

    required property var screen

    // ponytail: re-filters when workspaces are created/destroyed, not when an
    // existing one is dragged to another monitor. Swap to a Connections on
    // Hyprland.rawEvent("moveworkspace") if that turns out to bite.
    readonly property var list: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor?.name === root.screen.name)

    implicitWidth: row.implicitWidth + 2
    implicitHeight: Theme.barHeight - Theme.gap * 2
    color: Theme.surface
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
                color: active ? (ma.containsMouse ? Theme.activeHover : Theme.active) : ma.containsMouse ? Theme.surfaceHover : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.anim
                    }
                }

                BarText {
                    id: label
                    anchors.centerIn: parent
                    text: btn.modelData.name
                    color: btn.active ? Theme.fgInverted : Theme.fgMuted
                    font.weight: btn.active ? 700 : Theme.weight
                }

                // waybar pulsed urgent workspaces between 45% and 75% white.
                // Kept on a separate layer so it can't clobber the colour
                // binding above the way an animation on `color` would.
                Rectangle {
                    anchors.fill: parent
                    color: Theme.active
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

                // waybar's `border-right` on every button but the last
                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    visible: btn.index < root.list.length - 1
                    color: Qt.rgba(1, 1, 1, 0.15)
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
