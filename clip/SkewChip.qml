import QtQuick
import "../config"

// Chip/botón inclinado con texto Bebas
Item {
    id: chip
    property string label
    property color fill: Theme.ink
    property color fg: Theme.on(fill)
    property color border: "transparent"
    property color shadow: "transparent"
    property int size: 18
    property int padding: 12
    signal clicked

    implicitWidth: t.implicitWidth + padding * 2
    implicitHeight: Math.max(24, t.implicitHeight + 4)

    readonly property real k: -0.21
    Rectangle {
        visible: chip.shadow.a > 0
        x: 4
        y: 4
        width: parent.width
        height: parent.height
        color: chip.shadow
        transform: Matrix4x4 {
            matrix: Qt.matrix4x4(1, chip.k, 0, -chip.k * chip.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        }
    }
    Rectangle {
        anchors.fill: parent
        color: chip.fill
        border.width: chip.border.a > 0 ? 2 : 0
        border.color: chip.border
        antialiasing: true
        transform: Matrix4x4 {
            matrix: Qt.matrix4x4(1, chip.k, 0, -chip.k * chip.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        }
    }
    Text {
        id: t
        anchors.centerIn: parent
        text: chip.label
        color: chip.fg
        font.family: "Bebas Neue"
        font.pixelSize: chip.size
        font.letterSpacing: 2
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
