pragma Singleton

import QtQuick
import Quickshell

// Ported from waybar/zinc.css. There are no hues in this theme by design —
// inversion (white fill, black text) is the only accent, and it now covers
// the OSD and notifications too, which used to be a separate blue/shadcn set.
//
// This whole folder is the shell as it stood at a3bb985, kept so the warm
// caffeine theme in ../xeome has something to be switched back from. Run it
// with `qs -c zinc` — kill the running instance first, since both draw a bar
// and the two would simply stack.
//
// Frozen on purpose. Fixes and features belong in ../xeome; the point of this
// copy is that it still looks the way it did, so it is not worth keeping the
// two in sync. The only edit made to it is its layer namespaces, which gained
// a `-zinc-` infix so the compositor can blur these translucent surfaces
// without also blurring behind ../xeome's opaque ones.
Singleton {
    readonly property color fg: "#ffffff"
    readonly property color fgDim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color fgMuted: "#555555"
    readonly property color fgInverted: "#000000"
    readonly property color active: "#ffffff"
    readonly property color activeHover: "#e0e0e0"

    // The bar sits on a Hyprland-blurred layer; this alpha is what lets the
    // blur show through. Raise it for legibility, lower it for more glass.
    readonly property color bar: Qt.rgba(0, 0, 0, 0.82)
    readonly property color surface: Qt.rgba(0.059, 0.059, 0.059, 0.6)
    readonly property color surfaceHover: Qt.rgba(1, 1, 1, 0.08)
    readonly property color border: Qt.rgba(1, 1, 1, 0.2)
    readonly property color borderHover: Qt.rgba(1, 1, 1, 0.45)
    // Tooltips and the calendar: opaque, because they land on top of arbitrary
    // window content and have to stay readable.
    readonly property color panel: "#0d0d0d"

    // Notification cards, which get their own Hyprland-blurred layer. Both
    // states share one alpha on purpose: fading between different alphas
    // strobes through a bright mid-grey and flashes the desktop through.
    readonly property color glass: Qt.rgba(0.05, 0.05, 0.05, 0.82)
    readonly property color glassHover: Qt.rgba(0.18, 0.18, 0.18, 0.82)

    readonly property int barHeight: 48
    readonly property int gap: 6
    readonly property int pad: 12
    readonly property int anim: 200   // matches waybar's 0.2s transitions

    readonly property string family: "JetBrainsMono Nerd Font Propo"
    readonly property int size: 14
    readonly property int weight: 600
}
