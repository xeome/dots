//@ pragma UseQApplication
//! Replaces waybar + swayosd + swaync. Launch with: qs -c xeome
//
// QApplication (rather than the default QGuiApplication) is what pulls in
// QtWidgets, and QsMenuAnchor refuses to open a tray icon's menu without it.
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    Osd {}
    NotifPopups {}
}
