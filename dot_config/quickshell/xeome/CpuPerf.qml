pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// intel_pstate's max_perf_pct: the CPU's ceiling as a percentage of max turbo,
// across every core. The power menu's slider for keeping the laptop quiet —
// lower ceiling, less heat, slower fan.
//
// This is the cap's only writer. tlp.conf leaves CPU_MAX_PERF_* unset, so a
// profile click or a resume never moves it, and boot starts at the kernel's
// 100. The file is root-owned; the tmpfiles line from configure-power gives
// wheel write on it, so the write is a plain shell redirect.
//
// ponytail: intel_pstate only — on any other driver the file is missing,
// `available` stays false and the slider hides itself.
Singleton {
    id: root

    readonly property string path: "/sys/devices/system/cpu/intel_pstate/max_perf_pct"
    property int pct: 0
    // min_perf_pct, which the kernel clamps the cap to anyway. Flooring the
    // slider there means it never shows a value the kernel would refuse, and
    // never reaches 0, which would read as unavailable and hide it mid-drag.
    property int floor: 1
    readonly property bool available: root.pct > 0

    function set(fraction: real): void {
        if (!root.available)
            return;

        root.pct = Math.max(root.floor, Math.round(Math.min(1, fraction) * 100));
        debounce.restart();
    }

    FileView {
        path: "/sys/devices/system/cpu/intel_pstate/min_perf_pct"
        onLoaded: root.floor = Math.max(1, parseInt(text()) || 0)
    }

    FileView {
        id: reader

        path: root.path
        watchChanges: true
        onFileChanged: reload()
        // Skipped while a write is pending: the reload that follows the
        // previous write would otherwise overwrite the newer drag, and the
        // pending write would then send the stale value.
        onLoaded: if (!debounce.running)
            root.pct = parseInt(text()) || 0
    }

    Timer {
        id: debounce

        interval: 40
        onTriggered: {
            setter.command = ["sh", "-c", "echo \"$1\" > \"$2\"", "sh", `${root.pct}`, root.path];
            setter.running = true;
        }
    }

    Process {
        id: setter

        // A refused write raises no inotify event, so without this the slider
        // would keep showing a value the kernel never took.
        onExited: reader.reload()
    }
}
