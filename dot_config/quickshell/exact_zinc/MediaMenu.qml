import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

// The media module's menu, hung off it the way AudioMenu hangs off Audio: art,
// a seek bar, transport buttons, and a player picker when more than one thing
// is playing.
//
// The picker is collapsed until pressed and hidden entirely with one player,
// because the common case is a single browser tab and the menu shouldn't open
// three rows deep to say so.
PopupWindow {
    id: root

    required property Item anchorItem
    // Chosen by Media, which owns the selection so the bar label agrees with
    // whatever this menu is showing.
    required property var player

    signal picked(int id)

    // grabFocus dismisses on any outside click — including the click on the
    // module that meant "close". Media reads this so that click doesn't
    // immediately reopen what it just closed.
    property double closedAt: 0

    readonly property var players: Mpris.players.values
    readonly property real length: root.player?.lengthSupported ? root.player.length : 0
    // A stream has no length to seek within, and not every player reports one.
    readonly property bool seekable: root.length > 0 && (root.player?.positionSupported ?? false)

    function mmss(t: real): string {
        const s = Math.max(0, Math.floor(t));
        return `${Math.floor(s / 60)}:${`0${s % 60}`.slice(-2)}`;
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
        // Reopening shouldn't reopen whatever picker was left open.
        list.expanded = false;
    }

    // position doesn't update on its own — players only report it when it jumps
    // — so the bar has to ask. Only while open and only while playing: a paused
    // track's position isn't moving, and a closed menu isn't showing it.
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && (root.player?.isPlaying ?? false)
        onTriggered: root.player.positionChanged()
    }

    component Button: Rectangle {
        id: btn

        property string glyph

        signal activated

        implicitWidth: 34
        implicitHeight: 30
        color: btnMa.containsMouse ? Theme.surfaceHover : "transparent"
        border.width: 1
        border.color: btnMa.containsMouse ? Theme.borderHover : Theme.border
        // `enabled` is inherited by the MouseArea below, so a player that can't
        // skip gets a dead button rather than one that lies.
        opacity: btn.enabled ? 1 : 0.3

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }

        BarText {
            anchors.centerIn: parent
            text: btn.glyph
            font.pixelSize: Theme.size + 3
        }

        MouseArea {
            id: btnMa

            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.activated()
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

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Image {
                    id: art

                    // Collapses rather than reserving a grey hole: plenty of
                    // players publish no art at all.
                    Layout.preferredWidth: art.status === Image.Ready ? 64 : 0
                    Layout.preferredHeight: 64
                    visible: art.status === Image.Ready
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    // Album art is routinely 1000px square and this is 64.
                    sourceSize.width: 128
                    sourceSize.height: 128
                    asynchronous: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    BarText {
                        Layout.fillWidth: true
                        text: root.player?.trackTitle ?? ""
                        font.weight: 650
                        elide: Text.ElideRight
                    }

                    BarText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.player?.trackArtist ?? ""
                        elide: Text.ElideRight
                        font.pixelSize: Theme.size - 2
                        color: Theme.fgDim
                    }

                    BarText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.player?.trackAlbum ?? ""
                        elide: Text.ElideRight
                        font.pixelSize: Theme.size - 3
                        font.weight: 500
                        color: Theme.fgMuted
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 0
                visible: root.seekable

                Track {
                    value: root.length > 0 ? (root.player?.position ?? 0) / root.length : 0
                    // Players that report a position but refuse to take one
                    // still get the bar, as a progress readout.
                    onMoved: fraction => {
                        if (root.player?.canSeek)
                            root.player.position = Math.max(0, Math.min(1, fraction)) * root.length;
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    BarText {
                        Layout.fillWidth: true
                        text: root.mmss(root.player?.position ?? 0)
                        font.pixelSize: Theme.size - 4
                        font.weight: 500
                        color: Theme.fgDim
                    }

                    BarText {
                        text: root.mmss(root.length)
                        font.pixelSize: Theme.size - 4
                        font.weight: 500
                        color: Theme.fgDim
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Button {
                    glyph: "󰒮"
                    enabled: root.player?.canGoPrevious ?? false
                    onActivated: root.player.previous()
                }

                Button {
                    glyph: root.player?.isPlaying ? "󰏤" : "󰐊"
                    enabled: root.player?.canTogglePlaying ?? false
                    onActivated: root.player.togglePlaying()
                }

                Button {
                    glyph: "󰒭"
                    enabled: root.player?.canGoNext ?? false
                    onActivated: root.player.next()
                }
            }

            Rule {
                Layout.topMargin: 2
                visible: list.visible
            }

            ColumnLayout {
                id: list

                property bool expanded: false

                Layout.fillWidth: true
                spacing: 2
                visible: root.players.length > 1

                Pick {
                    label: root.player?.identity ?? ""
                    suffix: list.expanded ? "󰅃" : "󰅀"
                    onClicked: list.expanded = !list.expanded
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: list.expanded

                    Repeater {
                        model: root.players

                        delegate: Pick {
                            required property var modelData

                            label: modelData.identity
                            suffix: modelData.isPlaying ? "󰐊" : ""
                            current: root.player?.uniqueId === modelData.uniqueId
                            onClicked: {
                                root.picked(modelData.uniqueId);
                                list.expanded = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
