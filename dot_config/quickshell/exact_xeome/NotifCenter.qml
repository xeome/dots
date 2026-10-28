import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// The notification centre, opened from Bell: history and Do Not Disturb.
//
// A full-screen layer rather than a PopupWindow, so the empty area around the
// panel is the click-to-dismiss target.
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

    Surface {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: Theme.barHeight + 8
            rightMargin: 10
        }
        width: 420
        height: 520

        // Keeps clicks on the panel from reaching the dismiss area. Declared
        // first, so the controls below sit on top of it.
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
                    color: Theme.bright
                }

                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + 20
                    implicitHeight: 28
                    radius: Theme.radius
                    color: clearMa.containsMouse ? Theme.hover : "transparent"
                    border.width: 1
                    border.color: Theme.line

                    BarText {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "󰎟  Clear"
                        font.pixelSize: Theme.size - 2
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
                radius: Theme.radius
                color: dndMa.containsMouse ? Theme.hover : "transparent"
                border.width: 1
                border.color: Theme.line

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
                    // Fully round: Theme.radius is for boxes, not a knob's track.
                    radius: height / 2
                    color: Notifs.dnd ? Theme.sel : "transparent"
                    border.width: 1
                    border.color: Theme.line

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.anim
                            easing.type: Theme.ease
                        }
                    }

                    Rectangle {
                        y: 2
                        x: Notifs.dnd ? 22 : 2
                        width: 16
                        height: 16
                        radius: height / 2
                        color: Notifs.dnd ? Theme.bright : Theme.dim

                        Behavior on x {
                            NumberAnimation {
                                duration: Theme.anim
                                easing.type: Theme.ease
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
                    color: Theme.dim
                    weight: 450
                }
            }
        }
    }
}
