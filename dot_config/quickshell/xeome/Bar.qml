import QtQuick
import Quickshell
import Quickshell.Wayland

// waybar: 48px top bar, one per monitor.
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

        // waybar's `border-bottom: 1px solid alpha(@outline, 0.15)`
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Qt.rgba(1, 1, 1, 0.15)
        }
    }

    Workspaces {
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
    }

    Row {
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        spacing: 4

        Media {}
        Clock {}

        // waybar stripped the inner left/right borders off these so they read
        // as one connected strip. The border is drawn once, over the whole
        // group, rather than per module — overlapping per-module borders still
        // leaves a visible seam at every junction.
        Item {
            implicitWidth: strip.implicitWidth
            implicitHeight: strip.implicitHeight

            Row {
                id: strip
                spacing: 0

                Net {
                    bordered: false
                }
                Mic {
                    bordered: false
                }
                Volume {
                    bordered: false
                }
                Battery {
                    bordered: false
                }
                Idle {
                    bordered: false
                    window: root
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
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
