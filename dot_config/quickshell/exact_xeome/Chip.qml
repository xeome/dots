import QtQuick

// A mode or tool in Shot's and ShotEditor's pills. Selected is `sel`, never a colour.
Rectangle {
    id: chip

    property alias text: label.text
    property bool on

    signal clicked

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 30
    radius: Theme.radius
    color: chip.on ? Theme.sel : chipMa.containsMouse ? Theme.hover : "transparent"

    BarText {
        id: label

        anchors.centerIn: parent
        color: chip.on ? Theme.bright : Theme.dim
        weight: chip.on ? 650 : Theme.weight
    }

    MouseArea {
        id: chipMa

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
