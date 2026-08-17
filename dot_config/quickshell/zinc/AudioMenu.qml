import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

// The audio module's menu, hung off it the way Power hangs off Battery:
// default sink and source, each with a mute toggle, a drag/scroll bar and a
// device picker, plus the list of whoever is holding the mic open.
//
// The picker is collapsed until the device button is pressed, because the
// common case is "set the volume" and a machine with three sinks would
// otherwise open six rows deep. Per-app volume still isn't here — right-clicking
// the module lands in pavucontrol, which already does it.
PopupWindow {
    id: root

    required property Item anchorItem
    // Recording streams, filtered by Audio — one definition, two consumers.
    required property var recorders

    // grabFocus dismisses on any outside click — including the click on the
    // module that meant "close". Audio reads this so that click doesn't
    // immediately reopen what it just closed.
    property double closedAt: 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // Real devices, not streams: the type is a flag set, so AudioDuplex nodes
    // (a loopback, a virtual cable) match both lists rather than neither.
    readonly property var sinks: Pipewire.nodes.values.filter(n => !n.isStream && (n.type & PwNodeType.AudioSink) === PwNodeType.AudioSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isStream && (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource)

    readonly property var adapter: Bluetooth.defaultAdapter
    // Paired audio devices only. Bluez classifies by icon — "audio-headset",
    // "audio-card" — which is what keeps the mouse out of the audio menu, and
    // the mouse battery out of the bar where it used to sit reading 100% at
    // nobody. Unpaired devices need a scan and a pairing flow that live in
    // blueman; this list is the ones you already own.
    readonly property var headsets: (root.adapter ? Bluetooth.devices.values.filter(d => d.paired && d.icon.startsWith("audio")) : []).slice().sort((a, b) => b.connected - a.connected)

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

    function clamp(v: real): real {
        return Math.max(0, Math.min(1, v));
    }

    // application.name is what pavucontrol shows ("Firefox", "OBS Studio");
    // the node description is a fallback for streams that don't set it.
    function appName(n: var): string {
        return n.properties["application.name"] || n.description || n.name;
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: 324
    implicitHeight: body.implicitHeight + 24
    color: "transparent"
    visible: false
    grabFocus: true

    onVisibleChanged: {
        if (root.visible)
            return;

        root.closedAt = Date.now();
        // Reopening the menu shouldn't reopen whatever picker was left open.
        out.expanded = false;
        mic.expanded = false;
    }

    // Volume and muted are unreadable until the node is bound, and
    // `properties` — where the recorder app names live — stays empty without
    // this. The picker rows need only `description`, which every node carries.
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.recorders)
    }

    // Output and input are the same widgets, so they're one component: click
    // the glyph to mute, drag or scroll the bar to set volume, press the device
    // button to switch to another one.
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
                color: dev.muted ? Theme.fgMuted : Theme.fg

                MouseArea {
                    anchors.fill: parent
                    onClicked: if (dev.audio)
                        dev.audio.muted = !dev.muted
                }
            }

            BarText {
                Layout.fillWidth: true
                text: dev.label
                color: dev.muted ? Theme.fgMuted : Theme.fg
            }

            BarText {
                text: dev.muted ? "muted" : `${Math.round(dev.volume * 100)}%`
                font.weight: 500
                color: dev.muted ? Theme.fgMuted : Theme.fg
            }
        }

        Track {
            value: dev.muted ? 0 : dev.volume
            // Touching the bar un-mutes: dragging a dead slider and hearing
            // nothing is the worse surprise.
            onMoved: fraction => {
                if (!dev.audio)
                    return;
                dev.audio.muted = false;
                dev.audio.volume = root.clamp(fraction);
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
                    // By id, not by identity: the default is a separate lookup
                    // from the node list and doesn't have to be the same wrapper.
                    current: dev.node?.id === modelData.id
                    onClicked: {
                        dev.picked(modelData);
                        dev.expanded = false;
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.panel
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            id: body

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 8

            Device {
                id: out

                node: root.sink
                label: "Output"
                devices: root.sinks
                glyph: out.muted ? "󰖁" : out.volume > 0.66 ? "󰕾" : out.volume > 0.33 ? "󰖀" : "󰕿"
                // Preferred, not default: this is the one pipewire remembers and
                // falls back from when the device disappears.
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

            // Bluetooth lives here rather than in a module of its own: it is an
            // audio device menu 99% of the time, and a second bar button for it
            // meant two clicks and a mouse battery nobody asked for. The toggle
            // is the only switch left now that the module is gone, so it stays
            // even when nothing is paired.
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
                        // Connecting a headset makes it a pipewire node, so the
                        // Output picker above grows the entry on its own — no
                        // sink switching duplicated down here.
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
                    color: root.recorders.length > 0 ? Theme.fg : Theme.fgDim
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
                        font.weight: 500
                        color: Theme.fgDim
                    }
                }
            }
        }
    }
}
