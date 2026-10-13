import QtQuick
import QtQuick.Layouts
import Quickshell

// The clock's calendar. Click-toggled rather than hover-shown: a popup that
// dies on mouse-leave has no month arrows you can actually reach.
PopupWindow {
    id: root

    required property Item anchorItem
    // Today, live from the clock, so both the highlight and the reset target
    // roll over at midnight with the popup open.
    required property var today

    // Months away from today. The arrows walk it; the title resets it.
    property int offset: 0

    // grabFocus dismisses on any outside click — including the click on the
    // clock that meant "close". Clock reads this so that click doesn't
    // immediately reopen what it just closed.
    property double closedAt: 0

    readonly property var first: new Date(today.getFullYear(), today.getMonth() + offset, 1)

    // ISO-8601: week 1 is the one holding the year's first Thursday.
    function isoWeek(monday: var): int {
        const thu = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 3);
        const jan1 = new Date(thu.getFullYear(), 0, 1);
        // Round before dividing: a DST boundary in between leaves the raw
        // millisecond gap an hour short of a whole number of days.
        return Math.floor(Math.round((thu - jan1) / 86400000) / 7) + 1;
    }

    readonly property int todayWeek: isoWeek(new Date(today.getFullYear(), today.getMonth(), today.getDate() - (today.getDay() + 6) % 7))

    // Six Monday-first weeks — enough for any month, including a 31-day one
    // that starts on a Sunday.
    readonly property var weeks: {
        const origin = new Date(first.getFullYear(), first.getMonth(), 1 - (first.getDay() + 6) % 7);
        const out = [];
        for (let w = 0; w < 6; w++) {
            const monday = new Date(origin.getFullYear(), origin.getMonth(), origin.getDate() + w * 7);
            const days = [];
            for (let d = 0; d < 7; d++) {
                const c = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + d);
                days.push({
                    day: c.getDate(),
                    inMonth: c.getMonth() === first.getMonth(),
                    today: c.toDateString() === today.toDateString(),
                    weekend: d > 4
                });
            }
            out.push({
                week: isoWeek(monday),
                days: days
            });
        }
        return out;
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: body.implicitWidth + 28
    implicitHeight: body.implicitHeight + 28
    color: "transparent"
    visible: false
    grabFocus: true

    onVisibleChanged: if (!visible) {
        closedAt = Date.now();
        // Reopening should land on the current month, not wherever you browsed to.
        offset = 0;
    }

    component NavButton: Rectangle {
        id: nav

        property string glyph
        signal activated

        implicitWidth: 26
        implicitHeight: 26
        color: navMa.containsMouse ? Theme.surfaceHover : "transparent"
        border.width: 1
        border.color: navMa.containsMouse ? Theme.borderHover : Theme.border

        BarText {
            anchors.centerIn: parent
            text: nav.glyph
        }

        MouseArea {
            id: navMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: nav.activated()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.panel
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            id: body
            anchors.centerIn: parent
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                NavButton {
                    glyph: "󰅁"
                    onActivated: root.offset--
                }

                BarText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDateTime(root.first, "MMMM yyyy")
                    font.pixelSize: Theme.size + 1
                    // Dimmed once you've browsed away, as a hint that it's the
                    // way back.
                    color: root.offset === 0 ? Theme.fg : Theme.fgDim

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.offset = 0
                    }
                }

                NavButton {
                    glyph: "󰅂"
                    onActivated: root.offset++
                }
            }

            Rule {}

            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                Row {
                    spacing: 2

                    // Spacer above the week-number column.
                    Item {
                        width: 24
                        height: 20
                    }

                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                        delegate: BarText {
                            required property int index
                            required property string modelData

                            width: 32
                            height: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                            font.pixelSize: Theme.size - 3
                            color: index > 4 ? Theme.fgMuted : Theme.fgDim
                        }
                    }
                }

                Repeater {
                    model: root.weeks

                    delegate: Row {
                        id: weekRow

                        required property var modelData

                        spacing: 2

                        BarText {
                            width: 24
                            height: 26
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: weekRow.modelData.week
                            font.pixelSize: Theme.size - 3
                            font.weight: 500
                            color: weekRow.modelData.week === root.todayWeek && root.offset === 0 ? Theme.fgDim : Theme.fgMuted
                        }

                        Repeater {
                            model: weekRow.modelData.days

                            delegate: Rectangle {
                                id: cell

                                required property var modelData

                                width: 32
                                height: 26
                                color: cell.modelData.today ? Theme.active : "transparent"

                                BarText {
                                    anchors.centerIn: parent
                                    text: cell.modelData.day
                                    font.weight: cell.modelData.today ? 700 : 500
                                    color: cell.modelData.today ? Theme.fgInverted : !cell.modelData.inMonth ? Theme.fgMuted : cell.modelData.weekend ? Theme.fgDim : Theme.fg
                                }
                            }
                        }
                    }
                }
            }

            Rule {}

            BarText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(root.today, "dddd, d MMMM yyyy") + "  ·  week " + root.todayWeek
                font.pixelSize: Theme.size - 2
                font.weight: 500
                color: Theme.fgDim
            }
        }
    }
}
