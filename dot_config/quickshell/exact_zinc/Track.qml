import QtQuick
import QtQuick.Layouts

// 8px of bar in 18px of hit area: the visual weight the OSD uses, with a target
// you can actually hit. Drag, click-to-seek and scroll all report a fraction;
// whoever placed it decides what that means and whether it sticks.
Item {
    id: root

    property real value: 0
    signal moved(real fraction)

    function clamp(v: real): real {
        return Math.max(0, Math.min(1, v));
    }

    Layout.fillWidth: true
    implicitHeight: 18

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: 8
        color: Qt.rgba(1, 1, 1, 0.15)

        Rectangle {
            width: parent.width * root.clamp(root.value)
            height: parent.height
            color: ma.containsMouse ? Theme.fg : Qt.rgba(1, 1, 1, 0.75)
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
