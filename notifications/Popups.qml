import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../config"
import "../components"
import "../services"

PanelWindow {
    id: win
    readonly property bool focused: Hyprland.focusedMonitor?.name === screen?.name
    visible: focused && Notifs.popups.length > 0 && Ui.cornerScreen !== screen?.name

    anchors {
        top: true
        right: true
    }
    margins {
        top: 12
        right: 16
    }          // ya respeta el hueco de la barra
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "velvet-notifs"
    color: "transparent"
    implicitWidth: 520
    implicitHeight: Math.max(1, col.implicitHeight + 20)
    mask: Region {
        item: col
    }

    Column {
        id: col
        anchors {
            top: parent.top
            right: parent.right
        }
        spacing: 16

        Repeater {
            model: ScriptModel {
                values: Notifs.popups.slice(0, 3)
            }
            delegate: Bubble {
                required property var modelData
                required property int index
                n: modelData
                order: index
                anchors.right: parent.right
                anchors.rightMargin: 8 + index * 18
            }
        }

        // Más de 3: aviso hacia el historial
        Item {
            visible: Notifs.popups.length > 3
            anchors.right: parent.right
            anchors.rightMargin: 8 + 3 * 18
            width: moreT.implicitWidth + 24
            height: 22
            Slant {
                anchors.fill: parent
                color: Theme.paper
            }
            Text {
                id: moreT
                anchors.centerIn: parent
                text: "+" + (Notifs.popups.length - 3) + " MÁS EN EL MENÚ // AVISOS"
                color: Theme.ink
                font {
                    family: "JetBrains Mono"
                    pixelSize: 10
                    weight: Font.ExtraBold
                    letterSpacing: 1
                }
            }
        }
    }
}
