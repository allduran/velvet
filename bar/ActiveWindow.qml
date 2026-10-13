import Quickshell
import Quickshell.Wayland
import QtQuick
import "../config"
import "../components"

Island {
    id: root
    padding: 0
    property bool light: false   // fondo claro detrás → tinta oscura
    readonly property var win: ToplevelManager.activeToplevel
    visible: win !== null

    // Cuña de acento
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 16
        color: Theme.accent2
        antialiasing: true
        transform: Matrix4x4 {
            matrix: Qt.matrix4x4(1, -0.21, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        }
    }

    // App (p. ej. "org.kde.dolphin" → "DOLPHIN")
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: (root.win?.appId ?? "").split(".").pop().toUpperCase()
        color: root.light ? Qt.alpha(Theme.ink, 0.7) : Theme.telemetry
        font {
            family: "JetBrains Mono"
            pixelSize: 10
            bold: true
            letterSpacing: 1.2
        }
    }

    // Título, truncado a 360px
    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 360)
        elide: Text.ElideRight
        text: root.win?.title ?? ""
        color: root.light ? Theme.ink : Theme.paper
        font {
            family: "Montserrat"
            pixelSize: 12
            weight: Font.Medium
        }
    }
}
