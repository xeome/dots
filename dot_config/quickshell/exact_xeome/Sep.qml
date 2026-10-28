import QtQuick
import QtQuick.Layouts

// A hairline between groups in a toolbar row.
Rectangle {
    Layout.leftMargin: 4
    Layout.rightMargin: 4
    implicitWidth: 1
    implicitHeight: 18
    color: Theme.rule
}
