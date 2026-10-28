import QtQuick
import Quickshell
import Quickshell.Networking

// Wifi signal ramp, hidden unless connected over wifi. Left click opens
// NetMenu; right click opens nm-connection-editor.
BarModule {
    id: root

    readonly property var device: Networking.devices.values.find(d => d.connected && d.type === DeviceType.Wifi) ?? null
    readonly property var network: device?.networks.values.find(n => n.connected) ?? null

    visible: device !== null
    minWidth: 0
    tooltipText: menu.visible ? "" : `${network?.name ?? "?"}\nStrength: ${Math.round((network?.signalStrength ?? 0) * 100)}%\n${device?.name ?? ""}`

    onClicked: button => {
        if (button === Qt.RightButton)
            Quickshell.execDetached(["nm-connection-editor"]);
        else
            root.openMenu(menu);
    }

    BarText {
        readonly property var icons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

        text: icons[Math.min(4, Math.floor((root.network?.signalStrength ?? 0) * 5))]
        color: Theme.text
    }

    NetMenu {
        id: menu
        anchorItem: root
        device: root.device
    }
}
