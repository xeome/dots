import QtQuick
import QtQuick.Layouts

// The bordered box every right-side bar module sits in — waybar's shared
// `#network, #custom-vpn, #pulseaudio, #battery, ...` rule, including its
// 0.2s hover transition.
Rectangle {
    id: root

    // This theme's only accent: white fill, black text.
    property bool inverted: false
    // waybar's `min-width: 60px`, which is there to stop a module resizing the
    // whole row every time its text changes width — a muted Audio collapsing to
    // one glyph, a Battery crossing 100%. Modules that only ever draw a single
    // glyph can't jitter, so they set this to 0 and come out square instead of
    // padded out to a box two thirds empty.
    property int minWidth: 60
    // False for modules inside a connected strip, which is bordered as a
    // group — otherwise every junction draws a seam.
    property bool bordered: true
    property string tooltipText: ""
    default property alias content: layout.data
    property alias spacing: layout.spacing

    signal clicked(int button)

    readonly property bool hovered: ma.containsMouse
    // Modules bind their labels/icons to this so inversion flips them too.
    readonly property color fg: inverted ? Theme.fgInverted : Theme.fg

    implicitWidth: Math.max(minWidth, layout.implicitWidth + Theme.pad * 2)
    implicitHeight: Theme.barHeight - Theme.gap * 2

    color: inverted ? (hovered ? Theme.activeHover : Theme.active) : (hovered ? Theme.surfaceHover : Theme.surface)
    border.width: bordered ? 1 : 0
    border.color: hovered ? Theme.borderHover : Theme.border

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
                font.weight: 500
            }
        }
    ]
}
