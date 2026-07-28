import Quickshell.Wayland

// waybar `idle_inhibitor`.
BarModule {
    id: root

    required property var window
    property bool active: false

    inverted: active
    tooltipText: `Idle inhibitor: ${active ? "Active" : "Inactive"}`
    onClicked: active = !active

    IdleInhibitor {
        window: root.window
        enabled: root.active
    }

    BarText {
        text: root.active ? "󰅶" : "󰾪"
        color: root.fg
        font.pixelSize: Theme.size + 3   // waybar: font-size 1.25em
    }
}
