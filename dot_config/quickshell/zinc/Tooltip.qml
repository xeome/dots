import QtQuick
import Quickshell

// waybar got tooltips from GTK; quickshell has none, so this is the one
// implementation the whole bar shares. Clock uses it directly for its
// calendar; everything else goes through BarModule.tooltipText.
PopupWindow {
    id: root

    required property Item anchorItem
    property int delay: 400
    default property alias content: body.data

    // `hovered` is the caller's intent; `visible` lags it by `delay`.
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
        interval: root.delay
        running: root.hovered
        onTriggered: root.visible = true
    }

    onHoveredChanged: if (!hovered) visible = false

    Rectangle {
        anchors.fill: parent
        color: Theme.panel
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.3)

        Column {
            id: body
            anchors.centerIn: parent
            spacing: 2
        }
    }
}
