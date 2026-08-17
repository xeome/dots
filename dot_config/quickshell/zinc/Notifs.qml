pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Replaces swaync's daemon. swaync must not be running — both want to own
// org.freedesktop.Notifications and whoever grabs it first wins.
Singleton {
    id: root

    property bool dnd: false
    property var popups: []

    // Bells listen for this; the one on the focused monitor opens.
    signal toggleCentre

    // Newest first, which is the order both the stack and the list want.
    readonly property var history: [...server.trackedNotifications.values].reverse()

    // Arrival times, which the Notification object doesn't carry. Keyed by id
    // rather than by object so a dismissed card can't keep one alive.
    //
    // ponytail: dropped on reload — keepOnReload keeps the notifications but
    // not this, so anything that survived a reload shows no age at all.
    readonly property var stamps: new Map()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Reads clock.date, so every label bound to this re-evaluates on the tick
    // rather than freezing at whatever it said when the centre opened.
    function age(n): string {
        const at = root.stamps.get(n.id);
        if (at === undefined)
            return "";

        const mins = Math.floor((clock.date.getTime() - at) / 60000);
        if (mins < 1)
            return "now";
        if (mins < 60)
            return `${mins}m`;
        if (mins < 1440)
            return `${Math.floor(mins / 60)}h`;
        return `${Math.floor(mins / 1440)}d`;
    }

    // The sending app's hint wins. Spec: a positive timeout is a request in
    // seconds, 0 means never expire, and -1 hands the decision back to us —
    // which is where swaync's 5s low / 10s normal / never-for-critical come in.
    function timeout(n): int {
        if (n.expireTimeout >= 0)
            return n.expireTimeout * 1000;
        if (n.urgency === NotificationUrgency.Critical)
            return 0;
        return n.urgency === NotificationUrgency.Low ? 5000 : 10000;
    }

    function drop(n): void {
        root.popups = root.popups.filter(p => p !== n);
    }

    function clearAll(): void {
        for (const n of root.history)
            n.dismiss();
        root.popups = [];
        root.stamps.clear();
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            // Stamped before tracking, so the card that tracking creates can
            // already read its own age.
            root.stamps.set(n.id, Date.now());
            n.tracked = true;
            if (!root.dnd)
                root.popups = [n, ...root.popups];
        }
    }

    // Replaces `swaync-client -t` / `-d`.
    IpcHandler {
        target: "notifs"

        function toggle(): void {
            root.toggleCentre();
        }

        function dnd(): bool {
            root.dnd = !root.dnd;
            return root.dnd;
        }

        function clear(): void {
            root.clearAll();
        }
    }
}
