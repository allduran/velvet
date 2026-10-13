import QtQuick
import "../config"

// Buscador inclinado (papel)
Item {
    id: box
    property alias text: input.text
    property alias input: input
    property string placeholder
    property color accent: Theme.accent
    implicitHeight: 42
    signal keyPressed(var event)

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.paper
        antialiasing: true
        transform: Matrix4x4 {
            matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * bg.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        }
    }
    Text {
        id: icon
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        text: "⌕"
        color: box.accent
        font.family: "Bebas Neue"
        font.pixelSize: 22
    }
    TextInput {
        id: input
        anchors {
            left: icon.right
            leftMargin: 10
            right: parent.right
            rightMargin: 16
            verticalCenter: parent.verticalCenter
        }
        color: Theme.ink
        clip: true
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        font.bold: true
        Keys.onPressed: event => box.keyPressed(event)
        Text {
            visible: input.text === ""
            text: box.placeholder
            color: Qt.alpha(Theme.ink, 0.4)
            font: input.font
        }
    }
}
