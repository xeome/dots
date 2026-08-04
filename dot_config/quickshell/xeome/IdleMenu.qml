import QtQuick
import QtQuick.Layouts

// The idle inhibitor's menu. Left-clicking the module is still the switch —
// this is for the case that needs a decision rather than a toggle: keep the
// screen up for as long as the thing I'm doing lasts, and put it back on its
// own afterwards, because the failure mode of this module is leaving it on for
// three days and wondering why the laptop is warm.
//
// Picking the duration that's already running turns it off, the way clicking a
// connected device in BtMenu disconnects it.
Menu {
    id: root

    // -1 off, 0 indefinite, otherwise minutes.
    required property int span
    // Formatted by the module, which owns the clock this counts down.
    property string remaining: ""

    signal picked(int minutes)

    readonly property var options: [
        {
            label: "15 minutes",
            minutes: 15
        },
        {
            label: "30 minutes",
            minutes: 30
        },
        {
            label: "1 hour",
            minutes: 60
        },
        {
            label: "2 hours",
            minutes: 120
        },
        {
            label: "4 hours",
            minutes: 240
        },
        {
            label: "Until I turn it off",
            minutes: 0
        }
    ]

    BarText {
        Layout.fillWidth: true
        text: root.span < 0 ? "󰾪  Sleep allowed" : root.span === 0 ? "󰅶  Staying awake" : `󰅶  Staying awake · ${root.remaining} left`
        font.pixelSize: Theme.size - 2
        color: root.span < 0 ? Theme.fgDim : Theme.fg
    }

    Rule {}

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: root.options

            delegate: Pick {
                required property var modelData

                label: modelData.label
                current: root.span === modelData.minutes
                onClicked: root.picked(modelData.minutes)
            }
        }
    }
}
