import QtQuick
import QtQuick.Layouts

// Idle's duration menu. Picking the duration already running turns it off.
Menu {
    id: root

    // -1 off, 0 indefinite, otherwise minutes.
    required property int span
    // Formatted by the module, which owns the clock this counts down.
    property string remaining: ""

    signal picked(int minutes)

    readonly property var options: [
        { label: "15 minutes", minutes: 15 },
        { label: "30 minutes", minutes: 30 },
        { label: "1 hour", minutes: 60 },
        { label: "2 hours", minutes: 120 },
        { label: "4 hours", minutes: 240 },
        { label: "Until I turn it off", minutes: 0 }
    ]

    BarText {
        Layout.fillWidth: true
        text: root.span < 0 ? "󰾪  Sleep allowed" : root.span === 0 ? "󰅶  Staying awake" : `󰅶  Staying awake · ${root.remaining} left`
        font.pixelSize: Theme.size - 2
        color: root.span < 0 ? Theme.dim : Theme.text
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
