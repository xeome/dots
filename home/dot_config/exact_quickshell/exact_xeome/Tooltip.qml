import QtQuick
import Quickshell

// The bar's hover tooltip. Tray uses it directly; modules go through
// BarModule.tooltipText.
PopupWindow {
    id: root

    required property Item anchorItem
    default property alias content: body.data

    // `hovered` is the caller's intent; `visible` follows it after a delay.
    property bool hovered: false

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 4

    implicitWidth: body.implicitWidth + Theme.pad * 2
    implicitHeight: body.implicitHeight + Theme.pad
    color: "transparent"
    visible: false

    Timer {
        interval: 400
        running: root.hovered
        onTriggered: root.visible = true
    }

    onHoveredChanged: if (!hovered) visible = false

    Surface {
        anchors.fill: parent
        radius: Theme.radius

        Column {
            id: body
            anchors.centerIn: parent
            spacing: 2
        }
    }
}
