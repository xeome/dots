import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets
import "Calc.mjs" as Calc

// Desktop widgets, after glyph-rice's home screen: a dot-matrix clock, the
// date and a greeting on the left, a 3×3 grid of square tiles on the right.
// One square module sizes everything, so the tiles read as one piece, and the
// dots of the clock, the rings and the CPU history repeat the dot wallpaper
// (dots.py).
//
// One per screen, on the layer under windows, and only while that screen's
// workspace is empty: tiled windows leave gaps, and a tile showing through
// them reads as a glitch. Hidden means unmapped, so nothing polls behind a
// window either.
//
// What sits on the wallpaper rather than a tile uses the dark set's literals:
// the wallpaper does not flip with light mode.
PanelWindow {
    id: root

    required property var modelData

    // The module: one tile's side. 0.19 of the height leaves the grid about
    // 60% of the screen tall, under the bar, on 1080p and 1440p alike.
    readonly property int m: Math.round(height * 0.19)
    readonly property int gap: 16
    // Unlit dots: glyph's one step above its tiles, on our panel-black tiles.
    readonly property color off: Theme.light ? Theme.rule : "#1A1A1C"

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property real length: root.player?.lengthSupported ? root.player.length : 0

    property int cpu: -1    // -1: no sample yet since the desk last showed
    property var hist: []   // one CPU sample per tick, the last 30 (60 s)
    property real ramUsed: 0   // GiB
    property real ramTotal: 0
    property int gpu: -1    // -1: no card that reports busy percent
    property string gpuDir: ""
    property string lastStat: ""

    // A fresh graph each time it shows: samples from before a window covered
    // it, and one average over the whole hidden stretch, would both lie.
    onVisibleChanged: if (!visible) {
        root.lastStat = "";
        root.hist = [];
        root.cpu = -1;
    }

    // ponytail: every Desk polls on its own; one singleton if more screens ever show at once.
    screen: modelData
    // Hyprland only; sway's Compositor says never.
    visible: Compositor.empty(modelData)
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-desk"
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    color: "transparent"
    // Only the tiles take clicks; the rest of the desktop stays the compositor's.
    mask: Region {
        item: grid
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // ---- system stats, every 2 s while shown ---------------------------------

    // The card with the most VRAM: the discrete GPU on the desktop, the only
    // one on a laptop. Its busy percent is all the ring shows.
    Process {
        running: true
        command: ["sh", "-c", 'for d in /sys/class/drm/card[0-9]*/device; do [ -r "$d/gpu_busy_percent" ] && echo "$(cat "$d/mem_info_vram_total" 2>/dev/null || echo 0) $d"; done | sort -n | tail -1 | cut -d" " -f2']
        stdout: StdioCollector {
            onStreamFinished: root.gpuDir = text.trim()
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        blockAllReads: true
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        blockAllReads: true
    }

    FileView {
        id: busy

        path: root.gpuDir ? `${root.gpuDir}/gpu_busy_percent` : ""
        blockAllReads: true
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            const line = stat.text().split("\n")[0];
            if (root.lastStat) {
                root.cpu = Calc.cpuBusy(root.lastStat, line);
                root.hist = root.hist.concat([root.cpu]).slice(-30);
            }
            root.lastStat = line;

            meminfo.reload();
            const kb = name => Number(meminfo.text().match(new RegExp(`^${name}:\\s+(\\d+)`, "m"))?.[1] ?? 0);
            root.ramTotal = kb("MemTotal") / 1048576;
            root.ramUsed = root.ramTotal - kb("MemAvailable") / 1048576;

            if (root.gpuDir) {
                busy.reload();
                root.gpu = parseInt(busy.text()) || 0;
            }
        }
    }

    // While playing, the position only moves if someone asks for it.
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && (root.player?.isPlaying ?? false)
        onTriggered: root.player.positionChanged()
    }

    // ---- left: clock, date, greeting --------------------------------------------

    ColumnLayout {
        x: Math.round(root.width * 0.08)
        y: grid.y
        spacing: 0

        Num {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "#F7F8F8"
            font.pixelSize: Math.round(root.height * 0.22)
        }

        BarText {
            Layout.topMargin: Math.round(root.m * 0.12)
            Layout.leftMargin: 4
            text: `${Qt.formatDateTime(clock.date, "dddd · d MMMM")} · week ${Calc.isoWeek(clock.date)}`
            color: "#8A8F98"
            font.pixelSize: Theme.size + 4
            font.letterSpacing: 1
        }

        BarText {
            Layout.topMargin: Math.round(root.m * 0.45)
            text: `Good ${Calc.greeting(clock.date.getHours())},`
            color: "#F7F8F8"
            weight: 300
            font.pixelSize: Math.round(root.height * 0.05)
        }

        BarText {
            text: `${Quickshell.env("USER")}.`
            color: "#8A8F98"
            weight: 300
            font.pixelSize: Math.round(root.height * 0.05)
        }
    }

    // ---- right: the grid ---------------------------------------------------------

    Item {
        id: grid

        x: root.width - Math.round(root.width * 0.06) - width
        y: Math.round(root.height * 0.12)
        width: 3 * root.m + 2 * root.gap
        height: width

        // Row 1: calendar · CPU · GPU.
        Tile {
            col: 0
            row: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(root.m * 0.1)
                spacing: 0

                BarText {
                    text: Qt.formatDateTime(clock.date, "MMMM")
                    color: Theme.dim
                    font.pixelSize: Theme.size - 1
                }

                Num {
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    text: clock.date.getDate()
                    font.pixelSize: Math.round(root.m * 0.42)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: ["M", "T", "W", "T", "F", "S", "S"]

                        BarText {
                            id: day

                            required property string modelData
                            required property int index
                            readonly property bool today: (clock.date.getDay() + 6) % 7 === index

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: today ? Theme.bright : Theme.dim
                            weight: today ? 650 : Theme.weight
                            font.pixelSize: Theme.size - 3

                            Rectangle {
                                visible: day.today
                                anchors.top: parent.bottom
                                anchors.topMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 10
                                height: 2
                                color: Theme.bright
                            }
                        }
                    }
                }
            }
        }

        RingTile {
            col: 1
            row: 0
            fraction: Math.max(0, root.cpu) / 100
            value: root.cpu < 0 ? "—" : root.cpu
            label: "CPU %"
        }

        RingTile {
            col: 2
            row: 0
            fraction: Math.max(0, root.gpu) / 100
            value: root.gpu < 0 ? "—" : root.gpu
            label: "GPU %"
        }

        // Row 2: now playing · RAM.
        Tile {
            col: 0
            row: 1
            span: 2

            BarText {
                visible: root.player === null
                anchors.centerIn: parent
                text: "Nothing playing"
                color: Theme.dim
            }

            RowLayout {
                visible: root.player !== null
                anchors.fill: parent
                anchors.margins: Math.round(root.m * 0.1)
                spacing: Math.round(root.m * 0.1)

                ClippingRectangle {
                    // Collapses rather than reserving a grey hole: plenty of
                    // players publish no art.
                    visible: art.status === Image.Ready
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    radius: Theme.radius
                    color: Theme.ground

                    Image {
                        id: art

                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(256, 256)
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    BarText {
                        Layout.fillWidth: true
                        text: `Now playing · ${root.player?.identity ?? ""}`
                        color: Theme.dim
                        elide: Text.ElideRight
                        font.pixelSize: Theme.size - 3
                    }

                    BarText {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        text: root.player?.trackTitle ?? ""
                        color: Theme.bright
                        weight: 650
                        elide: Text.ElideRight
                        font.pixelSize: Theme.size + 3
                    }

                    BarText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.player?.trackArtist ?? ""
                        color: Theme.dim
                        elide: Text.ElideRight
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Track {
                        visible: root.length > 0 && (root.player?.positionSupported ?? false)
                        value: root.length > 0 ? (root.player?.position ?? 0) / root.length : 0
                        onMoved: fraction => {
                            if (root.player?.canSeek)
                                root.player.position = Math.max(0, Math.min(1, fraction)) * root.length;
                        }
                    }

                    RowLayout {
                        spacing: 8

                        MediaMenu.Button {
                            glyph: "󰒮"
                            enabled: root.player?.canGoPrevious ?? false
                            onActivated: root.player.previous()
                        }

                        MediaMenu.Button {
                            glyph: root.player?.isPlaying ? "󰏤" : "󰐊"
                            enabled: root.player?.canTogglePlaying ?? false
                            onActivated: root.player.togglePlaying()
                        }

                        MediaMenu.Button {
                            glyph: "󰒭"
                            enabled: root.player?.canGoNext ?? false
                            onActivated: root.player.next()
                        }
                    }
                }
            }
        }

        RingTile {
            col: 2
            row: 1
            fraction: root.ramTotal > 0 ? root.ramUsed / root.ramTotal : 0
            value: root.ramUsed.toFixed(1)
            label: `RAM · ${Math.round(root.ramTotal)} G`
        }

        // Row 3: CPU over the last minute, as a dot matrix: each column one
        // sample, lit from the bottom, its top dot brightest.
        Tile {
            id: history

            col: 0
            row: 2
            span: 3

            readonly property int pad: Math.round(root.m * 0.1)
            readonly property int s: 3   // space between dots
            // Square dots sized by whichever runs out first, the width or the
            // height left under the label: by width alone the 8 rows overflow
            // a 1080p tile.
            readonly property real d: Math.min((width - 2 * pad - 29 * s) / 30, (height - 2 * pad - histLabel.height - 8 - 7 * s) / 8)

            BarText {
                id: histLabel

                x: history.pad
                y: history.pad
                text: "CPU · 60 s"
                color: Theme.dim
                font.pixelSize: Theme.size - 3
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: history.pad
                columns: 30
                spacing: history.s

                Repeater {
                    model: 30 * 8

                    Rectangle {
                        required property int index

                        readonly property var v: root.hist[root.hist.length - 30 + index % 30]
                        readonly property int lit: v === undefined ? 0 : Math.max(1, Math.round(v * 8 / 100))
                        readonly property int level: 8 - Math.floor(index / 30)   // 8 at the top, 1 at the bottom

                        width: history.d
                        height: history.d
                        radius: history.d / 2
                        color: level === lit ? Theme.bright : level < lit ? Theme.dim : root.off
                    }
                }
            }
        }
    }

    // A grid cell: `span` modules wide, one tall. Flat `panel` with only the
    // hairline edge, glyph's barely-lifted tile on the black wallpaper: the
    // shell's raised grey with its glow and grain read grey over black.
    component Tile: Surface {
        property int col
        property int row
        property int span: 1

        x: col * (root.m + root.gap)
        y: row * (root.m + root.gap)
        width: span * root.m + (span - 1) * root.gap
        height: root.m
        fill: Theme.panel
        glow: "transparent"
        glowFar: "transparent"
        grain: ""
        lifted: false
    }

    // A ring of dots lit clockwise from 12 by `fraction`, the value in Doto
    // in the middle. After glyph's Ring.
    component RingTile: Tile {
        id: rt

        property real fraction
        property var value
        property string label

        Item {
            id: ring

            readonly property int n: 44
            readonly property real dot: Math.max(3, root.m * 0.026)
            readonly property int lit: Math.round(n * Math.max(0, Math.min(1, rt.fraction)))

            anchors.fill: parent
            anchors.margins: Math.round(root.m * 0.08)

            Repeater {
                model: ring.n

                Rectangle {
                    required property int index

                    readonly property real a: index / ring.n * 2 * Math.PI - Math.PI / 2

                    x: ring.width / 2 * (1 + Math.cos(a)) - width / 2
                    y: ring.height / 2 * (1 + Math.sin(a)) - height / 2
                    width: ring.dot
                    height: ring.dot
                    radius: ring.dot / 2
                    color: index < ring.lit ? Theme.bright : root.off
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Math.round(root.m * 0.03)

            Num {
                Layout.alignment: Qt.AlignHCenter
                text: rt.value
                font.pixelSize: Math.round(root.m * 0.24)
            }

            BarText {
                Layout.alignment: Qt.AlignHCenter
                text: rt.label
                color: Theme.dim
                font.pixelSize: Theme.size - 3
            }
        }
    }

    // Numbers in Doto, with round dots: the font's default is ROND 0, square
    // pixels, which would clash with every other dot here. Plain Text, not
    // BarText, whose variableAxes only carries wght.
    component Num: Text {
        color: Theme.bright
        font.family: "Doto"
        font.weight: Font.Black
        font.variableAxes: ({
                ROND: 100,
                wght: 900
            })
    }
}
