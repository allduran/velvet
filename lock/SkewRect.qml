import QtQuick

// Rectangle con skewX como en CSS (grados), pivotando en el centro vertical.
Rectangle {
    property real skew: -12
    readonly property real k: Math.tan(skew * Math.PI / 180)

    antialiasing: true
    transform: Matrix4x4 {
        matrix: Qt.matrix4x4(1, k, 0, -k * height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
    }
}
