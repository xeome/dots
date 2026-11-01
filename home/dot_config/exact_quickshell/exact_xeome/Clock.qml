import QtQuick
import Quickshell

// Time and date, the bar's anchor through larger, heavier text rather than a
// fill.
BarModule {
    id: root

    property bool precise: false

    onClicked: button => {
        if (button === Qt.RightButton)
            root.precise = !root.precise;
        else
            root.openMenu(cal);
    }

    SystemClock {
        id: clock
        precision: root.precise ? SystemClock.Seconds : SystemClock.Minutes
    }

    BarText {
        text: Qt.formatDateTime(clock.date, root.precise ? "HH:mm:ss" : "HH:mm")
        color: Theme.bright
        font.pixelSize: Theme.size + 2
        weight: 650
    }

    BarText {
        text: Qt.formatDateTime(clock.date, root.precise ? "dd/MM/yyyy" : "ddd dd MMM")
        color: Theme.dim
    }

    Calendar {
        id: cal
        anchorItem: root
        today: clock.date
    }
}
