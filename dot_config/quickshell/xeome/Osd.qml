import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// Replaces swayosd, restyled from its black pill into the bar's square mono
// chrome. Volume comes from Pipewire's own signals and brightness/caps-lock
// from sysfs inotify — verified to fire on this machine — so nothing polls and
// no keybind has to tell the OSD that something changed.
PanelWindow {
    id: root

    property string icon: ""
    property real value: 0
    property string label: ""   // shown instead of the bar, for caps lock

    // Every source flashes on *change*, never on the first value it sees, so
    // startup reads stay silent without a timer racing device discovery.
    property real lastVolume: -1
    property bool lastMuted: false
    property int lastBrightness: -1
    property int lastCaps: -1

    function flash(icon: string, value: real, label: string): void {
        root.icon = icon;
        root.value = value;
        root.label = label;
        root.visible = true;
        hide.restart();
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    WlrLayershell.namespace: "quickshell-osd"
    anchors.bottom: true
    margins.bottom: 120
    implicitWidth: 320
    implicitHeight: 56
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.visible = false
    }

    // ---- volume ------------------------------------------------------------

    readonly property var sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: [root.sink]
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged(): void {
            root.onAudioChanged();
        }

        function onMutedChanged(): void {
            root.onAudioChanged();
        }
    }

    function onAudioChanged(): void {
        const a = root.sink?.audio;
        if (!a)
            return;

        const changed = root.lastVolume >= 0 && (Math.abs(a.volume - root.lastVolume) > 0.001 || a.muted !== root.lastMuted);
        root.lastVolume = a.volume;
        root.lastMuted = a.muted;
        if (!changed)
            return;

        const pct = Math.round(a.volume * 100);
        root.flash(a.muted ? "󰖁" : pct > 66 ? "󰕾" : pct > 33 ? "󰖀" : "󰕿", a.muted ? 0 : a.volume, "");
    }

    // ---- brightness --------------------------------------------------------

    property string backlight: ""
    property int briMax: 0

    Process {
        running: true
        command: ["sh", "-c", "ls -1 /sys/class/backlight | head -n1"]

        stdout: StdioCollector {
            onStreamFinished: {
                const dev = text.trim();
                if (dev)
                    root.backlight = "/sys/class/backlight/" + dev;
            }
        }
    }

    FileView {
        path: root.backlight ? root.backlight + "/max_brightness" : ""
        onLoaded: root.briMax = parseInt(text()) || 0
    }

    FileView {
        path: root.backlight ? root.backlight + "/brightness" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = parseInt(text()) || 0;
            const changed = root.lastBrightness >= 0 && v !== root.lastBrightness;
            root.lastBrightness = v;
            if (changed && root.briMax > 0)
                root.flash("󰃠", v / root.briMax, "");
        }
    }

    // ---- caps lock ---------------------------------------------------------

    property string capsDir: ""

    Process {
        running: true
        command: ["sh", "-c", "ls -1d /sys/class/leds/*capslock 2>/dev/null | head -n1"]

        stdout: StdioCollector {
            onStreamFinished: root.capsDir = text.trim()
        }
    }

    // ponytail: if this never fires, the LED is written by a path inotify
    // doesn't cover — fall back to binding Caps_Lock to an IpcHandler that
    // reloads this file, the way swayosd-client did.
    FileView {
        path: root.capsDir ? root.capsDir + "/brightness" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const on = parseInt(text()) > 0 ? 1 : 0;
            const changed = root.lastCaps >= 0 && on !== root.lastCaps;
            root.lastCaps = on;
            if (changed)
                root.flash("⇪", 0, on ? "Caps Lock On" : "Caps Lock Off");
        }
    }

    // ---- chrome ------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: Theme.bar
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            BarText {
                text: root.icon
                font.pixelSize: 22
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                visible: root.label === ""
                color: Qt.rgba(1, 1, 1, 0.15)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.value))
                    height: parent.height
                    color: Theme.fg

                    Behavior on width {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                }
            }

            BarText {
                Layout.fillWidth: true
                visible: root.label !== ""
                text: root.label
            }

            BarText {
                visible: root.label === ""
                text: `${Math.round(root.value * 100)}%`
                font.weight: 500
            }
        }
    }
}
