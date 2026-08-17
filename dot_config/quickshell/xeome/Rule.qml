import QtQuick
import QtQuick.Layouts

// The hairline every menu divides itself with. Was the same four lines pasted
// into five of them. Dimmer than Theme.border: this only ever has to separate
// two rows inside a panel that already has an outer edge.
Rectangle {
    Layout.fillWidth: true
    implicitHeight: 1
    color: Theme.divider
}
