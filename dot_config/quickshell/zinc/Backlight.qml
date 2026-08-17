pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// The laptop panel's backlight, straight off sysfs: FolderListModel finds the
// device and FileView's inotify watch reports every change, so discovery and
// reads cost no processes and nothing polls. The only thing that shells out is
// a write, because /sys/class/backlight is root-owned and brightnessctl ships
// the udev rule that lets the video group past that.
//
// A singleton because Power exists once per monitor and Osd once per shell —
// one watch feeding all of them, and the OSD flashes for the menu slider and
// the XF86 keys through the same path.
//
// ponytail: laptop panels only — a desktop has no backlight class, `available`
// stays false and the consumers hide themselves. External monitors would need
// ddcutil, a second backend that costs ~300ms per call and writes monitor NVRAM.
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

        // Never all the way off: a black panel hides the slider that turned it
        // off. brightnessctl's own `set 0%` has the same floor.
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
        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        watchChanges: true
        onFileChanged: reload()
        // Also how the optimistic value set by dragging gets corrected, if the
        // driver rounds it or refuses it.
        onLoaded: root.raw = parseInt(text()) || 0
    }

    // A drag emits a move per pixel and only the last one matters; without this
    // it would be a process per pixel.
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
    }
}
