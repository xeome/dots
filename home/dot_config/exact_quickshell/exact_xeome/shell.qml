//@ pragma UseQApplication
//! The xeome desktop shell. Launch with: qs -c xeome
//
// QApplication rather than the default QGuiApplication: QsMenuAnchor needs
// QtWidgets to open a tray icon's menu.
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Desk {}
    }

    Osd {}
    NotifPopups {}
    Shot {}
    Walls {}
}
