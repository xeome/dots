import Quickshell.Services.Mpris

// waybar `mpris`: "{status_icon} {artist} - {title}", 20 chars each,
// italic when paused, hidden entirely when no player exists.
//
// Left-click opens MediaMenu, the way Audio and Battery open theirs; the
// one-click play/pause that used to be on the left button moves to the middle
// one, since XF86AudioPlay is the bind that actually gets used for it.
BarModule {
    id: root

    // A player picked in the menu wins, then whatever is playing, then whatever
    // exists. The lookup falls through on its own once that player quits, so
    // nothing has to notice and reset it.
    property int selectedId: -1
    readonly property var player: Mpris.players.values.find(p => p.uniqueId === root.selectedId) ?? Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function clip(s: string, n: int): string {
        return s.length > n ? s.slice(0, n - 1) + "…" : s;
    }

    visible: player !== null
    // Suppressed while the menu is open: both anchor below this module, so
    // otherwise they stack on top of each other.
    tooltipText: menu.visible || !player ? "" : `${player.identity}: ${player.trackArtist} - ${player.trackTitle}`

    onClicked: button => {
        if (button === Qt.MiddleButton)
            root.player?.togglePlaying();
        else if (!menu.visible && Date.now() - menu.closedAt > 200)
            menu.visible = true;
    }

    // A popup anchored to a hidden module has nothing left to hang off.
    onVisibleChanged: if (!visible)
        menu.visible = false

    BarText {
        readonly property var p: root.player
        // Artist is empty often enough — podcasts, streams, browser tabs — that
        // the separator has to earn its place rather than dangle off the front.
        readonly property string label: [root.clip(p?.trackArtist ?? "", 20), root.clip(p?.trackTitle ?? "", 20)].filter(s => s !== "").join(" - ")

        text: `${p?.isPlaying ? "󰐊" : "󰏤"} ${label}`
        color: p?.isPlaying ? Theme.fg : Theme.fgMuted
        font.italic: !(p?.isPlaying ?? false)
    }

    // A PopupWindow isn't an Item, so the RowLayout that BarModule's default
    // property points at stores it without trying to lay it out.
    MediaMenu {
        id: menu
        anchorItem: root
        player: root.player
        onPicked: id => root.selectedId = id
    }
}
