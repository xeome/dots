import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// waybar `pulseaudio`.
BarModule {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: sink?.audio?.muted ?? false

    tooltipText: `Volume: ${volume}%\nClick to open mixer`
    onClicked: Quickshell.execDetached(["pavucontrol"])

    // Volume/muted are unreadable until the node is bound.
    PwObjectTracker {
        objects: [root.sink]
    }

    BarText {
        text: root.muted ? "󰖁" : `${root.volume > 66 ? "󰕾" : root.volume > 33 ? "󰖀" : "󰕿"} ${root.volume}%`
        color: root.muted ? Qt.rgba(1, 1, 1, 0.3) : Theme.fg
        // md-volume_medium/_low are drawn smaller than neighboring glyphs
        // (bell, mic) at the same pixel size.
        font.pixelSize: Theme.size + 1
    }
}
