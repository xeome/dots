import QtQuick
import QtQuick.Layouts
import Quickshell

// The chrome every bar popup shares: hung under its module, opaque panel,
// hairline border, one radius, one width, one padding. Children go straight
// into the column — a menu is its rows and nothing else.
//
// A menu that needs to do more on open or close declares its own
// `onVisibleChanged` and both run; a handler here isn't replaced by one in a
// derived menu.
PopupWindow {
    id: root

    required property Item anchorItem
    // Read by the module that owns this menu: grabFocus dismisses on any outside
    // click — including the click on the module that meant "close" — so that
    // click must not immediately reopen what it just closed.
    property double closedAt: 0
    property int pad: 12
    property alias spacing: body.spacing

    default property alias content: body.data

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: 324
    implicitHeight: body.implicitHeight + pad * 2
    color: "transparent"
    visible: false
    grabFocus: true

    onVisibleChanged: if (!visible)
        closedAt = Date.now()

    Rectangle {
        anchors.fill: parent
        color: Theme.panel
        radius: Theme.radiusLg
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            id: body

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: root.pad
                rightMargin: root.pad
            }
            spacing: 8
        }
    }
}
