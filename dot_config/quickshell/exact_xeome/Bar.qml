import QtQuick
import Quickshell
import Quickshell.Wayland

// 48px top bar, one per monitor. Edge-to-edge and square on purpose: a radius
// in this shell means "this responds to you", and the bar itself does not.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell-bar"
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: "transparent"

    Surface {
        anchors.fill: parent
        fill: Theme.ground
        radius: 0
        edged: false
        glow: Theme.glow
        glowFar: "transparent"
        glowSize: 600
        grain: "grain-ground.png"

        // The bar's only edge: the translucent line, with the dark ring as the
        // outermost pixel below it.
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: 1
            }
            height: 1
            color: Theme.line
        }
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.ring
        }
    }

    Workspaces {
        id: workspaces
        screen: root.modelData
        anchors {
            left: parent.left
            leftMargin: Theme.pad
            verticalCenter: parent.verticalCenter
        }
    }

    WindowTitle {
        screen: root.modelData
        anchors.centerIn: parent
        // Centred, so clamp to the room left by the wider of the two sides.
        width: Math.min(implicitWidth, Math.max(0, 2 * (root.width / 2 - Theme.pad - Math.max(workspaces.width, rightRow.width) - 16)))
    }

    Row {
        id: rightRow
        anchors {
            right: parent.right
            rightMargin: Theme.pad
            verticalCenter: parent.verticalCenter
        }
        spacing: 4

        Media {}
        Clock {}

        // One connected strip, bordered once over the group because
        // per-module borders seam at every junction. The end modules round
        // their own outer corners: `clip` is a rectangular scissor.
        Item {
            implicitWidth: strip.implicitWidth
            implicitHeight: strip.implicitHeight

            Row {
                id: strip
                spacing: 0

                Net {
                    id: net
                    bordered: false
                    topLeftRadius: Theme.radius
                    bottomLeftRadius: Theme.radius
                }
                Audio {
                    bordered: false
                    topLeftRadius: net.visible ? 0 : Theme.radius
                    bottomLeftRadius: net.visible ? 0 : Theme.radius
                }
                Battery {
                    bordered: false
                }
                Idle {
                    bordered: false
                    window: root
                    topRightRadius: Theme.radius
                    bottomRightRadius: Theme.radius
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: Theme.radius
                border.width: 1
                border.color: Theme.line

                CardEdges {}
            }
        }

        Bell {
            screen: root.modelData
        }
        Tray {}
    }
}
