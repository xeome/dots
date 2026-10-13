import QtQuick
import QtQuick.Layouts

// The rounded box every right-side bar module sits in, including its 0.2s hover
// transition. A graphite card: a nearly clear fill, a translucent line, a dark
// ring outside it and a lit top edge (CardEdges).
Rectangle {
    id: root

    // The signal split. "" is the resting state; the two other tones each mean
    // one thing shell-wide:
    //   "sel"   you switched something on      (DND, idle inhibitor): the
    //           same 7% white as a selected menu row, no colour
    //   "warn"  something wants your attention (low battery): hot
    property string tone: ""
    // Stops a module resizing the whole row every time its text changes width —
    // a muted Audio collapsing to one glyph, a Battery crossing 100%. Modules
    // that only ever draw a single glyph can't jitter, so they set this to 0
    // and come out square instead of padded out to a box two thirds empty.
    property int minWidth: 60
    // False for modules inside a connected strip, which is bordered and rounded
    // as a group — otherwise every junction draws a seam.
    property bool bordered: true
    property string tooltipText: ""
    default property alias content: layout.data
    property alias spacing: layout.spacing

    signal clicked(int button)

    readonly property bool hovered: ma.containsMouse
    // Modules bind their labels/icons to this so a fill takes its text with it.
    readonly property color fg: tone === "warn" ? Theme.ground : tone === "sel" ? Theme.bright : Theme.text

    implicitWidth: Math.max(minWidth, layout.implicitWidth + Theme.pad * 2)
    implicitHeight: Theme.barHeight - Theme.gap * 2

    radius: bordered ? Theme.radius : 0
    color: tone === "warn" ? (hovered ? Qt.lighter(Theme.hot, 1.1) : Theme.hot) : tone === "sel" ? (hovered ? Theme.line : Theme.sel) : hovered ? Theme.hover : Theme.card
    border.width: bordered ? 1 : 0
    // The hot fill draws its own edge; a line on top of it only muddies the one
    // thing on the bar that is meant to be unambiguous.
    border.color: tone === "warn" ? "transparent" : Theme.line

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: Theme.anim
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
