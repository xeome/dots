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
    tooltipText: `${network?.name ?? "?"}\nStrength: ${Math.round((network?.signalStrength ?? 0) * 100)}%\n${device?.name ?? ""}`

    onClicked: Quickshell.execDetached(["sh", "-c", "ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -1 | tr -d '\\n' | wl-copy"])

    BarText {
        text: `󰤟 ${root.network?.name ?? ""}`
        color: Theme.fg
    }
}
