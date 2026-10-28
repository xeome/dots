import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Calc.mjs" as Calc

// Super+Shift+W, through `qs -c xeome ipc call walls toggle`. A wallpaper
// picker: every image in ~/.config/wallpapers as a parallelogram slice, the
// focused one wide. D turns on Dots, which shows and applies each wallpaper's
// dot-matrix bake (dots.py) instead, baked on demand into
// ~/.local/share/xeome-dots. Not ~/.cache: waypaper restores the applied bake
// at login, so a cache cleaner would leave the desktop bare. waypaper does the
// applying, so the choice survives a restart and its own picker keeps working.
Scope {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: `${root.home}/.config/wallpapers`
    readonly property string store: `${root.home}/.local/share/xeome-dots`

    property var scr: null
    property var files: []        // the originals, by name, bakes left out
    property bool dots: false
    property string pending: ""   // an original to apply once its bake lands
    property int rev: 0           // bumped when a bake exits

    // The store's bakes, by name. Reads `rev` as well as `count`, because an
    // overwritten bake leaves `count` alone.
    readonly property var bakes: {
        root.rev;
        const out = [];
        for (let i = 0; i < baked.count; i++)
            out.push(baked.get(i, "fileName"));
        return out;
    }

    function listed(file: string): bool {
        return root.bakes.includes(Calc.dotsName(file));
    }

    function toggle(): void {
        if (win.visible)
            return root.close();
        root.scr = Quickshell.screens.find(s => s.name === Compositor.focusedMonitor) ?? Quickshell.screens[0];
        waypaper.reload();
        const now = (waypaper.text().match(/^wallpaper = (.*)$/m) ?? [])[1] ?? "";
        const at = Calc.sourceOf(now.trim(), root.files);
        root.dots = at.dots;
        win.visible = true;
        list.currentIndex = Math.max(0, at.index);
        list.recenter();
        list.forceActiveFocus();
        // Reopening may change neither index nor Dots, so nothing else would
        // start a bake for the slice it opens on.
        root.check();
    }

    function close(): void {
        settle.stop();
        win.visible = false;
    }

    function set(path: string): void {
        // Detached, not a Process: swaybg inherits waypaper's stdio, and a
        // Process closes that pipe when waypaper exits, so swaybg dies of
        // SIGPIPE the next time it logs.
        Quickshell.execDetached(["waypaper", "--wallpaper", path]);
    }

    function apply(): void {
        const file = root.files[list.currentIndex];
        if (!file)
            return;
        // A newer choice wins over a dots apply still waiting on its bake.
        root.pending = "";
        if (!root.dots)
            root.set(`${root.dir}/${file}`);
        else if (root.listed(file))
            root.set(`${root.store}/${Calc.dotsName(file)}`);
        else {
            root.pending = file;
            root.bake(file);   // or the running bake's onExited gets to it
        }
        root.close();
    }

    // One bake at a time: exec() on a running Process kills the run in progress.
    function bake(file: string): void {
        if (baker.running)
            return;
        baker.file = file;
        baker.exec(["python3", "-I", `${Quickshell.shellDir}/../dots.py`, "--out", root.store, `${root.dir}/${file}`]);
    }

    // With Dots on, the focused slice gets its bake once you stop on it.
    function check(): void {
        if (win.visible && root.dots && root.files[list.currentIndex] && !root.listed(root.files[list.currentIndex]))
            settle.restart();
    }

    onDotsChanged: root.check()

    IpcHandler {
        target: "walls"

        function toggle(): void {
            root.toggle();
        }
    }

    FileView {
        id: waypaper

        path: `${root.home}/.config/waypaper/config.ini`
        blockAllReads: true
    }

    FolderListModel {
        id: originals

        folder: `file://${root.dir}`
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
        showDirs: false
        onCountChanged: {
            const out = [];
            for (let i = 0; i < count; i++)
                out.push(get(i, "fileName"));
            root.files = out.filter(f => !Calc.isDots(f));
        }
    }

    // Bound only once the folder exists: a FolderListModel started on a
    // missing folder lists the working directory instead and never notices
    // the folder appearing.
    Process {
        running: true
        command: ["mkdir", "-p", root.store]
        onExited: baked.folder = `file://${root.store}`
    }

    FolderListModel {
        id: baked

        nameFilters: ["*-dots.png"]
        showDirs: false
    }

    Timer {
        id: settle

        interval: 300
        onTriggered: {
            const file = root.files[list.currentIndex];
            if (root.dots && file && !root.listed(file))
                root.bake(file);
        }
    }

    // Its exit, not the listing, says what comes next: the listing changes
    // while the Process still counts as running, and by exit it already holds
    // the bake.
    Process {
        id: baker

        property string file

        onExited: code => {
            root.rev++;
            if (code !== 0) {
                Quickshell.execDetached(["notify-send", "-a", "Wallpaper", "Could not bake dots", baker.file]);
                // Only the apply that was waiting on this file goes with it;
                // one queued behind a failed preview still gets its bake.
                if (root.pending === baker.file)
                    root.pending = "";
                else if (root.pending)
                    root.bake(root.pending);
                return;
            }
            if (root.pending && root.listed(root.pending)) {
                root.set(`${root.store}/${Calc.dotsName(root.pending)}`);
                root.pending = "";
            } else if (root.pending) {
                root.bake(root.pending);
            } else {
                root.check();
            }
        }
    }

    PanelWindow {
        id: win

        // The slice geometry, from the screen: tall slices, the focused one
        // wide, each leaning right by `lean` across its height.
        readonly property real sliceH: Math.round(height * 0.55)
        readonly property real wideW: Math.round(width * 0.42)
        readonly property real narrowW: Math.round(width * 0.05)
        readonly property real lean: Math.round(sliceH * 0.12)

        screen: root.scr
        visible: false
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        color: "#D9000000"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-walls"

        MouseArea {
            // One slice per notch (120): a touchpad sends many small deltas,
            // and a zero one when the gesture ends.
            property real travel: 0

            anchors.fill: parent
            // Above or below the strip only: beside a slice is the gap its
            // slant leaves, still the strip.
            onClicked: mouse => {
                if (mouse.y < list.y || mouse.y > list.y + list.height)
                    root.close();
            }
            onWheel: wheel => {
                travel += wheel.angleDelta.y || wheel.angleDelta.x;
                for (; travel >= 120; travel -= 120)
                    list.decrementCurrentIndex();
                for (; travel <= -120; travel += 120)
                    list.incrementCurrentIndex();
            }
        }

        ListView {
            id: list

            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Math.round(win.height * 0.04)
            width: parent.width
            height: win.sliceH
            orientation: ListView.Horizontal
            model: root.files
            // Neighbours' slanted edges are parallel, so the gap between
            // them is `spacing` all the way up.
            spacing: 10
            interactive: false
            focus: true
            keyNavigationEnabled: true
            onCurrentIndexChanged: {
                root.check();
                Qt.callLater(list.recenter);
            }

            // The focused slice in the middle, re-done on every width step of
            // every slice, because the one shrinking beside it moves it too.
            // forceLayout() first, or the position read is a frame old. No
            // highlight range: StrictlyEnforceRange re-picks the current item
            // as widths animate, and stepping left runs on to the first slice.
            function recenter(): void {
                forceLayout();
                positionViewAtIndex(currentIndex, ListView.Center);
            }

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape)
                    root.close();
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                    root.apply();
                else if (e.key === Qt.Key_D)
                    root.dots = !root.dots;
                else
                    return;
                e.accepted = true;
            }

            delegate: Item {
                id: slice

                required property string modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                readonly property bool showDots: root.dots && root.listed(modelData)

                width: current ? win.wideW : win.narrowW
                height: win.sliceH

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.anim
                        easing.type: Easing.OutCubic
                    }
                }

                onWidthChanged: Qt.callLater(list.recenter)

                // The slice: an upright Item sheared into a parallelogram
                // (x shifted right by lean · (1 − y/h)) and clipped there. Its
                // image is sheared back, so the picture stays upright.
                Item {
                    id: shape

                    readonly property real k: win.lean / height

                    width: parent.width
                    height: parent.height
                    clip: true
                    transform: Matrix4x4 {
                        matrix: Qt.matrix4x4(1, -shape.k, 0, win.lean, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                    }

                    Image {
                        width: slice.width + win.lean
                        height: slice.height
                        source: slice.showDots ? `file://${root.store}/${Calc.dotsName(slice.modelData)}` : `file://${root.dir}/${slice.modelData}`
                        sourceSize.height: win.sliceH
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, shape.k, 0, -win.lean, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: slice.current ? "transparent" : "#59000000"
                        border.width: 1
                        border.color: slice.current ? Theme.bright : Theme.line
                    }

                    // Inside the shear, so clicks follow the slanted edges.
                    MouseArea {
                        anchors.fill: parent
                        onClicked: slice.current ? root.apply() : list.currentIndex = slice.index
                    }
                }
            }
        }

        // The name and the Dots switch, with the keys under them.
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: list.bottom
            anchors.topMargin: 28
            spacing: 8

            Surface {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: bar.implicitWidth + 12
                implicitHeight: bar.implicitHeight + 12

                MouseArea {
                    anchors.fill: parent
                }

                RowLayout {
                    id: bar

                    anchors.centerIn: parent
                    spacing: 4

                    BarText {
                        readonly property string file: root.files[list.currentIndex] ?? ""

                        Layout.leftMargin: 10
                        Layout.rightMargin: 6
                        text: file.replace(/\.[^.]*$/, "") + (root.dots && (settle.running || baker.running && baker.file === file) ? "  · baking…" : "")
                        color: Theme.bright
                        weight: 650
                    }

                    Sep {}

                    Chip {
                        text: "dots"
                        on: root.dots
                        onClicked: root.dots = !root.dots
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
                    text: "←→  browse     d  dots     ↵  apply     esc  close"
                    color: Theme.dim
                    font.pixelSize: Theme.size - 3
                }
            }
        }
    }
}
