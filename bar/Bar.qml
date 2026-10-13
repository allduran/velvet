import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../config"
import "../services"

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    color: "transparent"
    implicitHeight: 40 + 8          // island height + top margin
    exclusiveZone: implicitHeight   // windows tile below the bar

    // ── Placa izquierda: desde (0,0) hasta pasado el título ──
    Shape {
        id: leftPlate
        readonly property real slant: 16
        readonly property real w: row.x + (aw.visible ? aw.x + aw.width : ws.x + ws.width) + 18
        anchors {
            left: parent.left
            top: parent.top
        }
        width: w + slant
        height: bar.implicitHeight
        preferredRendererType: Shape.CurveRenderer
        opacity: Contrast.busy(bar.modelData.name, "left") ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        ShapePath {
            fillColor: Qt.alpha(Theme.ink, 0.72)
            strokeColor: "transparent"
            startX: 0
            startY: 0
            PathLine {
                x: leftPlate.w + leftPlate.slant
                y: 0
            }
            PathLine {
                x: leftPlate.w
                y: leftPlate.height
            }
            PathLine {
                x: 0
                y: leftPlate.height
            }
            PathLine {
                x: 0
                y: 0
            }
        }
    }

    RowLayout {
        id: row
        anchors {
            fill: parent
            topMargin: 8
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 8

        Workspaces {
            id: ws
            monitor: Hyprland.monitorFor(bar.modelData)
            light: Contrast.light(bar.modelData.name, "left")
        }
        ActiveWindow {
            id: aw
            light: Contrast.light(bar.modelData.name, "left")
        }

        Item {
            Layout.fillWidth: true
        }   // spacer
    }

    // Isla central, centrada en la pantalla
    Media {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 8
        light: Contrast.light(bar.modelData.name, "center")
        plate: Contrast.busy(bar.modelData.name, "center")
    }
}
