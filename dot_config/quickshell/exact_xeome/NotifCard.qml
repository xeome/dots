import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets

// One notification, shared by the popup stack and the history list. A 2px hot
// left edge marks a critical one.
//
// ponytail: no inline replies; they need state the Notification object
// doesn't carry.
Surface {
    id: root

    required property var notif
    // Only the history list sets it; a popup's age would always read "now".
    property bool showAge: false

    signal dismissed

    // The popup stack stops its expiry countdown while this is true.
    readonly property bool hovered: ma.containsMouse
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property string age: root.showAge && root.notif ? Notifs.age(root.notif) : ""
    // The spec reserves the "default" action for a click on the body, not a
    // button.
    readonly property var defaultAction: notif?.actions.find(a => a.identifier === "default") ?? null
    readonly property var otherActions: notif?.actions.filter(a => a.identifier !== "default") ?? []

    implicitWidth: 400
    implicitHeight: Math.max(64, col.implicitHeight + 28)
    fill: ma.containsMouse ? Qt.tint(Theme.raised, Theme.hover) : Theme.raised

    Behavior on fill {
        ColorAnimation {
            duration: Theme.anim
        }
    }

    // Rounded itself because `clip` is a rectangular scissor and would square
    // the strip's ends. Inset by the card's 1px ring.
    Rectangle {
        visible: root.critical
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: 1
        }
        width: 2
        topLeftRadius: root.radius - 1
        bottomLeftRadius: root.radius - 1
        color: Theme.hot
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        // Nothing after invoke(): see the action buttons' MouseArea below.
        onClicked: root.defaultAction ? root.defaultAction.invoke() : root.dismissed()
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
            text: (root.notif?.appName ?? "") + (root.age === "" ? "" : `  ·  ${root.age}`)
            color: Theme.dim
            font.pixelSize: Theme.size - 3
        }

        BarText {
            width: parent.width
            text: root.notif?.summary ?? ""
            font.pixelSize: Theme.size + 3
            weight: 650
            color: Theme.bright
            elide: Text.ElideRight
        }

        BarText {
            width: parent.width
            visible: text !== ""
            text: root.notif?.body ?? ""
            color: Theme.text
            weight: 450
            textFormat: Text.StyledText   // Notifs advertises bodyMarkupSupported
            wrapMode: Text.Wrap
            maximumLineCount: 6
            elide: Text.ElideRight
        }

        Row {
            spacing: 6
            visible: root.otherActions.length > 0
            topPadding: 4

            Repeater {
                model: root.otherActions

                delegate: Rectangle {
                    id: action

                    required property var modelData

                    implicitWidth: actionLabel.implicitWidth + 20
                    implicitHeight: 28
                    radius: Theme.radius
                    color: actionMa.containsMouse ? Theme.hover : "transparent"
                    border.width: 1
                    border.color: Theme.line

                    BarText {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: action.modelData.text
                        font.pixelSize: Theme.size - 2
                    }

                    MouseArea {
                        id: actionMa
                        anchors.fill: parent
                        hoverEnabled: true
                        // Nothing after this: invoking an action closes a
                        // non-resident notification and destroys this card
                        // mid-handler. dismiss() on the close button does too.
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
        radius: Theme.radius - 2
        color: closeMa.containsMouse ? Theme.hover : "transparent"

        BarText {
            anchors.centerIn: parent
            text: "✕"
            font.pixelSize: Theme.size - 2
            color: closeMa.containsMouse ? Theme.text : Theme.dim
        }

        MouseArea {
            id: closeMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.notif.dismiss()
        }
    }
}
