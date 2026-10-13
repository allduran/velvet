import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property color fill
    property real cut: 24
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fill
        strokeColor: "transparent"
        startX: root.cut
        startY: 0
        PathLine {
            x: root.width
            y: 0
        }
        PathLine {
            x: root.width
            y: root.height
        }
        PathLine {
            x: 0
            y: root.height
        }
        PathLine {
            x: root.cut
            y: 0
        }
    }
}
