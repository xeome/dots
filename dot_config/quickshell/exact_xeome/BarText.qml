import QtQuick

// Every label in the shell.
//
// Set `weight`, not `font.weight`. Qt rounds font.weight to the nearest 100,
// so the weight also drives Inter Variable's wght axis to render as asked.
// Reading font.weight inside the axis binding instead is a binding loop.
//
// Tabular figures, so labels that update in place (clock, battery, volume)
// don't reflow as digits change width.
Text {
    property int weight: Theme.weight

    color: Theme.text
    font.family: Theme.family
    font.pixelSize: Theme.size
    font.weight: weight
    font.variableAxes: ({
            wght: weight
        })
    font.features: ({
            tnum: 1
        })
    renderType: Text.NativeRendering
}
