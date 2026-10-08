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

    // Toggle with `qs -c xeome ipc call theme toggle`, bound to SUPER+T via
    // ~/.local/bin/theme-toggle (which also flips the GTK theme so
    // the shell and GTK apps never drift apart). Persisted to stateDir since
    // this is flipped rarely and forgetting it on every restart would be
    // more annoying than a stray state file.
    property alias light: persisted.light

    // stateDir isn't created just by quickshell running — nothing else here
    // writes to it — so make sure it exists before FileView tries to.
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

    // Graphite's tokens, copied from the skill rather than re-tuned: every dark
    // value there was settled by eye in small steps. The light set is derived
    // and has not been looked at yet.
    //
    // Colours are #AARRGGBB, Qt's order. The translucent ones are drawn over
    // whatever surface they sit on, so check-palette.py composites them over
    // their ground before it measures contrast.
    //
    // Grounds: the bar is `ground`, everything floating is `raised`. Graphite's
    // inset `panel` is what a window is, so nothing in the shell draws it: it
    // is here as the one source for the terminals' and GTK views' background.
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
    readonly property int anim: 200

    // Radius marks what you can interact with. Flat chrome — the bar itself,
    // dividers, the bar's bottom edge — stays square, so a rounded corner in
    // this shell always means "this responds to you".
    readonly property int radius: 6
    readonly property int radiusLg: 10

    // Inter, as graphite asks. "Inter Variable" and not "Inter": that name
    // resolves to the static Inter.ttc, where BarText's wght axis does nothing
    // and the 450/550/650 weights collapse onto 500 and 700.
    //
    // One family, not a list: QML's font value type has `family` (a string) and
    // no `families`, and a comma-separated string is read as one bogus family
    // name rather than a fallback chain. So the Nerd glyphs inlined into label
    // strings all over the shell (`󰐊 ${label}`) ride on fontconfig's own
    // fallback, which serves them from whichever Nerd Font is installed —
    // Iosevka Nerd Font on this machine. Correct either way: the Nerd Fonts
    // standard assigns the same glyph to the same private-use codepoint in
    // every patched font, so only the advance width varies by machine.
    readonly property string family: "Inter Variable"

    // Added to the space that separates a glyph from its value in the bar's
    // icon+number labels ("󰂰 35%"). Lives here because it is a property of the
    // font above, not of any one module: a proportional space is far narrower
    // than the monospace advance those labels were spaced by, and the glyphs
    // arrive from a fallback font narrower still, so the two ended up touching.
    // Brings the gap to roughly BarModule's own 6px row spacing.
    readonly property int glyphGap: 3
    // 14 rather than a sans-flattering 13: Inter and the JetBrains Mono the
    // shell once used have all but identical x-heights (0.546 vs 0.550 of em), so
    // the same pixelSize draws the same letter height and dropping it only made
    // the bar smaller. What did shrink is horizontal — proportional advances
    // render the clock's "14:32  Mon 17 Aug" at 122px where mono took 143 — and
    // that part is the point, not something to compensate for with size.
    // Scaled per machine by TEXT_SCALE (hyprland.lua, from .chezmoidata.toml);
    // unset means 1.
    readonly property int size: Math.round(14 * (Number(Quickshell.env("TEXT_SCALE")) || 1))
    // Every ordinary label inherits this. Eighteen of them used to pin 500
    // explicitly, which meant "lighter than the old 600" and silently became a
    // no-op once the default dropped — so raising the token moved almost
    // nothing. They were deleted rather than rewritten; only the weights that
    // deliberately differ (450 body, 650 headings, 700 active) are still local.
    readonly property int weight: 550
}
