import QtQuick
import Quickshell
import Quickshell.Networking

// waybar `network`, wifi only. Wired/disconnected has nothing worth clicking
// or reporting, so the module disappears entirely instead of showing a dimmed
// ethernet glyph.
BarModule {
    id: root

    readonly property var device: Networking.devices.values.find(d => d.connected && d.type === DeviceType.Wifi) ?? null
    readonly property var network: device?.networks.values.find(n => n.connected) ?? null

    visible: device !== null
    tooltipText: `${network?.name ?? "?"}\nStrength: ${Math.round((network?.signalStrength ?? 0) * 100)}%\n${device?.name ?? ""}\nClick to copy this machine's IP`

    // Copying silently left no way to tell whether it worked. The shell is the
    // notification daemon, so notify-send lands in its own popup stack — and
    // its -t is honoured now that Notifs stopped overriding app timeouts.
    onClicked: Quickshell.execDetached(["sh", "-c", "ip=$(ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -1); [ -n \"$ip\" ] && printf %s \"$ip\" | wl-copy && notify-send -a Network -t 2000 'IP copied' \"$ip\""])

    BarText {
        // The same ramp idea as the battery icon: the strength is in the
        // tooltip either way, but a static glyph made the bar look identical at
        // one bar and four.
        readonly property var icons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

        text: `${icons[Math.min(4, Math.floor((root.network?.signalStrength ?? 0) * 5))]} ${root.network?.name ?? ""}`
        color: Theme.fg
    }
}
