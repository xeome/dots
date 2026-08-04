import Quickshell
import Quickshell.Bluetooth

// Not a waybar module. Sits between Net and Audio because that's what it is —
// a radio whose main job here is putting a headset on the other end of the
// audio module.
//
// Visible whenever the machine has an adapter at all, including while it's
// switched off: hiding it when off would take the on-switch with it. No adapter
// (the desktop) and the module disappears the way Net does off wifi.
//
// Left-click opens BtMenu; right-click goes to blueman-manager, which is where
// unpairing and file transfer live.
BarModule {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
    // Whichever connected device reports a charge — in practice earbuds, and
    // the reason this module earns bar width at all. First one wins; two
    // batteries in a 60px box is a list, not a status.
    readonly property var powered: connected.find(d => d.batteryAvailable) ?? null

    visible: adapter !== null
    // A lone glyph can't change width, so it gets a square instead of waybar's
    // 60px box. It grows when a battery appears, which is a real event.
    minWidth: 0
    // Suppressed while the menu is open: both anchor below this module, so
    // otherwise they stack on top of each other.
    tooltipText: menu.visible ? "" : !adapter?.enabled ? "Bluetooth is off" : root.connected.length === 0 ? "Bluetooth on, nothing connected" : root.connected.map(d => `${menu.title(d)}${d.batteryAvailable ? ` · ${Math.round(d.battery * 100)}%` : ""}`).join("\n")

    onClicked: button => {
        if (button === Qt.RightButton)
            Quickshell.execDetached(["blueman-manager"]);
        else if (!menu.visible && Date.now() - menu.closedAt > 200)
            menu.visible = true;
    }

    BarText {
        text: !root.adapter?.enabled ? "󰂲" : root.connected.length === 0 ? "󰂯" : `󰂱${root.powered ? ` ${Math.round(root.powered.battery * 100)}%` : ""}`
        // Off is a state worth showing but not worth reading — same treatment as
        // a muted volume.
        color: root.adapter?.enabled ? root.fg : Theme.fgMuted
    }

    // A PopupWindow isn't an Item, so the RowLayout that BarModule's default
    // property points at stores it without trying to lay it out.
    BtMenu {
        id: menu
        anchorItem: root
    }
}
