import Quickshell.Services.Pipewire

// waybar `privacy`, audio-in half only — screenshare detection was dropped
// because it keys off portal-specific node naming and false-positives on any
// video capture. Inverted (white fill) while something is recording, hidden
// otherwise, same as waybar.
BarModule {
    id: root

    // PwNode.properties is empty unless the node is bound through a
    // PwObjectTracker; `type` and `name` are available on every node for free.
    // Filter-chain based noise suppression (e.g. rnnoise) keeps an internal
    // "capture.*" stream open at all times to feed the filter — that's not
    // someone recording, so it's excluded rather than showing this lit 24/7.
    readonly property var recorders: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream && !n.name.startsWith("capture."))

    visible: recorders.length > 0
    inverted: true
    tooltipText: recorders.map(n => n.description || n.name).join("\n")

    BarText {
        text: "󰍬"
        color: root.fg
    }
}
