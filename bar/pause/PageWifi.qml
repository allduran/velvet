import Quickshell
import Quickshell.Networking
import QtQuick
import "../../config"

Column {
    id: root
    spacing: 2
    signal done

    readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    Binding {
        target: root.dev
        property: "scannerEnabled"
        value: root.visible
        when: root.dev !== null
    }

    Repeater {
        model: ScriptModel {
            values: root.dev ? Array.from(root.dev.networks.values).sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength).slice(0, 7) : []
        }
        delegate: PauseRow {
            required property var modelData
            readonly property int bars: Math.min(3, Math.floor(modelData.signalStrength * 4))
            marked: modelData.connected
            label: modelData.name
            meta: "▂▄▆█".slice(0, bars + 1) + (modelData.connected ? " · CONECTADA" : modelData.known ? " · GUARDADA" : "")
            onClicked: {
                if (modelData.connected)
                    modelData.disconnect();
                else if (modelData.known)
                    modelData.connect();
                else {
                    root.done();
                    Quickshell.execDetached(["foot", "-e", "nmcli", "--ask", "device", "wifi", "connect", modelData.name]);
                }
            }
        }
    }

    Text {
        topPadding: 6
        text: Networking.wifiEnabled ? "BUSCANDO REDES…" : "WI-FI APAGADO"
        color: Theme.telemetry
        font {
            family: "JetBrains Mono"
            pixelSize: 9
            bold: true
            letterSpacing: 1.5
        }
    }
}
