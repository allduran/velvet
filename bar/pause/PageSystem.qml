import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import "../../config"
import "../../components"

Column {
    id: root
    spacing: 14

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property real vol: sink?.audio.volume ?? 0
    readonly property bool muted: sink?.audio.muted ?? false
    readonly property var profiles: [
        {
            p: PowerProfile.PowerSaver,
            label: "AHORRO"
        },
        {
            p: PowerProfile.Balanced,
            label: "EQUILIBRADO"
        },
        {
            p: PowerProfile.Performance,
            label: "RENDIMIENTO"
        }
    ]
    PwObjectTracker {
        objects: [root.sink]
    }

    property var monitors: []
    property int screenCount: Quickshell.screens.length
    property bool rescan: false
    onScreenCountChanged: rescan = true      // monitor conectado/desconectado

    Process {
        id: brList
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text);
                } catch (e) {}
            }
        }
    }
    onVisibleChanged: if (visible) {
        brList.command = [Quickshell.shellDir + "/scripts/brightness.sh", "list"].concat(root.rescan ? ["rescan"] : []);
        root.rescan = false;
        brList.running = true;
    }

    property real bright: 0
    onMonitorsChanged: bright = monitors.length ? monitors[0].value / 100 : 0

    Process {
        id: brSet
    }
    // Agrupa los cambios al arrastrar (ddcutil es lento)
    Timer {
        id: brSetT
        interval: 250
        onTriggered: {
            if (brSet.running) {
                restart();
                return;
            }
            brSet.command = [Quickshell.shellDir + "/scripts/brightness.sh", "set", "all", Math.round(root.bright * 100).toString()];
            brSet.running = true;
        }
    }

    Column {
        spacing: 6
        Text {
            text: "VOLUMEN"
            color: Theme.telemetry
            font {
                family: "JetBrains Mono"
                pixelSize: 9
                bold: true
                letterSpacing: 1.5
            }
        }
        Row {
            spacing: 10
            SegBar {
                count: 10
                segW: 10
                segH: 10
                gap: 2
                anchors.verticalCenter: parent.verticalCenter
                value: root.vol
                interactive: true
                fill: root.muted ? Theme.accent : Theme.paper
                onMoved: v => root.sink.audio.volume = v
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.vol * 100) + "%"
                color: Theme.paper
                font {
                    family: "Bebas Neue"
                    pixelSize: 18
                    letterSpacing: 1
                }
            }
            Chip {
                anchors.verticalCenter: parent.verticalCenter
                label: root.muted ? "SILENCIADO" : "SILENCIAR"
                active: root.muted
                onClicked: root.sink.audio.muted = !root.muted
            }
        }
    }

    Column {
        visible: root.monitors.length > 0
        spacing: 6
        Text {
            text: "BRILLO" + (root.monitors.length > 1 ? " · " + root.monitors.length + " PANTALLAS" : "")
            color: Theme.telemetry
            font {
                family: "JetBrains Mono"
                pixelSize: 9
                bold: true
                letterSpacing: 1.5
            }
        }
        Row {
            spacing: 10
            SegBar {
                count: 10
                segW: 10
                segH: 10
                gap: 2
                anchors.verticalCenter: parent.verticalCenter
                value: root.bright
                interactive: true
                onMoved: v => {
                    root.bright = Math.max(0.05, v);
                    brSetT.restart();
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.bright * 100) + "%"
                color: Theme.paper
                font {
                    family: "Bebas Neue"
                    pixelSize: 18
                    letterSpacing: 1
                }
            }
        }
    }

    Column {
        spacing: 6
        Text {
            text: "PERFIL DE ENERGÍA"
            color: Theme.telemetry
            font {
                family: "JetBrains Mono"
                pixelSize: 9
                bold: true
                letterSpacing: 1.5
            }
        }
        Row {
            spacing: 6
            Repeater {
                model: root.profiles
                delegate: Chip {
                    required property var modelData
                    required property int index
                    visible: modelData.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                    label: modelData.label
                    tone: index
                    active: PowerProfiles.profile === modelData.p
                    onClicked: PowerProfiles.profile = modelData.p
                }
            }
        }
    }

    Row {
        spacing: 6
        Chip {
            tone: 1
            label: Networking.wifiEnabled ? "WI-FI · ON" : "WI-FI · OFF"
            active: Networking.wifiEnabled
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
        Chip {
            tone: 2
            visible: root.adapter !== null
            label: root.adapter?.enabled ? "BLUETOOTH · ON" : "BLUETOOTH · OFF"
            active: root.adapter?.enabled ?? false
            onClicked: root.adapter.enabled = !root.adapter.enabled
        }
    }
}
