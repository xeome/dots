import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// waybar `group/tray-expander`: a chevron that reveals the tray on hover.
Rectangle {
    id: root

    // An open menu grabs the pointer and `hover` goes false; without menuOpen
    // the drawer would collapse and destroy the delegate holding the menu.
    readonly property bool expanded: hover.containsMouse || menuOpen
    property bool menuOpen: false

    // Bound eagerly: the tray service only starts syncing once referenced, so
    // a first read inside the Repeater leaves the drawer empty for seconds.
    readonly property var items: SystemTray.items.values

    // Which icon the cursor is over, read off the drawer's own hover area. A
    // per-icon hover area or HoverHandler steals hover from it, and the drawer
    // then collapses and reopens in a loop under the cursor.
    readonly property var hoveredItem: {
        if (!hover.containsMouse)
            return null;

        const p = root.mapToItem(layout, hover.mouseX, hover.mouseY);
        // Misses on the chevron, which has no modelData to speak of.
        return layout.childAt(p.x, p.y)?.modelData ?? null;
    }

    // Ayatana indicators have no Activate method but still report
    // onlyMenu=false, so a left click on one does nothing.
    // ponytail: an id list, since quickshell exposes neither a flag nor the
    // failed call. Add ids as they turn up (blueman, print-applet).
    readonly property var menuOnlyIds: ["nm-applet"]

    implicitWidth: layout.implicitWidth + Theme.pad * 2
    implicitHeight: Theme.barHeight - Theme.gap * 2
    color: Theme.card
    radius: Theme.radius
    border.width: 1
    border.color: Theme.line

    CardEdges {}

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.anim
            easing.type: Theme.ease
        }
    }

    // Covers the whole drawer so it stays open over the icons. Declared first
    // so the per-icon click areas sit on top; those keep hoverEnabled off.
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 12

        BarText {
            text: root.expanded ? "󰅂" : "󰅁"
        }

        Repeater {
            model: root.expanded ? root.items : []

            delegate: Item {
                id: item

                required property var modelData

                implicitWidth: 18
                implicitHeight: 18

                IconImage {
                    anchors.fill: parent
                    source: item.modelData.icon
                    opacity: item.modelData.status === Status.Passive ? 0.5 : 1
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: e => {
                        if (e.button === Qt.MiddleButton)
                            item.modelData.secondaryActivate();
                        else if (item.modelData.hasMenu && (e.button === Qt.RightButton || root.menuOnlyIds.includes(item.modelData.id)))
                            menu.open();
                        else
                            item.modelData.activate();
                    }
                }

                QsMenuAnchor {
                    id: menu
                    menu: item.modelData.menu
                    anchor.item: item
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                    onVisibleChanged: root.menuOpen = visible
                }
            }
        }
    }

    // Anchored to the whole module like every bar tooltip; only the text
    // follows the icon under the cursor.
    Tooltip {
        anchorItem: root
        hovered: root.hoveredItem !== null

        BarText {
            text: root.hoveredItem?.tooltipTitle || root.hoveredItem?.title || root.hoveredItem?.id || ""
        }
    }
}
