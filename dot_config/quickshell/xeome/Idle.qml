import QtQuick
import Quickshell.Wayland

// waybar `idle_inhibitor`, plus an expiry waybar didn't have.
//
// Left-click is still the plain toggle. Right-click picks a duration, after
// which this switches itself back off — the thing you turn on for a film and
// find still on two days later.
BarModule {
    id: root

    required property var window

    // -1 off, 0 indefinite, otherwise the minutes originally asked for. Kept
    // rather than derived from `until` so the menu can tick the row you picked
    // instead of guessing it back out of a deadline.
    property int span: -1
    // Epoch ms the inhibit lapses at; 0 while off or indefinite.
    property double until: 0
    // The clock the countdown reads. A binding can't depend on Date.now(), so
    // the tick has to land in a property for the label to follow it.
    property double now: 0

    readonly property bool active: span >= 0

    // Compact on purpose: this sits in a bar that already fights the window
    // title for width, and "1h23" is legible at a glance where "1h 23m" costs
    // another 30px. The tooltip spells it out.
    //
    // Not called `left()`: Item already has a `left` anchor line, and the
    // property wins silently — every call site throws at runtime while the
    // label just renders without its countdown.
    function countdown(): string {
        const m = Math.ceil(Math.max(0, root.until - root.now) / 60000);
        return m >= 60 ? `${Math.floor(m / 60)}h${String(m % 60).padStart(2, "0")}` : `${m}m`;
    }

    function set(minutes: int): void {
        // Re-picking what's already running means "stop" — the same gesture as
        // clicking a connected bluetooth device in AudioMenu.
        if (minutes === root.span) {
            root.span = -1;
            root.until = 0;
            return;
        }
        root.span = minutes;
        root.now = Date.now();
        root.until = minutes > 0 ? root.now + minutes * 60000 : 0;
    }

    tone: active ? "toggle" : ""
    minWidth: 0
    tooltipText: menu.visible ? "" : !active ? "Idle inhibitor: Inactive\nRight-click to keep awake for a while" : until > 0 ? `Idle inhibitor: ${countdown()} left\nRight-click to change` : "Idle inhibitor: Active\nRight-click to set an expiry"

    onClicked: button => {
        if (button === Qt.RightButton) {
            if (!menu.visible && Date.now() - menu.closedAt > 200)
                menu.visible = true;
        } else {
            root.set(root.active ? root.span : 0);
        }
    }

    IdleInhibitor {
        window: root.window
        enabled: root.active
    }

    // Only runs while something is actually counting down — an idle inhibitor
    // that wakes the CPU every second to do nothing would be its own joke.
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
        font.pixelSize: Theme.size + 3   // waybar: font-size 1.25em
    }

    // A PopupWindow isn't an Item, so the RowLayout that BarModule's default
    // property points at stores it without trying to lay it out.
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
