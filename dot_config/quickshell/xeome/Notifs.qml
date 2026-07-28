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

    // swaync's timeouts: 5s low, 10s normal, critical never expires.
    function timeout(n): int {
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
