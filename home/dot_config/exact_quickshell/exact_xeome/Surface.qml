import QtQuick
import QtQuick.Shapes

// Every panel in the shell: the bar, menus, tooltips, the OSD, notifications.
// Children go on top of it like on a Rectangle.
//
// Painted outside in: a dark ring, the fill with corner glow and grain, a
// translucent line one pixel in, a highlight along the top. The ring sits
// inside the item because hosts fill their window, which clips anything outside.
//
// A Shape because a Rectangle's gradient is linear only; CurveRenderer because
// the default renderer steps the corners.
Item {
    id: root

    property color fill: Theme.raised
    property int radius: Theme.radiusLg
    // False on the bar: it is square, edge to edge, and draws its own bottom rule.
    property bool edged: true
    property bool lifted: true
    // Graphite's panel glow: a strong one top-left, a weaker one top-right.
    property color glow: Theme.glowPanel
    property color glowFar: Theme.glowPanelFar
    property real glowSize: 480
    // grain.py bakes one tile per ground, so this has to name the fill's ground.
    // Empty for none: Desk's flat tiles.
    property string grain: "grain-raised.png"

    readonly property int inset: edged ? 1 : 0

    Rectangle {
        visible: root.edged
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.ring
    }

    Shape {
        id: shape

        anchors.fill: parent
        anchors.margins: root.inset
        preferredRendererType: Shape.CurveRenderer

        readonly property int r: Math.max(0, root.radius - root.inset)

        ShapePath {
            strokeWidth: -1
            fillColor: root.fill
            PathRectangle {
                width: shape.width
                height: shape.height
                radius: shape.r
            }
        }

        // CSS draws these as 480x250 ellipses that are clear by 75%. A Qt
        // RadialGradient is a circle, so it is squashed to the same shape.
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: 0
                centerY: 0
                centerRadius: root.glowSize * 0.75
                focalX: 0
                focalY: 0
                GradientStop { position: 0; color: root.glow }
                GradientStop { position: 1; color: "transparent" }
            }
            fillTransform: PlanarTransform.fromScale(1, 0.52)
            PathRectangle {
                width: shape.width
                height: shape.height
                radius: shape.r
            }
        }

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: shape.width
                centerY: 0
                centerRadius: root.glowSize * 0.62
                focalX: shape.width
                focalY: 0
                GradientStop { position: 0; color: root.glowFar }
                GradientStop { position: 1; color: "transparent" }
            }
            fillTransform: PlanarTransform.fromScale(1, 0.5)
            PathRectangle {
                width: shape.width
                height: shape.height
                radius: shape.r
            }
        }

        // Hidden in light mode until the light palette gets its own tiles.
        ShapePath {
            strokeWidth: -1
            fillColor: "transparent"
            fillItem: Theme.light || !root.grain ? null : tile
            PathRectangle {
                width: shape.width
                height: shape.height
                radius: shape.r
            }
        }
    }

    // fillItem samples this as a texture. layer.enabled is what makes it
    // repeat past one 160px tile instead of smearing the last row.
    Image {
        id: tile

        width: shape.width
        height: shape.height
        visible: false
        source: root.grain
        fillMode: Image.Tile
        layer.enabled: !Theme.light
    }

    Rectangle {
        visible: root.edged
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: Theme.line
    }

    // A rounded ring cut to its top part, so the highlight bends with the
    // corners and stops before the sides.
    Item {
        visible: root.edged && root.lifted
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 2
        }
        height: root.radius
        clip: true

        Rectangle {
            width: parent.width
            height: parent.height * 3
            radius: Math.max(0, root.radius - 2)
            color: "transparent"
            border.width: 1
            border.color: Theme.lift
        }
    }
}
