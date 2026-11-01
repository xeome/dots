import Quickshell.Services.Mpris

// The current track as "artist - title", dim and italic while paused, hidden
// when no player exists.
BarModule {
    id: root

    // A player picked in the menu wins, then whatever is playing, then whatever
    // exists. Once the picked player quits the lookup falls through by itself.
    property int selectedId: -1
    readonly property var player: Mpris.players.values.find(p => p.uniqueId === root.selectedId) ?? Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function clip(s: string, n: int): string {
        return s.length > n ? s.slice(0, n - 1) + "…" : s;
    }

    visible: player !== null
    tooltipText: menu.visible || !player ? "" : `${player.identity}: ${player.trackArtist} - ${player.trackTitle}`

    onClicked: button => {
        if (button === Qt.MiddleButton)
            root.player?.togglePlaying();
        else
            root.openMenu(menu);
    }

    // A popup anchored to a hidden module has nothing left to hang off.
    onVisibleChanged: if (!visible)
        menu.visible = false

    BarText {
        readonly property var p: root.player
        // Artist is often empty (podcasts, streams), so the separator only
        // joins two non-empty parts.
        readonly property string label: root.clip([p?.trackArtist ?? "", p?.trackTitle ?? ""].filter(s => s !== "").join(" - "), 28)

        text: `${p?.isPlaying ? "󰐊" : "󰏤"} ${label}`
        color: p?.isPlaying ? Theme.text : Theme.dim
        font.italic: !(p?.isPlaying ?? false)
    }

    MediaMenu {
        id: menu
        anchorItem: root
        player: root.player
        onPicked: id => root.selectedId = id
    }
}
