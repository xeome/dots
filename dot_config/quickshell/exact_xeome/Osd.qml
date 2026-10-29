import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// The on-screen display for volume, mic mute, brightness and caps lock. Each
// source is watched (Pipewire signals, Backlight, sysfs inotify), so nothing
// polls and no keybind has to notify it.
PanelWindow {
    id: root

    property string icon: ""
    property real value: 0
    property string label: ""   // replaces the bar when set

    // Each source flashes on a change, never on its first value, so startup
    // stays silent.
    property real lastVolume: -1
    property bool lastMuted: false
    property int lastBrightness: -1
    property int lastCaps: -1

    // The window is this much taller than the Surface, which rests at its top
    // 120 px up: room for the drift up into place as Hyprland fades it in.
    readonly property int drift: 6

    function flash(icon: string, value: real, label: string): void {
        root.icon = icon;
        root.value = value;
        root.label = label;
        root.visible = true;
        hide.restart();
    }

    screen: Quickshell.screens.find(s => s.name === Compositor.focusedMonitor) ?? null
    WlrLayershell.namespace: "quickshell-osd"
    anchors.bottom: true
    margins.bottom: 120 - drift
    implicitWidth: 320
    implicitHeight: 56 + drift
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false

    onVisibleChanged: if (visible)
        enter.restart()

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.visible = false
    }

    // ---- volume ------------------------------------------------------------

    readonly property var sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged(): void {
            root.flashVolume();
        }

        function onMutedChanged(): void {
            root.flashVolume();
        }
    }

    function flashVolume(): void {
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

    // ---- mic mute ----------------------------------------------------------
    //
    // Mute only: XF86AudioMicMute changes it with nothing on screen, and
    // AudioMenu already shows the level.
    //
    // A mic that starts unmuted never emits a first value to seed from, so the
    // first real toggle would be swallowed. Changes count once the node has had
    // 500ms to bind instead.
    readonly property var source: Pipewire.defaultAudioSource
    property bool micReady: false

    onSourceChanged: root.micReady = false

    Timer {
        interval: 500
        // Re-arms when the default source changes.
        running: root.source !== null && !root.micReady
        onTriggered: root.micReady = true
    }

    Connections {
        target: root.source?.audio ?? null

        function onMutedChanged(): void {
            if (!root.micReady)
                return;

            const muted = root.source.audio.muted;
            root.flash(muted ? "󰍭" : "󰍬", 0, muted ? "Mic muted" : "Mic unmuted");
        }
    }

    // ---- brightness --------------------------------------------------------

    // Backlight owns the sysfs watch; this only decides when to flash.
    Connections {
        target: Backlight

        function onRawChanged(): void {
            const changed = root.lastBrightness >= 0 && Backlight.raw !== root.lastBrightness;
            root.lastBrightness = Backlight.raw;
            if (changed && Backlight.available)
                root.flash("󰃠", Backlight.value, "");
        }
    }

    // ---- caps lock ---------------------------------------------------------

    readonly property string capsDir: caps.count > 0 ? caps.get(0, "filePath") : ""

    FolderListModel {
        id: caps

        folder: "file:///sys/class/leds"
        nameFilters: ["*capslock"]
        showFiles: false
        showDotAndDotDot: false
    }

    // ponytail: trusts inotify to see the LED write. If it never fires, bind
    // Caps_Lock to an IpcHandler that reloads this file.
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

    Surface {
        width: parent.width
        height: parent.height - root.drift

        NumberAnimation on y {
            id: enter
            from: root.drift
            to: 0
            duration: Theme.anim
            easing.type: Theme.ease
            running: false
        }

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
                radius: height / 2
                color: Theme.rule

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.value))
                    height: parent.height
                    radius: height / 2
                    color: Theme.text

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
            }
        }
    }
}
