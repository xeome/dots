pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The graphite palette (the graphite-ui skill). One palette for the whole
// desktop: hypr's borders, hyprlock, vicinae, the GTK themes, yazi, zathura and
// the terminals' background repeat the values below in their own config.
// check-palette.py holds most of them to it; yazi and zathura it does not.
// The Qt theme is generated from them by kvantum.py on every chezmoi apply
// that changes this file.
Singleton {
    id: root

    // SUPER+T runs ~/.local/bin/theme-toggle, which flips GTK too and calls
    // `qs -c xeome ipc call theme toggle`. Persisted across restarts.
    property alias light: persisted.light

    // Quickshell does not create stateDir; FileView needs it to exist.
    Process {
        command: ["mkdir", "-p", Quickshell.stateDir]
        running: true
    }

    FileView {
        path: `${Quickshell.stateDir}/theme.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: persisted
            property bool light: false
        }
    }

    IpcHandler {
        target: "theme"

        function toggle(): bool {
            root.light = !root.light;
            return root.light;
        }
    }

    // Colours are #AARRGGBB, Qt's order. check-palette.py composites the
    // translucent ones over their ground before it measures contrast.
    //
    // Grounds: the bar is `ground`, everything floating is `raised`, and
    // `panel` is a window's background (terminals, GTK views, the desk's tiles).
    readonly property color ground: light ? "#FFEDEDEF" : "#FF0A0A0C"
    readonly property color panel: light ? "#FFF8F8F9" : "#FF0E0E10"
    readonly property color raised: light ? "#FFFFFFFF" : "#FF151618"
    readonly property color rule: light ? "#FFCFCFD3" : "#FF232427"   // slider troughs

    // Two tones carry hierarchy: bright for titles and values, dim for labels
    // and metadata. text is everything else that is read, not scanned.
    readonly property color text: light ? "#FF26272B" : "#FFE6E7EA"
    readonly property color bright: light ? "#FF0F1011" : "#FFF7F8F8"
    readonly property color dim: light ? "#FF62666D" : "#FF8A8F98"

    // Colour is spent on meaning only. warm is focus and a live microphone,
    // hot is something that wants you (low battery, urgent workspace, a
    // critical notification). Selection is not a colour: it is `sel`.
    readonly property color warm: light ? "#FF885B0C" : "#FFE5AE52"
    readonly property color hot: light ? "#FFAF3A1E" : "#FFE2715A"

    // Every edge is two lines: `line` one pixel in, `ring` as the outer pixel.
    readonly property color line: light ? "#17000000" : "#14FFFFFF"
    readonly property color ring: light ? "#0A000000" : "#4D000000"
    readonly property color lift: light ? "#CCFFFFFF" : "#0DFFFFFF"   // a card's top edge
    readonly property color card: light ? "#80FFFFFF" : "#05FFFFFF"   // bar modules: nearly clear
    readonly property color hover: light ? "#0A000000" : "#0DFFFFFF"
    readonly property color sel: light ? "#0E000000" : "#12FFFFFF"

    // Corner glow, colourless and gone within a few hundred pixels.
    readonly property color glow: light ? "#B3FFFFFF" : "#0DFFFFFF"          // the bar
    readonly property color glowPanel: light ? "#E6FFFFFF" : "#11FFFFFF"     // raised, top-left
    readonly property color glowPanelFar: light ? "#66FFFFFF" : "#08FFFFFF"  // raised, top-right

    readonly property int barHeight: 48
    readonly property int gap: 6
    readonly property int pad: 12
    // Every shell transition: 200 ms, decelerating. Hyprland's `ease` curve in
    // lua_modules/settings.lua is the same OutCubic, so windows move alike.
    readonly property int anim: 200
    readonly property int ease: Easing.OutCubic

    // Radius marks what you can interact with. Flat chrome — the bar itself,
    // dividers, the bar's bottom edge — stays square, so a rounded corner in
    // this shell always means "this responds to you".
    readonly property int radius: 6
    readonly property int radiusLg: 10

    // "Inter Variable", not "Inter": that name resolves to the static
    // Inter.ttc, where the wght axis does nothing and 450/550/650 collapse
    // onto 500 and 700. One family only, since QML reads a comma list as one
    // bogus name; the Nerd glyphs in labels come from fontconfig's fallback.
    readonly property string family: "Inter Variable"

    // Widens the space between a glyph and its value ("󰂰 35%"): Inter's space
    // is narrow and the fallback glyphs narrower, so the two touched.
    readonly property int glyphGap: 3
    // Scaled per machine by TEXT_SCALE (hyprland.lua, from .chezmoidata.toml).
    readonly property int size: Math.round(14 * (Number(Quickshell.env("TEXT_SCALE")) || 1))
    // Every ordinary label inherits this; only 450 body, 650 headings and 700
    // active are set locally.
    readonly property int weight: 550
}
