import QtQuick
import Quickshell

// The bar's anchor. It used to earn that by being permanently filled white,
// which spent the shell's one loud treatment on the module that never changes
// state — and made a battery at 25% look identical to a working clock. It
// anchors typographically now: larger, heavier, accent-coloured text on the
// same resting surface as everything else. Click opens the calendar.
BarModule {
    id: root

    // Only ever has to open. If the calendar was up, its own grabFocus already
    // dismissed it on this very click — see Calendar.closedAt.
    onClicked: if (!cal.visible && Date.now() - cal.closedAt > 200)
        cal.visible = true

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    BarText {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.accent
        font.pixelSize: Theme.size + 2
        weight: 650
    }

    BarText {
        text: Qt.formatDateTime(clock.date, "ddd dd MMM")
        color: Theme.fgDim
    }

    // A PopupWindow isn't an Item, so the RowLayout that BarModule's default
    // property points at stores it without trying to lay it out.
    Calendar {
        id: cal
        anchorItem: root
        today: clock.date
    }
}
