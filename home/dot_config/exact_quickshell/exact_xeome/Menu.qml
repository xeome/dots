import QtQuick
import QtQuick.Layouts

// The popup most bar modules share: one width and padding. Children go
// straight into the column. A derived menu's own onVisibleChanged runs
// alongside Popup's.
Popup {
    id: root

    default property alias rows: body.data

    contentWidth: 324
    contentHeight: body.implicitHeight + Theme.pad * 2

    ColumnLayout {
        id: body

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Theme.pad
            rightMargin: Theme.pad
        }
        spacing: 8
    }
}
