import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../config"
import "../components"

Island {
    id: root
    property HyprlandMonitor monitor
    property bool light: false   // fondo claro detrás → tinta oscura
    readonly property color fg: light ? Theme.ink : Theme.paper
    readonly property color bg: light ? Theme.paper : Theme.ink
    readonly property int focusedId: Math.max(1, monitor?.activeWorkspace?.id ?? 1)
    readonly property int start: Math.max(1, focusedId - 4)
    padding: 8

    Repeater {
        model: 5
        delegate: Item {
            id: ws
            required property int index
            readonly property int wsId: root.start + index
            readonly property bool active: root.monitor?.activeWorkspace?.id === wsId
            readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)

            anchors.verticalCenter: parent.verticalCenter
            width: active ? 34 : 22
            height: 20
            Behavior on width {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                antialiasing: true
                color: ws.active ? root.fg : ws.occupied ? Qt.alpha(root.fg, 0.12) : "transparent"
                border.width: ws.active ? 0 : 1
                border.color: Qt.alpha(root.fg, ws.occupied ? 0.35 : 0.15)
                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, -0.14, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

                // Filo de acento en el activo
                Rectangle {
                    visible: ws.active
                    width: 2
                    height: parent.height
                    color: Theme.accent
                    antialiasing: true
                }
            }

            Text {
                anchors.centerIn: parent
                text: ws.wsId.toString().padStart(2, "0")
                color: ws.active ? root.bg : Qt.alpha(root.fg, ws.occupied ? 0.9 : 0.4)
                font {
                    family: "JetBrains Mono"
                    pixelSize: 11
                    bold: true
                    letterSpacing: 1
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = "${ws.wsId}" })`)
            }
        }
    }
}
