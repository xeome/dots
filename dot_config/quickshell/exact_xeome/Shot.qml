import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "Calc.mjs" as Calc

// Print, through `qs -c xeome ipc call shot open`. Freezes the focused
// monitor (grim to a file shown under the overlay), takes a region, a window
// or the whole screen into ~/Pictures/Screenshots and the clipboard, then
// slides in a card that opens ShotEditor.
//
// Everything here is in the screen's logical pixels. The frozen frame is in
// device pixels, `k` per logical one, and only Calc.crop crosses between them.
// What is drawn over the frame is fixed black and white, not themed, because
// it sits on a screenshot.
Scope {
    id: root

    readonly property var modes: ["region", "window", "screen"]
    readonly property var delays: [0, 3, 10]
    readonly property string run: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    property int mode: 0
    property int delay: 0
    property string frozen: ""
    property var scr: null
    // A binding, so the positions refreshWindows() fetches land whenever they arrive.
    readonly property var wins: aim.visible ? Compositor.windows(root.scr) : []
    property rect drag: Qt.rect(0, 0, 0, 0)   // width 0: nothing dragged yet
    property real mx: 0
    property real my: 0
    readonly property var hover: wins.find(w => mx >= w.x && mx < w.x + w.width && my >= w.y && my < w.y + w.height) ?? null
    readonly property rect sel: mode === 2 ? Qt.rect(0, 0, aim.width, aim.height) : mode === 1 ? (hover ?? Qt.rect(0, 0, 0, 0)) : drag
    readonly property real k: frozenImg.sourceSize.width / Math.max(1, aim.width)

    // The last capture, for the flash and the card.
    property string shot: ""
    property string shotWhat: ""
    property string shotDims: ""
    property rect shotRect

    function open(): void {
        if (aim.visible)
            return;
        root.scr = Quickshell.screens.find(s => s.name === Compositor.focusedMonitor) ?? Quickshell.screens[0];
        Compositor.refreshWindows();
        // ppm, not png: grim writes it in a fraction of the time, and the
        // overlay cannot show before it is done.
        freeze.next = `${root.run}/xeome-shot-${Date.now()}.ppm`;
        freeze.exec(["sh", "-c", 'rm -f "$3"/xeome-shot-*.ppm; grim -t ppm -o "$1" "$2" && echo ok', "sh", root.scr.name, freeze.next, root.run]);
    }

    // Frees the decoded frame, which the picker's Canvas holds until told.
    // The capture script deletes the file itself once vips is done.
    function close(): void {
        aim.visible = false;
        picker.unloadImage(frozenImg.source);
        root.frozen = "";
    }

    function fire(): void {
        // A miss in window mode is a miss, not the whole screen.
        if (root.mode === 1 && !root.hover)
            return;
        const r = root.sel.width > 2 && root.sel.height > 2 ? root.sel : Qt.rect(0, 0, aim.width, aim.height);
        const c = Calc.crop(r, aim.width, aim.height, frozenImg.sourceSize.width, frozenImg.sourceSize.height);
        root.shotRect = r;
        root.shotWhat = `${root.modes[root.mode]} · ${Qt.formatTime(new Date(), "HH:mm")}`;
        root.shotDims = `${c.w} × ${c.h}`;
        const frame = root.frozen;
        // No timer: cut the frozen frame, so the shot is what you saw. With a
        // timer: shoot the live screen, in global logical coordinates.
        const g = `${Math.round(root.scr.x + c.x / root.k)},${Math.round(root.scr.y + c.y / root.k)} ${Math.round(c.w / root.k)}x${Math.round(c.h / root.k)}`;
        take.exec(["sh", "-c", `d="$HOME/Pictures/Screenshots"; mkdir -p "$d"; f="$d/shot-$(date +%F_%H-%M-%S-%3N).png"
            if [ "$1" = 0 ]; then vips crop -- "$4" "$f[compression=1]" $2; else sleep "$1"; grim -g "$3" "$f"; fi \\
                && wl-copy -t image/png < "$f" && printf %s "$f" || notify-send -a Screenshot "Screenshot failed" "$f"
            rm -f "$4"`,
            "sh", String(root.delays[root.delay]), `${c.x} ${c.y} ${c.w} ${c.h}`, g, frame]);
        root.close();
    }

    IpcHandler {
        target: "shot"

        function open(): void {
            root.open();
        }
    }

    Process {
        id: freeze

        property string next

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim())
                    return;
                root.frozen = freeze.next;   // only now: the file is complete
                root.mode = 0;
                root.drag = Qt.rect(0, 0, 0, 0);
                aim.visible = true;
                stage.forceActiveFocus();
            }
        }
    }

    Process {
        id: take

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text)
                    return;
                root.shot = text;
                fx.restart();
            }
        }
    }

    ShotEditor {
        id: editor
    }

    // ---- the overlay --------------------------------------------------------

    PanelWindow {
        id: aim

        screen: root.scr
        visible: false
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        // rules.lua turns layer animations off for this namespace: a frozen
        // frame that fades in looks like the screen flickering.
        WlrLayershell.namespace: "quickshell-shot"

        Item {
            id: stage

            anchors.fill: parent
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) {
                    Quickshell.execDetached(["rm", "-f", root.frozen]);
                    root.close();
                }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                    root.fire();
                else if (e.key === Qt.Key_Space)
                    root.mode = 1;
                else if (e.key === Qt.Key_Tab)
                    root.mode = (root.mode + 1) % 3;
                else if (e.key === Qt.Key_Backtab)
                    root.mode = (root.mode + 2) % 3;
                else if (e.key === Qt.Key_T)
                    root.delay = (root.delay + 1) % 3;
                else
                    return;
                e.accepted = true;
            }

            Image {
                id: frozenImg

                anchors.fill: parent
                // Shared with the loupe and the picker through the image cache,
                // so the frame is decoded once.
                source: root.frozen ? "file://" + root.frozen : ""
            }

            // Everything outside the selection darkens; a little before there is one.
            Item {
                anchors.fill: parent

                readonly property color c: root.sel.width ? "#B8000000" : "#59000000"
                readonly property rect r: root.sel.width ? root.sel : Qt.rect(0, 0, 0, 0)

                Rectangle {
                    width: parent.width
                    height: parent.r.y
                    color: parent.c
                }
                Rectangle {
                    y: parent.r.y + parent.r.height
                    width: parent.width
                    height: parent.height - y
                    color: parent.c
                }
                Rectangle {
                    y: parent.r.y
                    width: parent.r.x
                    height: parent.r.height
                    color: parent.c
                }
                Rectangle {
                    x: parent.r.x + parent.r.width
                    y: parent.r.y
                    width: parent.width - x
                    height: parent.r.height
                    color: parent.c
                }
            }

            // Crosshair.
            Rectangle {
                y: Math.round(root.my)
                width: parent.width
                height: 1
                color: "#40FFFFFF"
            }
            Rectangle {
                x: Math.round(root.mx)
                width: 1
                height: parent.height
                color: "#40FFFFFF"
            }

            // The selection: a 1px white edge with square handles, and its size
            // in frame pixels above it (inside it at the top of the screen).
            Item {
                id: vf

                visible: root.sel.width > 0
                x: root.sel.x
                y: root.sel.y
                width: root.sel.width
                height: root.sel.height

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: "#FFFFFF"
                }

                Repeater {
                    model: 4

                    Rectangle {
                        required property int index

                        x: (index % 2 ? vf.width : 0) - 3
                        y: (index > 1 ? vf.height : 0) - 3
                        width: 7
                        height: 7
                        color: "#FFFFFF"
                    }
                }

                Surface {
                    y: vf.y > 40 ? -height - 8 : 8
                    width: dims.implicitWidth + Theme.pad * 2
                    height: dims.implicitHeight + 8
                    radius: Theme.radius

                    BarText {
                        id: dims

                        anchors.centerIn: parent
                        text: `${root.modes[root.mode]}  ${Math.round(root.sel.width * root.k)} × ${Math.round(root.sel.height * root.k)}`
                        color: Theme.bright
                        font.pixelSize: Theme.size - 2
                    }
                }
            }

            // Loupe: the pixels under the cursor at 12x, with a ring on the
            // centre pixel and its position and colour below.
            Item {
                id: loupe

                // The cursor reaches the screen's far edge, x == width, which
                // is one pixel past the frame's last.
                readonly property int px: Math.max(0, Math.min(frozenImg.sourceSize.width - 1, Math.floor(root.mx * root.k)))
                readonly property int py: Math.max(0, Math.min(frozenImg.sourceSize.height - 1, Math.floor(root.my * root.k)))
                readonly property int zoom: 12
                readonly property int cells: 13   // odd, so one pixel sits in the middle

                x: root.mx + 24 + width > stage.width ? root.mx - 24 - width : root.mx + 24
                y: root.my + 24 + height > stage.height ? root.my - 24 - height : root.my + 24
                width: cells * zoom + 2
                height: width + readout.height + 6

                // The colour under the cursor, read from a 1x1 canvas hidden
                // behind the loupe.
                Canvas {
                    id: picker

                    property string hex: "#000000"

                    width: 1
                    height: 1
                    onImageLoaded: requestPaint()
                    onPaint: {
                        const g = getContext("2d"), src = frozenImg.source.toString();
                        if (!isImageLoaded(src))
                            return loadImage(src);
                        g.drawImage(src, loupe.px, loupe.py, 1, 1, 0, 0, 1, 1);
                        const d = g.getImageData(0, 0, 1, 1).data;
                        hex = "#" + [d[0], d[1], d[2]].map(v => v.toString(16).padStart(2, "0")).join("").toUpperCase();
                    }

                    Connections {
                        target: loupe

                        function onPxChanged(): void {
                            picker.requestPaint();
                        }

                        function onPyChanged(): void {
                            picker.requestPaint();
                        }
                    }
                }

                ClippingRectangle {
                    width: loupe.width
                    height: loupe.width
                    radius: Theme.radiusLg
                    color: "#000000"
                    border.width: 1
                    border.color: "#59FFFFFF"

                    Image {
                        source: frozenImg.source
                        smooth: false
                        width: frozenImg.sourceSize.width * loupe.zoom
                        height: frozenImg.sourceSize.height * loupe.zoom
                        x: 1 + (Math.floor(loupe.cells / 2) - loupe.px) * loupe.zoom
                        y: 1 + (Math.floor(loupe.cells / 2) - loupe.py) * loupe.zoom
                    }

                    Rectangle {
                        x: 1 + Math.floor(loupe.cells / 2) * loupe.zoom - 1
                        y: x
                        width: loupe.zoom + 2
                        height: width
                        color: "transparent"
                        border.width: 1
                        border.color: "#FFFFFF"
                    }
                }

                Surface {
                    id: readout

                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: row.implicitHeight + 10
                    radius: Theme.radius

                    RowLayout {
                        id: row

                        anchors.centerIn: parent
                        spacing: 8

                        BarText {
                            text: `${loupe.px}, ${loupe.py}`
                            color: Theme.bright
                            font.pixelSize: Theme.size - 2
                        }

                        Rectangle {
                            implicitWidth: 10
                            implicitHeight: 10
                            radius: 2
                            color: picker.hex
                            border.width: 1
                            border.color: Theme.line
                        }

                        BarText {
                            text: picker.hex
                            color: Theme.dim
                            font.pixelSize: Theme.size - 2
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.CrossCursor

                property point from

                // A held button keeps reporting past the screen edge.
                function clampX(x: real): real {
                    return Math.max(0, Math.min(width, x));
                }
                function clampY(y: real): real {
                    return Math.max(0, Math.min(height, y));
                }

                onPositionChanged: e => {
                    root.mx = clampX(e.x);
                    root.my = clampY(e.y);
                    if (pressed && root.mode === 0)
                        root.drag = Qt.rect(Math.min(from.x, root.mx), Math.min(from.y, root.my), Math.abs(root.mx - from.x), Math.abs(root.my - from.y));
                }
                onPressed: e => {
                    // The position only updates on move, so a click without
                    // moving would otherwise use the last capture's.
                    root.mx = clampX(e.x);
                    root.my = clampY(e.y);
                    if (root.mode !== 0)
                        return root.fire();
                    from = Qt.point(root.mx, root.my);
                    root.drag = Qt.rect(from.x, from.y, 0, 0);
                }
                // Region captures on release.
                onReleased: if (root.mode === 0 && root.drag.width > 2 && root.drag.height > 2)
                    root.fire()
            }

            // Modes and timer, with the keys under them.
            ColumnLayout {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 40
                }
                spacing: 8

                Surface {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: chips.implicitWidth + 12
                    implicitHeight: chips.implicitHeight + 12

                    // Keeps clicks on the pill from reaching the frame below.
                    MouseArea {
                        anchors.fill: parent
                    }

                    RowLayout {
                        id: chips

                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: root.modes

                            Chip {
                                required property string modelData
                                required property int index

                                text: modelData
                                on: index === root.mode
                                onClicked: root.mode = index
                            }
                        }

                        ShotEditor.Sep {}

                        Chip {
                            text: root.delay ? `${root.delays[root.delay]} s` : "timer"
                            on: root.delay > 0
                            onClicked: root.delay = (root.delay + 1) % 3
                        }
                    }
                }

                Surface {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: keys.implicitWidth + Theme.pad * 2
                    implicitHeight: keys.implicitHeight + 10
                    radius: Theme.radius

                    BarText {
                        id: keys

                        anchors.centerIn: parent
                        text: "drag  region     space  window     tab  mode     t  timer     ↵  capture     esc  cancel"
                        color: Theme.dim
                        font.pixelSize: Theme.size - 3
                    }
                }
            }
        }
    }

    // ---- after the shot: a flash on what was taken, then the card ------------

    PanelWindow {
        id: fired

        screen: root.scr
        visible: false
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        // Clicks go through everywhere except the card.
        mask: Region {
            item: card
        }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-shot"

        Rectangle {
            id: flash

            x: root.shotRect.x
            y: root.shotRect.y
            width: root.shotRect.width
            height: root.shotRect.height
            color: "#1FFFFFFF"
            border.width: 1
            border.color: "#FFFFFF"
        }

        Surface {
            id: card

            property real t: 0

            x: parent.width - 24 - width + 48 * (1 - t)
            y: parent.height - 24 - height
            opacity: t
            width: 320
            height: cardBody.implicitHeight + 24

            ColumnLayout {
                id: cardBody

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 10

                ClippingRectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 168
                    radius: Theme.radius
                    color: Theme.ground

                    Image {
                        anchors.fill: parent
                        source: root.shot ? "file://" + root.shot : ""
                        sourceSize: Qt.size(592, 336)
                        fillMode: Image.PreserveAspectCrop
                        // The editor saves over the same path.
                        cache: false
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    BarText {
                        Layout.fillWidth: true
                        text: root.shotDims
                        color: Theme.bright
                        weight: 650
                    }

                    BarText {
                        text: root.shotWhat
                        color: Theme.dim
                        font.pixelSize: Theme.size - 2
                    }
                }

                BarText {
                    text: "Copied · click to edit"
                    color: Theme.dim
                    font.pixelSize: Theme.size - 2
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    fx.stop();
                    fired.visible = false;
                    editor.open(root.shot, root.scr);
                }
            }
        }

        SequentialAnimation {
            id: fx

            PropertyAction {
                target: fired
                property: "visible"
                value: true
            }
            ParallelAnimation {
                NumberAnimation {
                    target: flash
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 700
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: card
                    property: "t"
                    from: 0
                    to: 1
                    duration: Theme.anim
                    easing.type: Easing.OutCubic
                }
            }
            PauseAnimation {
                duration: 2200
            }
            NumberAnimation {
                target: card
                property: "t"
                to: 0
                duration: Theme.anim
                easing.type: Easing.InCubic
            }
            PropertyAction {
                target: fired
                property: "visible"
                value: false
            }
        }
    }
}
