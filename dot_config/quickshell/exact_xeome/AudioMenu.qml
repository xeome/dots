import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

// Audio's menu: default sink and source, each with a mute toggle, a volume bar
// and a collapsed device picker, then Bluetooth headsets and the apps holding
// the mic. Per-app volume is pavucontrol's, on the module's right click.
Menu {
    id: root

    // Recording streams, filtered by Audio.
    required property var recorders

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // Real devices, not streams: the type is a flag set, so AudioDuplex nodes
    // (a loopback, a virtual cable) match both lists rather than neither.
    readonly property var sinks: Pipewire.nodes.values.filter(n => !n.isStream && (n.type & PwNodeType.AudioSink) === PwNodeType.AudioSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isStream && (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource)

    readonly property var adapter: Bluetooth.defaultAdapter
    // Paired audio devices, connected first. Bluez classifies by icon
    // ("audio-headset", "audio-card"); pairing new ones is blueman's job.
    readonly property var headsets: root.adapter ? Bluetooth.devices.values.filter(d => d.paired && d.icon.startsWith("audio")).sort((a, b) => b.connected - a.connected) : []

    function btLabel(d: var): string {
        return d.deviceName || d.name || d.address;
    }

    function btDetail(d: var): string {
        if (d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting)
            return "···";
        if (d.connected && d.batteryAvailable)
            return `󰥉 ${Math.round(d.battery * 100)}%`;
        return d.connected ? "connected" : "";
    }

    // application.name is what pavucontrol shows; not every stream sets it.
    function appName(n: var): string {
        return n.properties["application.name"] || n.description || n.name;
    }

    // Reopening shouldn't reopen a picker left open.
    onVisibleChanged: if (!visible) {
        out.expanded = false;
        mic.expanded = false;
    }

    // Volume, mute and `properties` (the recorders' app names) stay empty until
    // a node is bound. The picker rows need only `description`, which is free.
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.recorders)
    }

    // One output or input: the glyph mutes, the bar sets volume, the picker
    // switches device.
    component Device: ColumnLayout {
        id: dev

        required property var node
        required property string glyph
        required property string label
        required property var devices
        signal picked(var node)

        readonly property var audio: dev.node?.audio ?? null
        readonly property bool muted: dev.audio?.muted ?? false
        readonly property real volume: dev.audio?.volume ?? 0
        readonly property bool selectable: dev.devices.length > 1
        property bool expanded: false

        Layout.fillWidth: true
        spacing: 2
        visible: !!dev.node

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            BarText {
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
                text: dev.glyph
                font.pixelSize: Theme.size + 5
                color: dev.muted ? Theme.dim : Theme.text

                MouseArea {
                    anchors.fill: parent
                    onClicked: if (dev.audio)
                        dev.audio.muted = !dev.muted
                }
            }

            BarText {
                Layout.fillWidth: true
                text: dev.label
                color: dev.muted ? Theme.dim : Theme.text
            }

            BarText {
                text: dev.muted ? "muted" : `${Math.round(dev.volume * 100)}%`
                color: dev.muted ? Theme.dim : Theme.text
            }
        }

        Track {
            value: dev.muted ? 0 : dev.volume
            // Touching the bar un-mutes, so a drag is always heard.
            onMoved: fraction => {
                if (!dev.audio)
                    return;
                dev.audio.muted = false;
                dev.audio.volume = fraction;
            }
        }

        Pick {
            Layout.topMargin: 4
            label: dev.node?.description ?? ""
            suffix: dev.selectable ? (dev.expanded ? "󰅃" : "󰅀") : ""
            selectable: dev.selectable
            onClicked: dev.expanded = !dev.expanded
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: dev.expanded

            Repeater {
                model: dev.devices

                delegate: Pick {
                    required property var modelData

                    label: modelData.description || modelData.name
                    // By id: the default node need not be the same wrapper object.
                    current: dev.node?.id === modelData.id
                    onClicked: {
                        dev.picked(modelData);
                        dev.expanded = false;
                    }
                }
            }
        }
    }

    Device {
        id: out

        node: root.sink
        label: "Output"
        devices: root.sinks
        glyph: out.muted ? "󰖁" : out.volume > 0.66 ? "󰕾" : out.volume > 0.33 ? "󰖀" : "󰕿"
        // Preferred, not default: pipewire remembers it and falls back
        // from it when the device disappears.
        onPicked: node => Pipewire.preferredDefaultAudioSink = node
    }

    Rule {}

    Device {
        id: mic

        node: root.source
        label: "Input"
        devices: root.sources
        glyph: mic.muted ? "󰍭" : "󰍬"
        onPicked: node => Pipewire.preferredDefaultAudioSource = node
    }

    Rule {
        visible: bt.visible
    }

    // The shell's only Bluetooth switch, so it shows even with nothing
    // paired.
    ColumnLayout {
        id: bt

        Layout.fillWidth: true
        spacing: 2
        visible: !!root.adapter

        Pick {
            label: "Bluetooth"
            suffix: root.adapter?.enabled ? "on" : "off"
            current: root.adapter?.enabled ?? false
            onClicked: root.adapter.enabled = !root.adapter.enabled
        }

        Repeater {
            model: root.headsets

            delegate: Pick {
                required property var modelData

                label: root.btLabel(modelData)
                suffix: root.btDetail(modelData)
                current: modelData.connected
                // A connected headset shows up in the Output picker.
                onClicked: if (modelData.connected)
                    modelData.disconnect();
                else
                    modelData.connect()
            }
        }
    }

    Rule {}

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        BarText {
            text: root.recorders.length > 0 ? "󰍬  Mic in use by" : "󰍭  Mic not in use"
            font.pixelSize: Theme.size - 2
            color: root.recorders.length > 0 ? Theme.text : Theme.dim
        }

        Repeater {
            model: root.recorders

            delegate: BarText {
                required property var modelData

                Layout.fillWidth: true
                Layout.leftMargin: 22
                text: root.appName(modelData)
                elide: Text.ElideRight
                font.pixelSize: Theme.size - 3
                color: Theme.dim
            }
        }
    }
}
