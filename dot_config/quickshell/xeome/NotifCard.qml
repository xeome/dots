import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets

// One notification, shared by the popup stack and the history list.
// swaync's 2px accent left-border becomes white here: dim for normal,
// solid for critical, since this theme has no hues.
//
// ponytail: no timestamps and no inline replies. Both need state the
// Notification object doesn't carry; add them if you miss them.
Rectangle {
    id: root

    required property var notif
    signal dismissed

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical

    implicitWidth: 400
    implicitHeight: Math.max(64, col.implicitHeight + 28)
    color: ma.containsMouse ? Theme.glassHover : Theme.glass
    border.width: 1
    border.color: Theme.border

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 2
        color: Theme.fg
        opacity: root.critical ? 1 : 0.35
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.dismissed()
    }

    IconImage {
        id: icon
        anchors {
            left: parent.left
            leftMargin: 18
            verticalCenter: parent.verticalCenter
        }
        implicitSize: 32
        visible: source != ""
        source: root.notif?.image || root.notif?.appIcon || ""
    }

    Column {
        id: col
        anchors {
            left: icon.visible ? icon.right : parent.left
            right: close.left
            leftMargin: icon.visible ? 12 : 18
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        spacing: 3

        BarText {
            text: root.notif?.appName ?? ""
            color: Theme.fgMuted
            font.pixelSize: Theme.size - 3
        }

        BarText {
            width: parent.width
            text: root.notif?.summary ?? ""
            font.weight: 650
            elide: Text.ElideRight
            color: root.critical ? Theme.fg : Theme.fg
        }

        BarText {
            width: parent.width
            visible: text !== ""
            text: root.notif?.body ?? ""
            color: Theme.fgMuted
            font.weight: 450
            textFormat: Text.StyledText   // swaync advertised body markup
            wrapMode: Text.Wrap
            maximumLineCount: 6
            elide: Text.ElideRight
        }

        Row {
            spacing: 6
            visible: (root.notif?.actions.length ?? 0) > 0
            topPadding: 4

            Repeater {
                model: root.notif?.actions ?? []

                delegate: Rectangle {
                    id: action

                    required property var modelData

                    implicitWidth: actionLabel.implicitWidth + 20
                    implicitHeight: 26
                    color: actionMa.containsMouse ? Theme.surfaceHover : "transparent"
                    border.width: 1
                    border.color: Theme.border

                    BarText {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: action.modelData.text
                        font.pixelSize: Theme.size - 2
                        font.weight: 500
                    }

                    MouseArea {
                        id: actionMa
                        anchors.fill: parent
                        hoverEnabled: true
                        // No dismiss() after this: invoking an action closes a
                        // non-resident notification, which destroys this card
                        // mid-handler — the next line ran against a dead root.
                        onClicked: action.modelData.invoke()
                    }
                }
            }
        }
    }

    Rectangle {
        id: close
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: 8
            topMargin: 8
        }
        implicitWidth: 22
        implicitHeight: 22
        color: closeMa.containsMouse ? Theme.surfaceHover : "transparent"

        BarText {
            anchors.centerIn: parent
            text: "✕"
            font.pixelSize: Theme.size - 2
            color: closeMa.containsMouse ? Theme.fg : Theme.fgMuted
        }

        MouseArea {
            id: closeMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.notif.dismiss();
                root.dismissed();
            }
        }
    }
}
