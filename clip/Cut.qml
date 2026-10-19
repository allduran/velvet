import QtQuick
import QtQuick.Shapes
import "../config"

// Recorte de papel con las esquinas un poco irregulares (varía con `seed`)
Shape {
    id: cut
    property color fill: Theme.paper
    property int seed: 0
    readonly property var d: [[3, 0, 2, 4], [0, 3, 1, 2], [2, 1, 3, 0], [4, 2, 0, 1]][seed % 4]
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        fillColor: cut.fill
        strokeColor: "transparent"
        PathPolyline {
            path: [Qt.point(cut.d[0], 0), Qt.point(cut.width, cut.d[1]), Qt.point(cut.width - cut.d[2], cut.height), Qt.point(0, cut.height - cut.d[3]), Qt.point(cut.d[0], 0)]
        }
    }
}
