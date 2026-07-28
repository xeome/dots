import Quickshell.Services.Mpris

// waybar `mpris`: "{status_icon} {artist} - {title}", 20 chars each,
// italic when paused, hidden entirely when no player exists.
BarModule {
    id: root

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function clip(s: string, n: int): string {
        return s.length > n ? s.slice(0, n) : s;
    }

    visible: player !== null
    tooltipText: player ? `${player.identity}: ${player.trackArtist} - ${player.trackTitle}` : ""
    onClicked: player?.togglePlaying()

    BarText {
        readonly property var p: root.player

        text: `${p?.isPlaying ? "󰐊" : "󰏤"} ${root.clip(p?.trackArtist ?? "", 20)} - ${root.clip(p?.trackTitle ?? "", 20)}`
        color: p?.isPlaying ? Theme.fg : Theme.fgMuted
        font.italic: !(p?.isPlaying ?? false)
    }
}
