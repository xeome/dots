import QtQuick

// Every label in the shell. Exists so the font is declared once, not 15 times.
//
// Set `weight`, not `font.weight`. Qt rounds font.weight to the nearest 100 when
// it picks a face, so on its own a 550 renders as a 500 and the shell's 450s and
// 650s were silently landing on 500 and 700. Adwaita Sans is a variable font, so
// the weight also has to go into its wght axis to come out as the value asked
// for — and driving both off one property is what keeps that pair honest.
// Reading font.weight from inside the axis binding instead is a binding loop:
// both live in the same grouped property, so the group re-evaluates itself.
//
// On a static family the axis is ignored and the rounding simply comes back.
//
// Tabular figures are on by default rather than set per widget: the clock,
// battery, volume and media positions all update in place, and a proportional
// font reflows the module every time a digit changes width — which is the exact
// jitter BarModule.minWidth was added to hide back when the font was mono and
// tabular for free.
Text {
    property int weight: Theme.weight

    color: Theme.fg
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
