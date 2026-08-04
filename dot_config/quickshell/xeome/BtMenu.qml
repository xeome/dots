import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

// The bluetooth module's menu: radio toggle, a scan you have to ask for, and
// the devices. One press does the obvious thing to a row — disconnect what's
// connected, connect what's paired, pair what isn't.
//
// Discovery is off by default because leaving it on fills the list with every
// phone and earbud within 10m and keeps the radio awake for it. Unpairing lives
// in blueman-manager (right-click the module), like pavucontrol for audio.
Menu {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    // Connected first, then remembered, then whatever discovery turned up, each
    // group alphabetical. Without the name tiebreak the list reorders itself
    // mid-scan as signal-derived ordering churns.
    readonly property var devices: (root.adapter ? Bluetooth.devices.values.filter(d => d.adapter === root.adapter) : []).slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || root.title(a).localeCompare(root.title(b)))

    function title(d: var): string {
        return d.deviceName || d.name || d.address;
    }

    function activate(d: var): void {
        if (d.connected)
            d.disconnect();
        else if (d.paired)
            d.connect();
        else
            d.pair();
    }

    function detail(d: var): string {
        if (d.pairing)
            return "pairing···";
        if (d.state === BluetoothDeviceState.Connecting)
            return "···";
        if (d.state === BluetoothDeviceState.Disconnecting)
            return "···";
        // Only a connected device reports a battery, and only some do at all.
        if (d.connected && d.batteryAvailable)
            return `󰥉 ${Math.round(d.battery * 100)}%`;
        if (d.connected)
            return "connected";
        return d.paired ? "paired" : "";
    }

    // Scanning stops with the menu either way — leaving discovery running behind
    // a closed popup is the kind of thing you find later in a battery graph.
    onVisibleChanged: if (!root.visible && root.adapter?.discovering)
        root.adapter.discovering = false

    Pick {
        label: "Bluetooth"
        suffix: root.adapter?.enabled ? "on" : "off"
        current: root.adapter?.enabled ?? false
        selectable: !!root.adapter
        onClicked: if (root.adapter)
            root.adapter.enabled = !root.adapter.enabled
    }

    Pick {
        label: "Scan for devices"
        suffix: root.adapter?.discovering ? "···" : ""
        current: root.adapter?.discovering ?? false
        selectable: root.adapter?.enabled ?? false
        onClicked: if (root.adapter)
            root.adapter.discovering = !root.adapter.discovering
    }

    Rule {}

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: root.devices

            delegate: Pick {
                required property var modelData

                label: root.title(modelData)
                suffix: root.detail(modelData)
                current: modelData.connected
                onClicked: root.activate(modelData)
            }
        }

        BarText {
            Layout.fillWidth: true
            visible: root.devices.length === 0
            text: root.adapter?.enabled ? "No devices — try a scan" : "Bluetooth is off"
            font.pixelSize: Theme.size - 3
            font.weight: 500
            color: Theme.fgDim
        }
    }
}
