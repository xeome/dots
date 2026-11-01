import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

// Media's menu: art, a seek bar, transport buttons, and a collapsed player
// picker that only appears with more than one player.
Menu {
    id: root

    // Chosen by Media, so the bar label and this menu show the same player.
    required property var player

    signal picked(int id)

    readonly property var players: Mpris.players.values
    readonly property real length: root.player?.lengthSupported ? root.player.length : 0
    // A stream has no length to seek within, and not every player reports one.
    readonly property bool seekable: root.length > 0 && (root.player?.positionSupported ?? false)

    function mmss(t: real): string {
        const s = Math.max(0, Math.floor(t));
        return `${Math.floor(s / 60)}:${`0${s % 60}`.slice(-2)}`;
    }

    // Reopening shouldn't reopen a picker left open.
    onVisibleChanged: if (!visible)
        list.expanded = false

    // Players only report position when it jumps, so ask once a second while
    // it is both moving and on screen.
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
        radius: Theme.radius
        color: btnMa.containsMouse ? Theme.hover : "transparent"
        border.width: 1
        border.color: Theme.line
        // The MouseArea inherits `enabled`, so a disabled button is dead too.
        opacity: btn.enabled ? 1 : 0.3

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
                easing.type: Theme.ease
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

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Image {
            id: art

            Layout.preferredWidth: art.status === Image.Ready ? 64 : 0
            Layout.preferredHeight: 64
            visible: art.status === Image.Ready
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            // Decode at 2x the drawn size, not the art's full resolution.
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
                weight: 650
                color: Theme.bright
                elide: Text.ElideRight
            }

            BarText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                elide: Text.ElideRight
                font.pixelSize: Theme.size - 2
                color: Theme.dim
            }

            BarText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackAlbum ?? ""
                elide: Text.ElideRight
                font.pixelSize: Theme.size - 3
                color: Theme.dim
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
            // A player that cannot seek keeps the bar as a readout.
            onMoved: fraction => {
                if (root.player?.canSeek)
                    root.player.position = fraction * root.length;
            }
        }

        RowLayout {
            Layout.fillWidth: true

            BarText {
                Layout.fillWidth: true
                text: root.mmss(root.player?.position ?? 0)
                font.pixelSize: Theme.size - 4
                color: Theme.dim
            }

            BarText {
                text: root.mmss(root.length)
                font.pixelSize: Theme.size - 4
                color: Theme.dim
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
