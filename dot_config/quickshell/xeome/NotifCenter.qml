import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// swaync's control centre, cut down to what it was actually for: notification
// history plus DND. The button grid, mpris widget and per-app volume are gone
// — two of those buttons pointed at scripts that don't exist, and mpris is
// already in the bar.
//
// A full-screen layer rather than a PopupWindow, for two reasons: Hyprland's
// blur rules only reach layer surfaces, not the xdg-popups a PopupWindow
// creates, and the empty area around the panel doubles as the click-to-dismiss
// target that PopupWindow.grabFocus used to provide.
PanelWindow {
    id: root

    WlrLayershell.namespace: "quickshell-notifications"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: Theme.barHeight + 8
            rightMargin: 10
        }
        width: 420
        height: 520
        color: Theme.bar
        border.width: 1
        border.color: Theme.border

        // Swallows clicks on the panel itself so they don't reach the
        // dismiss area behind it. Declared first, so the controls below
        // still sit on top of it.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                BarText {
                    Layout.fillWidth: true
                    text: "󰂚  Notifications"
                    font.pixelSize: Theme.size + 3
                }

                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + 20
                    implicitHeight: 28
                    color: clearMa.containsMouse ? Theme.surfaceHover : "transparent"
                    border.width: 1
                    border.color: Theme.border

                    BarText {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "󰎟  Clear"
                        font.pixelSize: Theme.size - 2
                        font.weight: 500
                    }

                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            Rule {}

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                color: dndMa.containsMouse ? Theme.surfaceHover : "transparent"
                border.width: 1
                border.color: Theme.border

                BarText {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Do Not Disturb"
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    implicitWidth: 40
                    implicitHeight: 20
                    color: Notifs.dnd ? Theme.active : "transparent"
                    border.width: 1
                    border.color: Theme.border

                    Rectangle {
                        y: 2
                        x: Notifs.dnd ? 22 : 2
                        width: 16
                        height: 16
                        color: Notifs.dnd ? Theme.fgInverted : Theme.fg

                        Behavior on x {
                            NumberAnimation {
                                duration: Theme.anim
                            }
                        }
                    }
                }

                MouseArea {
                    id: dndMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Notifs.dnd = !Notifs.dnd
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: Notifs.history

                delegate: NotifCard {
                    id: card

                    required property var modelData

                    width: ListView.view.width
                    notif: modelData
                    showAge: true
                    onDismissed: card.modelData.dismiss()
                }

                BarText {
                    anchors.centerIn: parent
                    visible: Notifs.history.length === 0
                    text: "No notifications"
                    color: Theme.fgMuted
                    font.weight: 450
                }
            }
        }
    }
}
