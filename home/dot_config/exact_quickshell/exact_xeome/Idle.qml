import QtQuick
import Quickshell.Wayland

// Idle inhibitor. Left click toggles it; right click picks a duration after
// which it switches itself off.
BarModule {
    id: root

    required property var window

    // -1 off, 0 indefinite, otherwise the minutes picked. Stored rather than
    // derived from `until` so the menu can mark the picked row.
    property int span: -1
    // Epoch ms the inhibit lapses at; 0 while off or indefinite.
    property double until: 0
    // The clock the countdown reads. A binding can't depend on Date.now(), so
    // the tick has to land in a property for the label to follow it.
    property double now: 0

    readonly property bool active: span >= 0

    // "1h23" rather than "1h 23m": the bar is short of width.
    // Not called `left()`: Item's `left` anchor line shadows it and every call
    // throws at runtime.
    function countdown(): string {
        const m = Math.ceil(Math.max(0, root.until - root.now) / 60000);
        return m >= 60 ? `${Math.floor(m / 60)}h${String(m % 60).padStart(2, "0")}` : `${m}m`;
    }

    function set(minutes: int): void {
        // Re-picking the running duration turns it off.
        if (minutes === root.span) {
            root.span = -1;
            root.until = 0;
            return;
        }
        root.span = minutes;
        root.now = Date.now();
        root.until = minutes > 0 ? root.now + minutes * 60000 : 0;
    }

    tone: active ? "sel" : ""
    minWidth: 0
    tooltipText: menu.visible ? "" : !active ? "Idle inhibitor: Inactive\nRight-click to keep awake for a while" : until > 0 ? `Idle inhibitor: ${countdown()} left\nRight-click to change` : "Idle inhibitor: Active\nRight-click to set an expiry"

    onClicked: button => {
        if (button === Qt.RightButton) {
            root.openMenu(menu);
        } else {
            root.set(root.active ? root.span : 0);
        }
    }

    IdleInhibitor {
        window: root.window
        enabled: root.active
    }

    Timer {
        running: root.until > 0
        interval: 1000
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            root.now = Date.now();
            if (root.now >= root.until)
                root.set(-1);
        }
    }

    BarText {
        text: `${root.active ? "󰅶" : "󰾪"}${root.until > 0 ? ` ${root.countdown()}` : ""}`
        color: root.fg
        font.pixelSize: Theme.size + 3
        // The only space here is the one before the countdown.
        font.wordSpacing: Theme.glyphGap
    }

    IdleMenu {
        id: menu

        anchorItem: root
        span: root.span
        remaining: root.until > 0 ? root.countdown() : ""

        onPicked: minutes => {
            root.set(minutes);
            menu.visible = false;
        }
    }
}
