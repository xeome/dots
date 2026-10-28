import QtQuick
import QtQuick.Layouts
import Quickshell

// The chrome a bar popup shares: hung under its module on a Surface, one
// width and padding. Children go straight into the column. A derived menu's
// own onVisibleChanged runs alongside the one here.
PopupWindow {
    id: root

    required property Item anchorItem
    // Read by BarModule.openMenu: grabFocus dismisses on any outside click,
    // including the module click that meant "close".
    property double closedAt: 0

    default property alias content: body.data

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: 324
    implicitHeight: body.implicitHeight + Theme.pad * 2
    color: "transparent"
    visible: false
    grabFocus: true

    onVisibleChanged: if (!visible)
        closedAt = Date.now()

    Surface {
        anchors.fill: parent

        ColumnLayout {
            id: body

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.pad
                rightMargin: Theme.pad
            }
            spacing: 8
        }
    }
}
