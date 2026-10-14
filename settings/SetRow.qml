import QtQuick
import "../config"

// Fila de ajuste: título + descripción a la izquierda, control a la derecha
Item {
    id: root
    property string label
    property string desc
    default property alias control: ctrl.data

    width: parent ? parent.width : 860
    height: Math.max(texts.implicitHeight, ctrl.childrenRect.height) + 40

    Column {
        id: texts
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - ctrl.childrenRect.width - 30
        spacing: 5
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.label
            color: Theme.paper
            font {
                family: "Montserrat"
                pixelSize: 18
                weight: Font.Black
                letterSpacing: 0.5
            }
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.desc
            color: Theme.telemetry
            font {
                family: "JetBrains Mono"
                pixelSize: 10
                bold: true
                letterSpacing: 1.5
            }
        }
    }

    Item {
        id: ctrl
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Qt.alpha(Theme.paper, 0.12)
    }
}
