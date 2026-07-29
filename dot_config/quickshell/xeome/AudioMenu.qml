import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// The audio module's menu, hung off it the way Power hangs off Battery:
// default sink and source, each with a mute toggle and a drag/scroll bar, and
// the list of whoever is holding the mic open.
//
// Device *switching* isn't here — it needs a node list, per-node trackers and
// a scroll area, and right-clicking the module lands in pavucontrol which
// already does it.
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

    onVisibleChanged: if (!visible)
        closedAt = Date.now();

    // Volume and muted are unreadable until the node is bound, and
    // `properties` — where the recorder app names live — stays empty without
    // this.
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.recorders)
    }

    component Rule: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.border
    }

    // Output and input are the same three widgets, so they're one component:
    // click the glyph to mute, drag or scroll the bar to set volume.
    component Device: ColumnLayout {
        id: dev

        required property var node
        required property string glyph
        required property string label

        readonly property var audio: dev.node?.audio ?? null
        readonly property bool muted: dev.audio?.muted ?? false
        readonly property real volume: dev.audio?.volume ?? 0

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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                BarText {
                    text: dev.label
                    color: dev.muted ? Theme.fgMuted : Theme.fg
                }

                BarText {
                    Layout.fillWidth: true
                    text: dev.node?.description ?? ""
                    elide: Text.ElideRight
                    font.pixelSize: Theme.size - 4
                    font.weight: 450
                    color: Theme.fgMuted
                }
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
                glyph: out.muted ? "󰖁" : out.volume > 0.66 ? "󰕾" : out.volume > 0.33 ? "󰖀" : "󰕿"
            }

            Rule {}

            Device {
                id: mic

                node: root.source
                label: "Input"
                glyph: mic.muted ? "󰍭" : "󰍬"
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
