import QtQuick
import QtQuick.Layouts

// A row you press to choose something. The thing you're on and the things you
// could switch to are the same control, so they're the same component —
// stacked, they read the way a select reads when it drops open.
//
// AudioMenu picks sinks and sources with it; MediaMenu picks players.
Rectangle {
    id: root

    required property string label
    property string suffix: ""
    property bool current: false
    property bool selectable: true

    signal clicked

    Layout.fillWidth: true
    implicitHeight: 28
    color: root.current ? Theme.active : ma.containsMouse ? Theme.surfaceHover : "transparent"
    border.width: 1
    border.color: root.current ? Theme.active : ma.containsMouse ? Theme.borderHover : Theme.border

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
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
            color: root.current ? Theme.fgInverted : Theme.fg
        }

        BarText {
            visible: root.suffix !== ""
            text: root.suffix
            font.pixelSize: Theme.size - 2
            color: root.current ? Theme.fgInverted : Theme.fgDim
        }
    }

    MouseArea {
        id: ma

        anchors.fill: parent
        hoverEnabled: true
        // One option is still worth showing, but nothing about it should light
        // up under the cursor — there's nowhere to go.
        enabled: root.selectable
        onClicked: root.clicked()
    }
}
