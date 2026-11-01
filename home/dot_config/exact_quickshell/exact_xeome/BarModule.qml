import QtQuick
import QtQuick.Layouts

// The rounded box every right-side bar module sits in: a graphite card with a
// nearly clear fill, a translucent line and CardEdges' ring and lit top edge.
Rectangle {
    id: root

    // "" at rest, "sel" for something you switched on (DND, idle inhibitor),
    // "warn" for something that wants your attention (low battery).
    property string tone: ""
    // Keeps the row from resizing when a label changes width. Single-glyph
    // modules set 0 so they come out square.
    property int minWidth: 60
    // False inside a connected strip, which is bordered as a group.
    property bool bordered: true
    // Modules blank this while their menu is open, since both hang below the
    // module and would stack.
    property string tooltipText: ""
    // A menu (a PopupWindow, not an Item) declared in a module lands here too,
    // and the RowLayout stores it without laying it out.
    default property alias content: layout.data

    signal clicked(int button)

    readonly property bool hovered: ma.containsMouse
    // Modules bind their labels to this so a fill takes its text with it.
    readonly property color fg: tone === "warn" ? Theme.ground : tone === "sel" ? Theme.bright : Theme.text

    // The menu's grabFocus already closed it on the click that lands here, so a
    // click right after closing must not reopen it.
    function openMenu(menu: var): void {
        if (!menu.visible && Date.now() - menu.closedAt > 200)
            menu.visible = true;
    }

    implicitWidth: Math.max(minWidth, layout.implicitWidth + Theme.pad * 2)
    implicitHeight: Theme.barHeight - Theme.gap * 2

    radius: bordered ? Theme.radius : 0
    color: tone === "warn" ? (hovered ? Qt.lighter(Theme.hot, 1.1) : Theme.hot) : tone === "sel" ? (hovered ? Theme.line : Theme.sel) : hovered ? Theme.hover : Theme.card
    border.width: bordered ? 1 : 0
    // No line over the hot fill: it would muddy the bar's one loud signal.
    border.color: tone === "warn" ? "transparent" : Theme.line

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
            easing.type: Theme.ease
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: Theme.anim
            easing.type: Theme.ease
        }
    }

    // Assigned to `data` explicitly: the default property is aliased to
    // layout.data, so bare children here would land inside the layout.
    data: [
        CardEdges {
            visible: root.bordered && root.tone !== "warn"
        },

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: 6
        },

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: e => root.clicked(e.button)
        },

        Tooltip {
            anchorItem: root
            hovered: root.hovered && root.tooltipText !== ""

            BarText {
                text: root.tooltipText
                color: Theme.text
            }
        }
    ]
}
