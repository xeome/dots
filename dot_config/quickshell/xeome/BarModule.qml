import QtQuick
import QtQuick.Layouts

// The rounded box every right-side bar module sits in, including its 0.2s hover
// transition.
Rectangle {
    id: root

    // The signal split. "" is the resting state; the three filled tones each
    // mean one thing shell-wide:
    //   "focus"   this is what you're on          (cream)
    //   "toggle"  you switched something on       (warm brown)
    //   "warn"    something wants your attention  (red)
    // These used to be one shared white fill, so a battery at 25% and a clock
    // that is always lit were visually identical.
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
    // Toggle is dark enough to keep light text; the other two fills are not.
    readonly property color fg: tone === "toggle" ? Theme.accent : tone !== "" ? Theme.fgOnAccent : Theme.fg

    implicitWidth: Math.max(minWidth, layout.implicitWidth + Theme.pad * 2)
    implicitHeight: Theme.barHeight - Theme.gap * 2

    radius: bordered ? Theme.radius : 0
    color: switch (tone) {
    case "focus":
        return hovered ? Theme.accentHover : Theme.accent;
    case "toggle":
        return hovered ? Theme.toggleHover : Theme.toggle;
    case "warn":
        return hovered ? Theme.warnHover : Theme.warn;
    default:
        return hovered ? Theme.surfaceHover : Theme.surface;
    }
    border.width: bordered ? 1 : 0
    // A filled module draws its own edge; a border on top of it only muddies
    // the one thing on the bar that is meant to be unambiguous.
    border.color: tone !== "" ? "transparent" : hovered ? Theme.borderHover : Theme.border

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
                color: Theme.fgDim
            }
        }
    ]
}
