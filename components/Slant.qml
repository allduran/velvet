import QtQuick

Item {
    id: root
    property real skew: -0.21            // tan(12°)
    property color color: "transparent"
    property color borderColor: "transparent"
    property int borderWidth: 0
    default property alias content: inner.data

    Rectangle {
        anchors.fill: parent
        color: root.color
        border {
            width: root.borderWidth
            color: root.borderColor
        }
        antialiasing: true
        transform: Matrix4x4 {
            matrix: Qt.matrix4x4(1, root.skew, 0, -root.skew * root.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        }
    }
    Item {
        id: inner
        anchors.fill: parent
    }
}
