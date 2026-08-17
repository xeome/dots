import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets

// One notification, shared by the popup stack and the history list. The 2px
// left edge is the urgency: warn red for critical, a quiet accent for
// everything else.
//
// ponytail: no inline replies — that needs state the Notification object
// doesn't carry; add it if you miss it.
Rectangle {
    id: root

    required property var notif
    // Only the history list asks for it: a popup is by definition seconds old,
    // so an age there is a permanent, pointless "now".
    property bool showAge: false

    signal dismissed

    // The popup stack stops its expiry countdown while you're on a card, so
    // reaching for an action button doesn't race it.
    readonly property bool hovered: ma.containsMouse
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property string age: root.showAge && root.notif ? Notifs.age(root.notif) : ""
    // Spec reserves the "default" action id for click-to-activate on the
    // notification body itself — it isn't meant to get its own button.
    readonly property var defaultAction: notif?.actions.find(a => a.identifier === "default") ?? null
    readonly property var otherActions: notif?.actions.filter(a => a.identifier !== "default") ?? []

    implicitWidth: 400
    implicitHeight: Math.max(64, col.implicitHeight + 28)
    color: ma.containsMouse ? Theme.cardHover : Theme.card
    radius: Theme.radiusLg
    border.width: 1
    border.color: Theme.border

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
        }
    }

    // Follows the card's corners rather than being clipped by them: Qt's `clip`
    // is a rectangular scissor and would square this strip's ends back off.
    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 2
        topLeftRadius: root.radius
        bottomLeftRadius: root.radius
        color: root.critical ? Theme.warn : Theme.accent
        opacity: root.critical ? 1 : 0.4
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        // No dismiss() after invoke(): see the action buttons' MouseArea below.
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
            color: Theme.fgDim
            font.pixelSize: Theme.size - 3
        }

        BarText {
            width: parent.width
            text: root.notif?.summary ?? ""
            font.pixelSize: Theme.size + 3
            weight: 650
            elide: Text.ElideRight
        }

        BarText {
            width: parent.width
            visible: text !== ""
            text: root.notif?.body ?? ""
            color: Theme.fgDim
            weight: 450
            textFormat: Text.StyledText   // swaync advertised body markup
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
                    color: actionMa.containsMouse ? Theme.surfaceHover : "transparent"
                    border.width: 1
                    border.color: actionMa.containsMouse ? Theme.borderHover : Theme.border

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
        radius: Theme.radius - 2
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
