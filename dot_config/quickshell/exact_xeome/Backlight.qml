pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// The laptop panel's backlight, read off sysfs through an inotify watch, so
// nothing polls. Writes shell out to brightnessctl, whose udev rule lets the
// video group write the root-owned files. One singleton feeds Power on every
// monitor and the OSD.
//
// ponytail: laptop panels only; without a backlight class `available` stays
// false and consumers hide. External monitors need ddcutil (~300ms per call,
// writes monitor NVRAM).
Singleton {
    id: root

    property int max: 0
    property int raw: 0

    readonly property string device: devices.count > 0 ? devices.get(0, "fileName") : ""
    readonly property bool available: root.max > 0
    readonly property real value: root.max > 0 ? root.raw / root.max : 0

    function set(fraction: real): void {
        if (root.max <= 0)
            return;

        // Never fully off: a black panel hides the slider that turned it off.
        root.raw = Math.max(1, Math.round(Math.max(0, Math.min(1, fraction)) * root.max));
        debounce.restart();
    }

    FolderListModel {
        id: devices

        folder: "file:///sys/class/backlight"
        showFiles: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    FileView {
        path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text()) || 0
    }

    FileView {
        id: reader

        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        watchChanges: true
        onFileChanged: reload()
        // Corrects the optimistic value set by a drag. Skipped while a write
        // is pending, or the previous write's event would overwrite the newer
        // drag and the pending write would send the stale value.
        onLoaded: if (!debounce.running)
            root.raw = parseInt(text()) || 0
    }

    // A drag moves once per pixel; only the last move needs a process.
    Timer {
        id: debounce

        interval: 40
        onTriggered: {
            setter.command = ["brightnessctl", "-d", root.device, "set", `${root.raw}`];
            setter.running = true;
        }
    }

    Process {
        id: setter

        // A refused write raises no inotify event, so without this the slider
        // would keep showing a value the panel never took.
        onExited: reader.reload()
    }
}
