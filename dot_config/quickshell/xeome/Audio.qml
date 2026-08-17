import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// waybar `pulseaudio` plus the audio-in half of `privacy`, merged into one
// module — the recording indicator was its own box until it grew a menu worth
// sharing. Carries the toggle fill while something holds the mic: that's a
// switch someone flipped, not something asking you to act, so it shares a tone
// with DND and the idle inhibitor rather than with the low-battery warning.
//
// Left-click opens AudioMenu; right-click still goes to pavucontrol, which is
// the escape hatch for per-app volume the menu deliberately doesn't do.
BarModule {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: sink?.audio?.muted ?? false

    // Read off the node name rather than `device.api`, which would be the more
    // precise test but lives in `properties` and so only exists for nodes bound
    // through a tracker. pipewire's bluez5 module names every sink it creates
    // `bluez_output.<mac>.<profile>`, and the name is free on any node.
    readonly property bool overBluetooth: sink?.name.startsWith("bluez_output.") ?? false

    // PwNode.properties is empty unless the node is bound through a
    // PwObjectTracker; `type` and `name` are available on every node for free.
    // Filter-chain based noise suppression (e.g. rnnoise) keeps an internal
    // "capture.*" stream open at all times to feed the filter — that's not
    // someone recording, so it's excluded rather than showing this lit 24/7.
    readonly property var recorders: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream && !n.name.startsWith("capture."))

    tone: recorders.length > 0 ? "toggle" : ""
    // Suppressed while the menu is open: both anchor below this module, so
    // otherwise they stack on top of each other.
    tooltipText: menu.visible ? "" : [`Volume: ${volume}%`].concat(recorders.map(n => `󰍬 ${n.description || n.name}`)).join("\n")

    onClicked: button => {
        if (button === Qt.RightButton)
            Quickshell.execDetached(["pavucontrol"]);
        else if (!menu.visible && Date.now() - menu.closedAt > 200)
            menu.visible = true;
    }

    // Volume/muted are unreadable until the node is bound.
    PwObjectTracker {
        objects: [root.sink]
    }

    BarText {
        // Over bluetooth the headset glyph replaces the volume ramp rather than
        // riding alongside it — which speaker you're on is worth more than which
        // third of the range you're in, and the bar has no width for both.
        text: `${root.recorders.length > 0 ? "󰍬 " : ""}${root.muted ? "󰖁" : `${root.overBluetooth ? "󰂰" : root.volume > 66 ? "󰕾" : root.volume > 33 ? "󰖀" : "󰕿"} ${root.volume}%`}`
        color: root.muted && root.tone === "" ? Theme.fgMuted : root.fg
        // md-volume_medium/_low are drawn smaller than neighboring glyphs
        // (bell, mic) at the same pixel size.
        font.pixelSize: Theme.size + 1
        // Every space in this label separates a glyph from a value.
        font.wordSpacing: Theme.glyphGap
    }

    // A PopupWindow isn't an Item, so the RowLayout that BarModule's default
    // property points at stores it without trying to lay it out.
    AudioMenu {
        id: menu
        anchorItem: root
        recorders: root.recorders
    }
}
