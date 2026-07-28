//! Replaces waybar + swayosd + swaync. Launch with: qs -c xeome
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    Osd {}
    NotifPopups {}
}
