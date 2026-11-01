import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Output volume, plus a warm mic glyph while something records. Left click
// opens AudioMenu; right click opens pavucontrol for the per-app volume the
// menu does not do.
BarModule {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: sink?.audio?.muted ?? false

    // The node name, not `device.api`: `properties` is only filled for nodes
    // bound through a tracker, and bluez5 names every sink
    // `bluez_output.<mac>.<profile>`.
    readonly property bool overBluetooth: sink?.name.startsWith("bluez_output.") ?? false

    // A noise-suppression filter chain (rnnoise) holds a `capture.*` stream
    // open permanently; that is not someone recording.
    readonly property var recorders: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream && !n.name.startsWith("capture."))

    tooltipText: menu.visible ? "" : [`Volume: ${volume}%`].concat(recorders.map(n => `󰍬 ${n.description || n.name}`)).join("\n")

    onClicked: button => {
        if (button === Qt.RightButton)
            Quickshell.execDetached(["pavucontrol"]);
        else
            root.openMenu(menu);
    }

    // Volume/muted are unreadable until the node is bound.
    PwObjectTracker {
        objects: [root.sink]
    }

    BarText {
        visible: root.recorders.length > 0
        text: "󰍬"
        color: Theme.warm
        font.pixelSize: Theme.size + 1
    }

    BarText {
        // Over bluetooth the headset glyph replaces the volume ramp; the bar
        // has no width for both.
        text: root.muted ? "󰖁" : `${root.overBluetooth ? "󰂰" : root.volume > 66 ? "󰕾" : root.volume > 33 ? "󰖀" : "󰕿"} ${root.volume}%`
        color: root.muted ? Theme.dim : root.fg
        // md-volume_medium/_low are drawn smaller than neighboring glyphs
        // (bell, mic) at the same pixel size.
        font.pixelSize: Theme.size + 1
        // Every space in this label separates a glyph from a value.
        font.wordSpacing: Theme.glyphGap
    }

    AudioMenu {
        id: menu
        anchorItem: root
        recorders: root.recorders
    }
}
