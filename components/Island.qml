import QtQuick
import "../config"

Item {
    id: root
    default property alias content: row.data
    property int padding: 12
    property alias spacing: row.spacing

    // Placa oscura detrás cuando el fondo es muy variado (la decide Contrast)
    property bool plate: false
    readonly property int platePad: Math.max(0, 10 - padding)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: 40

    Rectangle {
        id: plateRect
        x: -root.platePad
        width: root.width + root.platePad * 2
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.alpha(Theme.ink, 0.72)
        antialiasing: true
        opacity: root.plate ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        transform: Matrix4x4 {
            matrix: Qt.matrix4x4(1, -0.2, 0, 0.2 * plateRect.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
}
