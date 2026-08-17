pragma Singleton

import QtQuick
import Quickshell

// Caffeine's warm surface stack over the accent this repo already had:
// #ffc799 is the same primary sway/conf.d/colors.conf and hypr's colors.lua
// paint window borders with, so the shell and the compositor finally agree.
//
// Opaque by design. The bar used to be 82% black on a compositor blur layer,
// which made every contrast ratio a function of the wallpaper. Flat surfaces at
// a known lightness are what let the hairline borders below be this quiet.
Singleton {
    // Surfaces, three steps. Warm-neutral, not grey: the tint is most of what
    // makes this read differently from the zinc theme it replaces.
    readonly property color bar: "#111111"
    readonly property color panel: "#191919"     // menus, tooltips
    readonly property color card: "#191919"      // notification cards
    readonly property color cardHover: "#221f1c"
    readonly property color surface: "#1b1917"   // a module sitting on the bar
    readonly property color surfaceHover: "#262220"

    // Caffeine ships --border: #201e18, which is invisible against #191919 —
    // in the web app the separation comes from the lightness step between
    // surfaces plus a shadow. Nothing here casts a shadow, so the hairline is
    // the only separator and has to be lifted until it reads.
    readonly property color border: "#2e2a24"
    readonly property color borderHover: "#4a4238"
    // Dividers inside an already-bordered group, which only need to be seen
    // against their own container, not against the desktop.
    readonly property color divider: "#242019"

    readonly property color fg: "#eeeeee"
    readonly property color fgDim: "#b4b4b4"
    // 4.6:1 on `panel`, which is the floor rather than a preference: the
    // smallest thing wearing this is Power's 9px profile detail line, and the
    // old #555555 sat around 2.6:1 there.
    readonly property color fgMuted: "#8a817a"
    // Text on a filled module. Named for the job, not the colour, because
    // `warn` and `accent` fills both want it and `toggle` doesn't.
    readonly property color fgOnAccent: "#111111"

    // One colour, one meaning — see BarModule.tone:
    //   accent  focus or selection    (active workspace, selected menu row)
    //   toggle  a switch you flipped  (DND, idle inhibit, mic in use)
    //   warn    something wants you   (battery below the 30% line)
    // The old theme filled all three with the same white, so a battery at 25%
    // looked exactly like a clock that is lit permanently.
    readonly property color accent: "#ffc799"
    readonly property color accentHover: "#ffd7b3"
    readonly property color toggle: "#393028"
    readonly property color toggleHover: "#4a3d31"
    readonly property color warn: "#ff8080"
    readonly property color warnHover: "#ff9999"

    readonly property int barHeight: 48
    readonly property int gap: 6
    readonly property int pad: 12
    readonly property int anim: 200

    // Radius marks what you can interact with. Flat chrome — the bar itself,
    // dividers, the bar's bottom edge — stays square, so a rounded corner in
    // this shell always means "this responds to you".
    readonly property int radius: 6
    readonly property int radiusLg: 8

    // Adwaita Sans is GNOME's Inter rebase and is already installed, so this
    // costs no package.
    //
    // One family, not a list: QML's font value type has `family` (a string) and
    // no `families`, and a comma-separated string is read as one bogus family
    // name rather than a fallback chain. So the Nerd glyphs inlined into label
    // strings all over the shell (`󰐊 ${label}`) ride on fontconfig's own
    // fallback, which serves them from whichever Nerd Font is installed —
    // Iosevka Nerd Font on this machine. Correct either way: the Nerd Fonts
    // standard assigns the same glyph to the same private-use codepoint in
    // every patched font, so only the advance width varies by machine.
    readonly property string family: "Adwaita Sans"

    // Added to the space that separates a glyph from its value in the bar's
    // icon+number labels ("󰂰 35%"). Lives here because it is a property of the
    // font above, not of any one module: a proportional space is far narrower
    // than the monospace advance those labels were spaced by, and the glyphs
    // arrive from a fallback font narrower still, so the two ended up touching.
    // Brings the gap to roughly BarModule's own 6px row spacing.
    readonly property int glyphGap: 3
    // 14 rather than a sans-flattering 13: Adwaita Sans and the JetBrains Mono
    // this replaced have all but identical x-heights (0.546 vs 0.550 of em), so
    // the same pixelSize draws the same letter height and dropping it only made
    // the bar smaller. What did shrink is horizontal — proportional advances
    // render the clock's "14:32  Mon 17 Aug" at 122px where mono took 143 — and
    // that part is the point, not something to compensate for with size.
    readonly property int size: 14
    // Every ordinary label inherits this. Eighteen of them used to pin 500
    // explicitly, which meant "lighter than the old 600" and silently became a
    // no-op once the default dropped — so raising the token moved almost
    // nothing. They were deleted rather than rewritten; only the weights that
    // deliberately differ (450 body, 650 headings, 700 active) are still local.
    readonly property int weight: 550
}
