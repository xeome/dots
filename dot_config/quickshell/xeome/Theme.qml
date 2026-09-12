pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The Caffeine colour scheme. One palette for the whole desktop — the shell,
// all three terminals, hypr's window borders, hyprlock, gtklock, rofi and
// vicinae all read the values below from their own config. See the block above
// `bar` for where they come from.
Singleton {
    id: root

    // Toggle with `qs -c xeome ipc call theme toggle`, bound to SUPER+T via
    // ~/.local/bin/theme-toggle (which also flips the Colloid GTK theme so
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

    // Caffeine's own values, from
    // github.com/crynta/terax-ai src/modules/theme/themes/caffeine.ts — the
    // same file ~/.config/ghostty/themes/caffeine, alacritty's caffeine.toml
    // and foot.ini are cut from. A colour that appears in two places on this
    // desktop is the same colour in both.
    //
    // Caffeine's neutrals are pure grey (#111111 → #191919 → #222222 →
    // #2a2a2a); all of its warmth lives in `primary`, `secondary` and the
    // ANSI ramp. The surfaces below used to carry a hand-mixed tint of their
    // own, which is precisely the drift this replaces.
    //
    // Opaque by design. The bar used to be 82% black on a compositor blur
    // layer, which made every contrast ratio a function of the wallpaper.
    // Flat surfaces at a known lightness are what let the hairline borders
    // below be this quiet — and the terminals are opaque for the same reason.
    //
    // `light` is Caffeine's own light variant, not an inversion of the dark
    // one. Floating surfaces (panel, card) stay *lighter* than the bar in
    // both modes, since there are no shadows to read elevation from; a module
    // sitting *in* the bar (`surface`) is Caffeine's `muted`, which reads as
    // recessed in light mode and raised in dark. Either way hover always
    // moves away from the mode's extreme.
    readonly property color bar: light ? "#f9f9f9" : "#111111"          // background
    readonly property color panel: light ? "#fcfcfc" : "#191919"        // popover: menus, tooltips
    readonly property color card: light ? "#fcfcfc" : "#191919"         // notification cards
    readonly property color cardHover: light ? "#efefef" : "#222222"    // muted
    readonly property color surface: light ? "#efefef" : "#222222"      // muted
    readonly property color surfaceHover: light ? "#e8e8e8" : "#2a2a2a" // accent

    // Caffeine's light `border` (#d8d8d8) is used as-is. Its dark one
    // (#201e18) is invisible against #191919 — in the web app the separation
    // comes from the lightness step between surfaces plus a shadow. Nothing
    // here casts a shadow, so the hairline is the only separator and has to
    // be lifted until it reads. `input` (#484848) is the scheme's own
    // brighter stroke, so the hover state needs no invention.
    readonly property color border: light ? "#d8d8d8" : "#2e2e2e"
    readonly property color borderHover: light ? "#b5b5b5" : "#484848"  // sidebarRing / input
    // Dividers inside an already-bordered group, which only need to be seen
    // against their own container, not against the desktop — so they sit one
    // Caffeine step below `border`. Not `muted` (#222222), which check-palette
    // rejects at 1.11:1 against the #191919 panel it draws on; `accent`
    // (#2a2a2a) is the next step up and the first one that reads.
    readonly property color divider: light ? "#e8e8e8" : "#2a2a2a"

    readonly property color fg: light ? "#202020" : "#eeeeee"           // foreground
    readonly property color fgDim: light ? "#646464" : "#b4b4b4"        // mutedForeground
    // Caffeine has no third foreground, so this one is derived — and derived
    // against a floor rather than a preference: 4.8:1 on `panel` in both
    // modes. The smallest thing wearing it is Power's 9px profile detail
    // line, where anything looser stops being text.
    readonly property color fgMuted: light ? "#707070" : "#8a8a8a"
    // Text on a filled module — Caffeine's `primaryForeground`. Named for the
    // job, not the colour, because `warn` and `accent` fills both want it and
    // `toggle` doesn't.
    readonly property color fgOnAccent: light ? "#ffffff" : "#081a1b"

    // One colour, one meaning — see BarModule.tone:
    //   accent  focus or selection    (active workspace, selected menu row)
    //   toggle  a switch you flipped  (DND, idle inhibit, mic in use)
    //   warn    something wants you   (battery below the 30% line)
    // The old theme filled all three with the same white, so a battery at 25%
    // looked exactly like a clock that is lit permanently.
    //
    // accent is Caffeine's `primary`/`ring` and toggle its `secondary`, in
    // both modes. This is also the accent Colloid's GTK theme is built with
    // (`-t orange`) and the gradient hypr paints its active border with, so
    // shell, compositor and GTK apps agree.
    readonly property color accent: light ? "#644a40" : "#ffe0c2"
    readonly property color accentHover: light ? "#4f3a31" : "#ffecd8"
    readonly property color toggle: light ? "#ffdfb5" : "#393028"
    readonly property color toggleHover: light ? "#ffd39b" : "#4a3d31"
    // Caffeine's `destructive` in dark. In light it is the same #e54d2e, but
    // white on it is only 3.9:1 and this is a chip with a battery percentage
    // inside it — so light mode borrows the scheme's own light ANSI red,
    // which is the same hue two steps down and clears 5:1.
    readonly property color warn: light ? "#c0392b" : "#e54d2e"
    readonly property color warnHover: light ? "#a52e22" : "#f0664a"

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
