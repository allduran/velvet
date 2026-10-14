import QtQuick
import "../config"
import "../components"

// Entrada del menú lateral (P3): número + nombre grande + subtítulo
Item {
    id: root
    property string code
    property string name
    property string sub
    property bool active
    property color tone: Theme.accent
    signal clicked

    width: active ? 430 : 400
    height: 86
    opacity: active || area.containsMouse ? 1 : 0.78
    Behavior on width {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    // Sombra dura doble (color de la sección + tinta)
    Slant {
        visible: root.active
        x: 11
        y: 11
        width: parent.width
        height: parent.height
        color: Theme.ink
    }
    Slant {
        visible: root.active
        x: 9
        y: 9
        width: parent.width
        height: parent.height
        color: root.tone
    }
    Slant {
        anchors.fill: parent
        color: root.active ? Theme.paper : "transparent"
    }

    Row {
        x: 24
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
            color: root.active ? root.tone : "transparent"
            border.width: 2
            border.color: root.active ? root.tone : Theme.paper
            Text {
                anchors.centerIn: parent
                text: root.code
                color: root.active ? Theme.on(root.tone) : Theme.paper
                font {
                    family: "JetBrains Mono"
                    pixelSize: 15
                    weight: Font.ExtraBold
                }
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                text: root.name
                color: root.active ? Theme.ink : Theme.paper
                font {
                    family: "Bebas Neue"
                    pixelSize: 46
                    letterSpacing: 2
                }
                lineHeight: 0.95
            }
            Text {
                text: root.sub
                color: root.active ? Theme.ink : Theme.paper
                opacity: 0.75
                font {
                    family: "JetBrains Mono"
                    pixelSize: 9
                    bold: true
                    letterSpacing: 1.5
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
