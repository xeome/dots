import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

// The network module's menu: radio toggle, the networks in range, and the IP.
//
// Deliberately not a network manager. Connecting to something you've joined
// before, joining something new with a password, and getting off a bad AP is
// the whole job — static addresses, 802.1X, VPNs and per-connection routing
// live in nm-connection-editor, which right-clicking the module opens. Same
// split as Audio and pavucontrol.
Menu {
    id: root

    // The connected wifi device, found once by Net — one lookup, two consumers.
    required property var device

    // Only unknown secured networks land here: the row is swapped for a
    // password field until it connects or you pick something else.
    property var pending: null

    // Strongest first, with whatever we're on pinned to the top so the list
    // doesn't reshuffle under the cursor every time a scan lands.
    readonly property var networks: (root.device?.networks.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    // A busy street resolves 30+ APs and nobody scrolls a bar popup looking for
    // the 24th strongest. The count below the list says what was cut.
    readonly property int shown: 8

    function bars(strength: real): string {
        return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor((strength ?? 0) * 5))];
    }

    function activate(n: var): void {
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

    // Scanning is a radio duty cycle, not a free query — it only runs while the
    // list is on screen, which is the only time a fresh result changes anything.
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
                // Mid-connect is the one moment the row's own state is worth
                // more than its signal strength.
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
            font.weight: 500
            color: Theme.fgDim
        }

        BarText {
            Layout.fillWidth: true
            visible: root.networks.length === 0
            text: Networking.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
            font.pixelSize: Theme.size - 3
            font.weight: 500
            color: Theme.fgDim
        }
    }

    // Only rendered for a network we have no saved secret for.
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
            color: Theme.fgDim
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            color: "transparent"
            border.width: 1
            border.color: psk.activeFocus ? Theme.borderHover : Theme.border

            TextInput {
                id: psk

                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.fg
                font.family: Theme.family
                font.pixelSize: Theme.size - 2
                font.weight: Theme.weight
                selectionColor: Theme.active
                selectedTextColor: Theme.fgInverted

                // No submit button: this field has exactly one thing to do, and
                // the row above already names the network it does it to.
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
        // The address is read off the interface rather than the device object:
        // this machine also holds tailscale and docker addresses, and the one
        // worth copying is the first global v4, which is what this picks.
        label: "󰆏  Copy IP address"
        onClicked: {
            Quickshell.execDetached(["sh", "-c", "ip=$(ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -1); [ -n \"$ip\" ] && printf %s \"$ip\" | wl-copy && notify-send -a Network -t 2000 'IP copied' \"$ip\""]);
            root.visible = false;
        }
    }
}
