import QtQuick
import Quickshell

// A click-opened bar popup, hung under its module on a Surface. Derived
// popups set contentWidth and contentHeight; their children go onto the
// Surface. Hyprland fades the window in and out; the Surface adds a short
// drift down into place on the way in.
PopupWindow {
    id: root

    required property Item anchorItem
    // Read by BarModule.openMenu: grabFocus dismisses on any outside click,
    // including the module click that meant "close".
    property double closedAt: 0

    property real contentWidth
    property real contentHeight

    default property alias content: surface.data

    // The window is this much taller than the Surface, which rests at its
    // bottom: the drift has room without clipping the Surface's top edge.
    readonly property int drift: 6

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    implicitWidth: contentWidth
    implicitHeight: contentHeight + drift
    color: "transparent"
    visible: false
    grabFocus: true

    onVisibleChanged: {
        if (visible)
            enter.restart();
        else
            closedAt = Date.now();
    }

    Surface {
        id: surface

        width: parent.width
        height: root.contentHeight
        y: root.drift

        NumberAnimation on y {
            id: enter
            from: 0
            to: root.drift
            duration: Theme.anim
            easing.type: Theme.ease
            running: false
        }
    }
}
