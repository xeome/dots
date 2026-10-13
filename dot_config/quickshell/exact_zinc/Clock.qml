import QtQuick
import Quickshell

// waybar `clock`: permanently inverted focal anchor. Click opens the calendar.
BarModule {
    id: root

    inverted: true

    // Only ever has to open. If the calendar was up, its own grabFocus already
    // dismissed it on this very click — see Calendar.closedAt.
    onClicked: if (!cal.visible && Date.now() - cal.closedAt > 200)
        cal.visible = true

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    BarText {
        text: Qt.formatDateTime(clock.date, "HH:mm  ddd dd MMM")
        color: root.fg
    }

    // A PopupWindow isn't an Item, so the RowLayout that BarModule's default
    // property points at stores it without trying to lay it out.
    Calendar {
        id: cal
        anchorItem: root
        today: clock.date
    }
}
