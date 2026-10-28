import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

// Opened from Shot's thumbnail card: pen, arrow, rectangle, pixelate and text
// marks over the shot, kept in the image's own pixels. Ctrl+S or Enter writes
// them over the file at full size and copies it; Esc discards.
//
// The inks are the dark set's hot and warm plus white and black, as literals
// rather than Theme tokens, because a PNG does not flip with light mode.
Scope {
    id: root

    readonly property var tools: ["pen", "arrow", "rect", "blur", "text"]
    readonly property var hotkeys: [Qt.Key_P, Qt.Key_A, Qt.Key_R, Qt.Key_B, Qt.Key_T]
    readonly property var inks: ["#E2715A", "#E5AE52", "#FFFFFF", "#000000"]
    readonly property var sizes: [3, 6, 12]   // logical px; × dpr in the image

    property string shot: ""
    property var scr: null
    property int tool: 0
    property int ink: 0
    property int size: 1
    // { k: "pen", c, w, pts } · { k: "arrow" | "rect" | "blur", c, w, x1, y1, x2, y2 } · { k: "text", c, s, x, y, t }
    property var marks: []
    property var live: null   // the mark being dragged right now
    readonly property real dpr: scr?.devicePixelRatio ?? 1
    readonly property real w: sizes[size] * dpr

    function open(path: string, screen: var): void {
        root.shot = path;
        root.scr = screen;
        root.marks = [];
        root.live = null;
        typing.visible = false;
        win.visible = true;
        st.forceActiveFocus();
    }

    function close(): void {
        win.visible = false;
    }

    function commitWord(): void {
        if (!typing.visible)
            return;
        if (typing.text.trim())
            root.marks = root.marks.concat([{ k: "text", c: root.inks[root.ink], s: typing.font.pixelSize, x: typing.x, y: typing.y, t: typing.text }]);
        typing.visible = false;
        st.forceActiveFocus();
    }

    function save(): void {
        root.commitWord();
        canvas.grabToImage(r => {
            if (!r.saveToFile(root.shot)) {
                Quickshell.execDetached(["notify-send", "-a", "Screenshot", "Could not save the edit", root.shot]);
                return;
            }
            Quickshell.execDetached(["sh", "-c", 'wl-copy -t image/png < "$1"', "sh", root.shot]);
            root.close();
        }, Qt.size(img.implicitWidth, img.implicitHeight));
    }

    PanelWindow {
        id: win

        screen: root.scr
        visible: false
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        color: "#F20A0A0C"   // ground, nearly opaque
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-shot"

        Item {
            id: st

            anchors.fill: parent
            focus: true
            Keys.onPressed: e => {
                const t = root.hotkeys.indexOf(e.key);
                if (e.key === Qt.Key_Escape)
                    root.close();
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || (e.key === Qt.Key_S && e.modifiers & Qt.ControlModifier))
                    root.save();
                else if (e.key === Qt.Key_Z && e.modifiers & Qt.ControlModifier)
                    root.marks = root.marks.slice(0, -1);
                else if (t >= 0)
                    root.tool = t;
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_4)
                    root.ink = e.key - Qt.Key_1;
                else if (e.key === Qt.Key_BracketLeft)
                    root.size = Math.max(0, root.size - 1);
                else if (e.key === Qt.Key_BracketRight)
                    root.size = Math.min(2, root.size + 1);
                else
                    return;
                e.accepted = true;
            }

            // The shot, fitted between the top label and the bottom pills,
            // never larger than 1:1.
            Item {
                id: frame

                readonly property real fit: Math.min(1 / root.dpr, (st.width - 160) / Math.max(1, img.implicitWidth), (st.height - 100 - 160) / Math.max(1, img.implicitHeight))

                width: img.implicitWidth * fit
                height: img.implicitHeight * fit
                x: (st.width - width) / 2
                y: 100 + (st.height - 100 - 160 - height) / 2

                Item {
                    id: canvas

                    width: img.implicitWidth
                    height: img.implicitHeight
                    scale: frame.fit
                    transformOrigin: Item.TopLeft

                    Image {
                        id: img

                        source: root.shot ? "file://" + root.shot : ""
                        cache: false   // saved over the same path
                        smooth: true
                        mipmap: true
                    }

                    // The live mark last: its delegate is rebuilt on every
                    // mouse move, the committed ones only when one is added.
                    Repeater {
                        model: root.marks

                        Mark {
                            required property var modelData

                            m: modelData
                            src: img
                        }
                    }

                    Repeater {
                        model: root.live ? [root.live] : []

                        Mark {
                            required property var modelData

                            m: modelData
                            src: img
                        }
                    }

                    TextInput {
                        id: typing

                        visible: false
                        font.family: Theme.family
                        font.pixelSize: root.w * 6
                        font.weight: 650
                        color: root.inks[root.ink]
                        selectionColor: Theme.sel
                        // Handled here, not via onAccepted: TextInput passes an
                        // accepted Return on to st, which would save and close.
                        Keys.onReturnPressed: root.commitWord()
                        Keys.onEnterPressed: root.commitWord()
                        Keys.onEscapePressed: {
                            visible = false;
                            st.forceActiveFocus();
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.tool === 4 ? Qt.IBeamCursor : Qt.CrossCursor
                        onPressed: e => {
                            root.commitWord();
                            const c = root.inks[root.ink];
                            if (root.tool === 0) {
                                root.live = { k: "pen", c, w: root.w, pts: [Qt.point(e.x, e.y)] };
                            } else if (root.tool === 4) {
                                typing.text = "";
                                typing.x = e.x;
                                typing.y = e.y - typing.height / 2;
                                typing.visible = true;
                                typing.forceActiveFocus();
                            } else {
                                root.live = { k: root.tools[root.tool], c, w: root.w, x1: e.x, y1: e.y, x2: e.x, y2: e.y };
                            }
                        }
                        onPositionChanged: e => {
                            const l = root.live;
                            if (!l)
                                return;
                            // ponytail: the stroke is copied on every move, O(n²); fine into the thousands of points.
                            if (l.k === "pen")
                                root.live = Object.assign({}, l, { pts: l.pts.concat([Qt.point(e.x, e.y)]) });
                            else
                                root.live = Object.assign({}, l, { x2: e.x, y2: e.y });
                        }
                        onReleased: {
                            const l = root.live;
                            root.live = null;
                            if (l && (l.k === "pen" ? l.pts.length > 1 : Math.hypot(l.x2 - l.x1, l.y2 - l.y1) > 4 * root.dpr))
                                root.marks = root.marks.concat([l]);
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.line
                }

                RowLayout {
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 10
                    width: parent.width

                    BarText {
                        Layout.fillWidth: true
                        text: `Edit · ${root.tools[root.tool]}`
                        color: Theme.bright
                        weight: 650
                    }

                    BarText {
                        text: `${root.marks.length} ${root.marks.length === 1 ? "mark" : "marks"}   ${img.implicitWidth} × ${img.implicitHeight}`
                        color: Theme.dim
                        font.pixelSize: Theme.size - 2
                    }
                }
            }

            // Tools, inks and sizes, with the keys under them.
            ColumnLayout {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 40
                }
                spacing: 8

                Surface {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: bar.implicitWidth + 12
                    implicitHeight: bar.implicitHeight + 12

                    RowLayout {
                        id: bar

                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: root.tools

                            Chip {
                                required property string modelData
                                required property int index

                                text: modelData
                                on: index === root.tool
                                onClicked: {
                                    root.commitWord();
                                    root.tool = index;
                                }
                            }
                        }

                        Sep {}

                        Repeater {
                            model: root.inks

                            Rectangle {
                                id: inkBtn

                                required property color modelData
                                required property int index

                                implicitWidth: 30
                                implicitHeight: 30
                                radius: Theme.radius
                                color: index === root.ink ? Theme.sel : "transparent"

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: inkBtn.modelData
                                    border.width: 1
                                    border.color: Theme.line
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.ink = inkBtn.index
                                }
                            }
                        }

                        Sep {}

                        Repeater {
                            model: root.sizes

                            Rectangle {
                                id: sizeBtn

                                required property int modelData
                                required property int index

                                implicitWidth: 30
                                implicitHeight: 30
                                radius: Theme.radius
                                color: index === root.size ? Theme.sel : "transparent"

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: sizeBtn.modelData + 3
                                    height: width
                                    radius: width / 2
                                    color: sizeBtn.index === root.size ? Theme.bright : Theme.dim
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.size = sizeBtn.index
                                }
                            }
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
                        text: "p a r b t  tool     1–4  ink     [ ]  size     ctrl+z  undo     ctrl+s  save · copy     esc  discard"
                        color: Theme.dim
                        font.pixelSize: Theme.size - 3
                    }
                }
            }
        }
    }

    component Sep: Rectangle {
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        implicitWidth: 1
        implicitHeight: 18
        color: Theme.rule
    }

    // One mark, in the image's pixels.
    component Mark: Item {
        id: mk

        property var m
        property Item src   // the shot, for blur: ids don't reach into inline components
        readonly property real x0: Math.min(m.x1, m.x2)
        readonly property real y0: Math.min(m.y1, m.y2)
        readonly property real w0: Math.abs(m.x2 - m.x1)
        readonly property real h0: Math.abs(m.y2 - m.y1)

        Loader {
            sourceComponent: ({
                    pen: pen,
                    arrow: arrow,
                    rect: rectMark,
                    blur: blur,
                    text: word
                })[mk.m.k]
        }

        Component {
            id: pen

            Shape {
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: mk.m.c
                    strokeWidth: mk.m.w
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathPolyline {
                        path: mk.m.pts
                    }
                }
            }
        }

        Component {
            id: arrow

            Shape {
                id: ar

                // The head is a triangle four strokes long; the shaft stops at its base.
                readonly property real a: Math.atan2(mk.m.y2 - mk.m.y1, mk.m.x2 - mk.m.x1)
                readonly property real hl: mk.m.w * 4
                // Never behind the tail, or a short arrow's shaft pokes out of the head.
                readonly property real back: Math.min(hl * 0.8, Math.hypot(mk.m.x2 - mk.m.x1, mk.m.y2 - mk.m.y1))
                readonly property point base: Qt.point(mk.m.x2 - Math.cos(a) * back, mk.m.y2 - Math.sin(a) * back)

                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: mk.m.c
                    strokeWidth: mk.m.w
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathPolyline {
                        path: [Qt.point(mk.m.x1, mk.m.y1), ar.base]
                    }
                }

                ShapePath {
                    strokeColor: "transparent"
                    fillColor: mk.m.c
                    PathPolyline {
                        path: [Qt.point(mk.m.x2, mk.m.y2), Qt.point(mk.m.x2 - Math.cos(ar.a - 0.45) * ar.hl, mk.m.y2 - Math.sin(ar.a - 0.45) * ar.hl), Qt.point(mk.m.x2 - Math.cos(ar.a + 0.45) * ar.hl, mk.m.y2 - Math.sin(ar.a + 0.45) * ar.hl), Qt.point(mk.m.x2, mk.m.y2)]
                    }
                }
            }
        }

        Component {
            id: rectMark

            Rectangle {
                x: mk.x0 - mk.m.w / 2
                y: mk.y0 - mk.m.w / 2
                width: mk.w0 + mk.m.w
                height: mk.h0 + mk.m.w
                color: "transparent"
                border.width: mk.m.w
                border.color: mk.m.c
            }
        }

        // Pixelate, not a true blur: the area resampled into blocks.
        Component {
            id: blur

            ShaderEffectSource {
                readonly property real px: mk.m.w * 3

                x: mk.x0
                y: mk.y0
                width: mk.w0
                height: mk.h0
                sourceItem: mk.src
                sourceRect: Qt.rect(mk.x0, mk.y0, mk.w0, mk.h0)
                textureSize: Qt.size(Math.max(1, Math.ceil(mk.w0 / px)), Math.max(1, Math.ceil(mk.h0 / px)))
                smooth: false
            }
        }

        Component {
            id: word

            Text {
                x: mk.m.x
                y: mk.m.y
                text: mk.m.t
                font.family: Theme.family
                font.pixelSize: mk.m.s
                font.weight: 650
                color: mk.m.c
                style: Text.Outline
                styleColor: Qt.colorEqual(mk.m.c, "#000000") ? "#FFFFFF" : "#000000"
            }
        }
    }
}
