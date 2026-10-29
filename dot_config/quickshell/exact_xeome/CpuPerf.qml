pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The CPU's performance ceiling as a percentage of max turbo, for the power
// menu's slider. intel_pstate keeps it in max_perf_pct; other drivers
// (amd-pstate) in every CPU's scaling_max_freq, in kHz of cpuinfo_max_freq.
//
// The only writer of the cap: the TLP drop-in leaves CPU_MAX_PERF_* and
// CPU_SCALING_MAX_FREQ_* unset, so boot starts at 100. The tmpfiles lines in
// infra/files/power/dots-cpu-perf.conf give wheel write access, so a shell
// redirect writes it.
//
// ponytail: reads cpu0 for every core; a CPU with per-core max frequencies
// would show cpu0's cap only.
Singleton {
    id: root

    readonly property string cpufreq: "/sys/devices/system/cpu/cpu0/cpufreq"
    // Empty until scaling_driver is read, which keeps every path below empty
    // too: reading cpu0's kHz as an intel percentage would show 5000000%.
    property string driver: ""
    // intel_cpufreq is intel_pstate in passive mode, max_perf_pct and all.
    readonly property bool intel: root.driver.startsWith("intel_")
    readonly property string path: root.driver === "" ? "" : root.intel ? "/sys/devices/system/cpu/intel_pstate/max_perf_pct" : `${root.cpufreq}/scaling_max_freq`
    // Every file `path` stands for, as one shell glob.
    readonly property string targets: root.intel ? root.path : "/sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq"
    // 100% in the file's own unit.
    property int full: 0
    property int pct: 0
    // The lowest percentage worth offering. On intel that is min_perf_pct,
    // which the kernel clamps the cap to anyway. On amd-pstate it is
    // lowest_nonlinear_freq: below it the CPU loses speed faster than it saves
    // power. Flooring the slider also keeps it off 0, which would read as
    // unavailable and hide it mid-drag.
    property int floor: 1
    readonly property bool available: root.pct > 0
    // The slider's position: floor at the left end, 100 at the right, so the
    // whole track is reachable and nothing below the floor is drawn.
    readonly property real fraction: (root.pct - root.floor) / (100 - root.floor)

    function set(fraction: real): void {
        if (!root.available)
            return;

        root.pct = root.floor + Math.round(Math.max(0, Math.min(1, fraction)) * (100 - root.floor));
        debounce.restart();
    }

    FileView {
        path: `${root.cpufreq}/scaling_driver`
        onLoaded: {
            root.driver = text().trim();
            if (root.intel)
                root.full = 100;
        }
    }

    FileView {
        path: root.driver === "" || root.intel ? "" : `${root.cpufreq}/cpuinfo_max_freq`
        onLoaded: root.full = parseInt(text()) || 0
    }

    FileView {
        path: root.full === 0 ? "" : root.intel ? "/sys/devices/system/cpu/intel_pstate/min_perf_pct" : `${root.cpufreq}/amd_pstate_lowest_nonlinear_freq`
        onLoaded: root.floor = Math.max(1, Math.ceil((parseInt(text()) || 0) * 100 / root.full))
    }

    FileView {
        id: reader

        path: root.full === 0 ? "" : root.path
        watchChanges: true
        onFileChanged: reload()
        // Skipped while a write is pending, as in Backlight.
        onLoaded: if (!debounce.running)
            root.pct = Math.round((parseInt(text()) || 0) * 100 / root.full)
    }

    Timer {
        id: debounce

        interval: 40
        onTriggered: {
            const value = root.intel ? root.pct : Math.round(root.pct * root.full / 100);
            // $2 is left unquoted on purpose: it is the glob.
            setter.command = ["sh", "-c", "for f in $2; do echo \"$1\" > \"$f\"; done", "sh", `${value}`, root.targets];
            setter.running = true;
        }
    }

    Process {
        id: setter

        // A refused write raises no inotify event.
        onExited: reader.reload()
    }
}
