import QtQuick
import "../config"

// Título grande flotante: sombra de color + contorno oscuro para leerse sobre cualquier fondo
Item {
    id: title
    property string text
    property color shadow: Theme.accent
    implicitWidth: main.implicitWidth + 5
    implicitHeight: main.implicitHeight + 5

    Text {
        x: 5
        y: 5
        text: title.text
        color: title.shadow
        font: main.font
    }
    Text {
        id: main
        text: title.text
        color: Theme.paper
        style: Text.Outline
        styleColor: Theme.ink
        font.family: "Bebas Neue"
        font.pixelSize: 84
        font.letterSpacing: 4
    }
}
