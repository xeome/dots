import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// waybar `group/tray-expander`: a chevron that reveals the tray on hover.
Rectangle {
    id: root

    // The open menu is a grabbing popup, so the compositor takes the pointer
    // away from this surface and `hover` goes false. Without the second term
    // the drawer would collapse, destroy the delegate, and take the menu down
    // with it the instant it appeared.
    readonly property bool expanded: hover.containsMouse || menuOpen
    property bool menuOpen: false

    // Bound eagerly: quickshell's service singletons only start syncing when
    // something references them, and reading this first inside the Repeater
    // would leave the drawer empty for seconds after the first open.
    readonly property var items: SystemTray.items.values

    // Ayatana indicators publish no Activate method at all — their whole UI is
    // the menu — so a left click on one is a D-Bus call into nothing. They
    // still report onlyMenu=false, so there is no flag to key off; waybar hid
    // this by falling back to the menu whenever Activate returned an error.
    // ponytail: an id list, since quickshell surfaces neither the flag nor the
    // failed call. Append ids as they turn up (blueman, print-applet, …).
    readonly property var menuOnlyIds: ["nm-applet"]

    implicitWidth: layout.implicitWidth + Theme.pad * 2
    implicitHeight: Theme.barHeight - Theme.gap * 2
    color: Theme.surface
    border.width: 1
    border.color: Theme.border

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 325   // waybar's drawer transition-duration
            easing.type: Easing.OutCubic
        }
    }

    // Covers the whole drawer so it stays open as you move onto the icons.
    // Declared first so the per-icon areas below sit on top for clicks; those
    // deliberately leave hoverEnabled off, or they'd steal the hover here and
    // collapse the drawer the moment you reached for an icon.
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
                    // waybar dimmed passive items via -gtk-icon-effect
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
}
