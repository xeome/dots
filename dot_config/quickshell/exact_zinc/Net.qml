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
    minWidth: 0
    // Suppressed while the menu is open: both anchor below this module, so
    // otherwise they stack on top of each other.
    tooltipText: menu.visible ? "" : `${network?.name ?? "?"}\nStrength: ${Math.round((network?.signalStrength ?? 0) * 100)}%\n${device?.name ?? ""}`

    // Copy-IP used to be the left click, back when there was no menu to open —
    // it's a row in the menu now. Right-click follows the Audio/pavucontrol
    // convention and lands in the full connection editor.
    onClicked: button => {
        if (button === Qt.RightButton)
            Quickshell.execDetached(["nm-connection-editor"]);
        else if (!menu.visible && Date.now() - menu.closedAt > 200)
            menu.visible = true;
    }

    BarText {
        // The same ramp idea as the battery icon: the strength is in the
        // tooltip either way, but a static glyph made the bar look identical at
        // one bar and four.
        //
        // The SSID used to ride along here and was the widest thing in the
        // right-hand row after the media label — up to ~180px of text that only
        // changes when you change network, and that the tooltip already gives.
        // The ramp is the part that moves, so it's the part that stays.
        readonly property var icons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

        text: icons[Math.min(4, Math.floor((root.network?.signalStrength ?? 0) * 5))]
        color: Theme.fg
    }

    // A PopupWindow isn't an Item, so the RowLayout that BarModule's default
    // property points at stores it without trying to lay it out.
    NetMenu {
        id: menu
        anchorItem: root
        device: root.device
    }
}
