import QtQuick
import Quickshell
import Quickshell.Networking

// waybar `network`. The ↓/↑ bandwidth counters are gone — Quickshell.Networking
// exposes no throughput — so this is SSID and link state only. Click still
// copies the primary IP, which is what that binding was actually for.
BarModule {
    id: root

    readonly property var device: Networking.devices.values.find(d => d.connected) ?? null
    readonly property bool wifi: device?.type === DeviceType.Wifi
    readonly property var network: device?.networks.values.find(n => n.connected) ?? null

    tooltipText: !device ? "Disconnected" : wifi ? `${network?.name ?? "?"}\nStrength: ${Math.round((network?.signalStrength ?? 0) * 100)}%\n${device.name}` : `Wired\n${device.name}`

    onClicked: Quickshell.execDetached(["sh", "-c", "ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -1 | tr -d '\\n' | wl-copy"])

    BarText {
        text: !root.device ? "󰤟" : root.wifi ? `󰤟 ${root.network?.name ?? ""}` : "󰈀"
        color: root.device ? Theme.fg : Qt.rgba(1, 1, 1, 0.3)
    }
}
