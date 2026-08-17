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

    Rectangle {
        anchors.fill: parent
        color: Theme.bar

        // The bar's only edge. Full-strength border rather than the dimmer
        // divider: this one separates the shell from arbitrary window content,
        // not two rows of the same panel.
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.border
        }
    }

    Workspaces {
        id: workspaces
        screen: root.modelData
        anchors {
            left: parent.left
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
    }

    WindowTitle {
        screen: root.modelData
        anchors.centerIn: parent
        // Workspaces and the right-side Row both change width at runtime
        // (workspace count, tray items, wifi visibility...); centerIn alone
        // doesn't know that, so a long title can slide under either one.
        // Clamp to whichever side is currently closer to center.
        width: Math.min(implicitWidth, Math.max(0, 2 * (Math.min(root.width / 2 - 10 - workspaces.width, root.width / 2 - 10 - rightRow.width) - 16)))
    }

    Row {
        id: rightRow
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        spacing: 4

        Media {}
        Clock {}

        // These four read as one connected strip: no inner borders, and the
        // outer border is drawn once over the whole group rather than per
        // module, since overlapping per-module borders leave a visible seam at
        // every junction.
        //
        // The rounding follows the same logic. `clip` is a rectangular scissor
        // in Qt and would square the corners straight back off, so the end
        // members carry the radius themselves via per-corner properties — the
        // group is round because its ends are, not because something masks it.
        Item {
            implicitWidth: strip.implicitWidth
            implicitHeight: strip.implicitHeight

            Row {
                id: strip
                spacing: 0

                Net {
                    bordered: false
                    topLeftRadius: Theme.radius
                    bottomLeftRadius: Theme.radius
                }
                Audio {
                    bordered: false
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
                border.color: Theme.border
            }
        }

        Bell {
            screen: root.modelData
        }
        Tray {}
    }
}
