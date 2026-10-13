import QtQuick

// Every label in the shell. Exists so the font is declared once, not 15 times.
Text {
    color: Theme.fg
    font.family: Theme.family
    font.pixelSize: Theme.size
    font.weight: Theme.weight
    renderType: Text.NativeRendering
}
