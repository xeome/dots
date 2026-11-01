import QtQuick
import QtQuick.Layouts

// A menu row you press to choose something; the current choice and the
// alternatives are the same control, so a stack of them reads like an open
// select.
Rectangle {
    id: root

    required property string label
    property string suffix: ""
    property bool current: false
    property bool selectable: true

    signal clicked

    Layout.fillWidth: true
    implicitHeight: 30
    radius: Theme.radius
    color: root.current ? Theme.sel : ma.containsMouse ? Theme.hover : "transparent"
    border.width: 1
    border.color: Theme.line

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
            easing.type: Theme.ease
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 6

        BarText {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
            font.pixelSize: Theme.size - 2
            color: root.current ? Theme.bright : Theme.text
        }

        BarText {
            visible: root.suffix !== ""
            text: root.suffix
            font.pixelSize: Theme.size - 2
            color: root.current ? Theme.text : Theme.dim
        }
    }

    MouseArea {
        id: ma

        anchors.fill: parent
        hoverEnabled: true
        // Off when there is nothing else to pick, so the row shows no hover.
        enabled: root.selectable
        onClicked: root.clicked()
    }
}
