import QtQuick
import QtQuick.Layouts

// A slider: an 8px bar in an 18px hit area. Drag, click and scroll report an
// unclamped fraction through moved(); the owner decides whether `value` follows.
Item {
    id: root

    property real value: 0
    signal moved(real fraction)

    Layout.fillWidth: true
    implicitHeight: 18

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: 8
        radius: height / 2
        color: Theme.rule

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: height / 2
            color: ma.containsMouse ? Theme.bright : Theme.text
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onPressed: e => root.moved(e.x / root.width)
        onPositionChanged: e => {
            if (pressed)
                root.moved(e.x / root.width);
        }
        onWheel: e => root.moved(root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}
