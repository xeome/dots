import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

// Net's menu: the Wi-Fi switch, networks in range with a password field for new
// ones, and Copy IP. Everything else (static addresses, 802.1X, VPNs) is
// nm-connection-editor's, on the module's right click.
Menu {
    id: root

    // The connected Wi-Fi device, from Net.
    required property var device

    // The unknown secured network the password field is for. Picking any
    // network clears it.
    property var pending: null

    // Strongest first, with whatever we're on pinned to the top so the list
    // doesn't reshuffle under the cursor every time a scan lands.
    readonly property var networks: (root.device?.networks.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    // Rows listed; the line below the list counts the rest.
    readonly property int shown: 8

    function bars(strength: real): string {
        return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor((strength ?? 0) * 5))];
    }

    function activate(n: var): void {
        root.pending = null;
        if (n.connected) {
            n.disconnect();
            return;
        }
        // `known` means NetworkManager already holds a profile for it, so the
        // secret comes from the keyring rather than from the field below.
        if (n.known || n.security === WifiSecurityType.Open) {
            n.connect();
            return;
        }
        root.pending = n;
    }

    // Scanning costs radio time, so it runs only while the list is on screen.
    onVisibleChanged: {
        if (root.device)
            root.device.scannerEnabled = root.visible;
        if (!root.visible)
            root.pending = null;
    }

    Pick {
        label: "Wi-Fi"
        suffix: Networking.wifiHardwareEnabled ? (Networking.wifiEnabled ? "on" : "off") : "blocked"
        current: Networking.wifiEnabled
        // rfkill: the switch is physically off, so flipping this would lie.
        selectable: Networking.wifiHardwareEnabled
        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    Rule {}

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: root.networks.slice(0, root.shown)

            delegate: Pick {
                required property var modelData

                label: modelData.name
                // Mid-connect, the state replaces the signal bars.
                suffix: modelData.stateChanging ? "···" : `${modelData.security === WifiSecurityType.Open ? "" : "󰌾 "}${root.bars(modelData.signalStrength)}`
                current: modelData.connected
                onClicked: root.activate(modelData)
            }
        }

        BarText {
            Layout.fillWidth: true
            Layout.topMargin: 2
            visible: root.networks.length > root.shown
            text: `+${root.networks.length - root.shown} weaker`
            font.pixelSize: Theme.size - 4
            color: Theme.dim
        }

        BarText {
            Layout.fillWidth: true
            visible: root.networks.length === 0
            text: Networking.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
            font.pixelSize: Theme.size - 3
            color: Theme.dim
        }
    }

    ColumnLayout {
        id: secret

        Layout.fillWidth: true
        spacing: 2
        visible: !!root.pending
        onVisibleChanged: if (visible)
            psk.forceActiveFocus()

        Rule {}

        BarText {
            Layout.fillWidth: true
            text: `Password for ${root.pending?.name ?? ""}`
            font.pixelSize: Theme.size - 3
            color: Theme.dim
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: Theme.radius
            color: "transparent"
            border.width: 1
            border.color: psk.activeFocus ? Theme.warm : Theme.line

            TextInput {
                id: psk

                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.text
                font.family: Theme.family
                font.pixelSize: Theme.size - 2
                font.weight: Theme.weight
                selectionColor: Theme.text
                selectedTextColor: Theme.ground

                onAccepted: {
                    root.pending.connectWithPsk(text);
                    text = "";
                    root.pending = null;
                }

                Keys.onEscapePressed: {
                    text = "";
                    root.pending = null;
                }
            }
        }
    }

    Rule {}

    Pick {
        // The first global IPv4 from `ip`, not the device object, which also
        // carries tailscale and docker addresses.
        label: "󰆏  Copy IP address"
        onClicked: {
            Quickshell.execDetached(["sh", "-c", "ip=$(ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -1); [ -n \"$ip\" ] && printf %s \"$ip\" | wl-copy && notify-send -a Network -t 2000 'IP copied' \"$ip\""]);
            root.visible = false;
        }
    }
}
