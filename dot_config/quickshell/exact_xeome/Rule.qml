import QtQuick
import QtQuick.Layouts

// The hairline every menu divides itself with. Was the same four lines pasted
// into five of them. Graphite's translucent line, the same one panel edges use.
Rectangle {
    Layout.fillWidth: true
    implicitHeight: 1
    color: Theme.line
}
