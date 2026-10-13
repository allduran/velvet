import Quickshell
import Quickshell.Bluetooth
import QtQuick
import "../../config"

Column {
    id: root
    spacing: 2

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    Binding {
        target: root.adapter
        property: "discovering"
        value: root.visible && root.on
        when: root.adapter !== null
    }

    Repeater {
        model: ScriptModel {
            values: root.on ? Array.from(root.adapter.devices.values).filter(d => d.name).sort((a, b) => b.connected - a.connected || b.paired - a.paired).slice(0, 7) : []
        }
        delegate: PauseRow {
            required property var modelData
            marked: modelData.connected
            iconSource: Quickshell.iconPath(modelData.icon)
            label: modelData.name
            meta: (modelData.connected ? "CONECTADO" : modelData.paired ? "EMPAREJADO" : "NUEVO") + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
            onClicked: {
                if (modelData.connected)
                    modelData.disconnect();
                else if (modelData.paired)
                    modelData.connect();
                else {
                    modelData.trusted = true;
                    modelData.pair();
                }
            }
        }
    }

    Text {
        topPadding: 6
        text: root.on ? "BUSCANDO DISPOSITIVOS…" : "BLUETOOTH APAGADO"
        color: Theme.telemetry
        font {
            family: "JetBrains Mono"
            pixelSize: 9
            bold: true
            letterSpacing: 1.5
        }
    }
}
