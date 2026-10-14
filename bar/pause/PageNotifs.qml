import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import "../../config"
import "../../services"

Column {
    id: root
    spacing: 2
    signal done

    Row {
        spacing: 6
        bottomPadding: 8
        Chip {
            tone: 1
            label: Notifs.dnd ? "NO MOLESTAR · ON" : "NO MOLESTAR · OFF"
            active: Notifs.dnd
            onClicked: Config.dnd = !Config.dnd
        }
        Chip {
            label: "LIMPIAR TODO"
            active: false
            onClicked: Notifs.clearAll()
        }
    }

    Text {
        visible: Notifs.all.length === 0
        text: "SIN AVISOS"
        color: Theme.telemetry
        font {
            family: "JetBrains Mono"
            pixelSize: 9
            bold: true
            letterSpacing: 1.5
        }
    }

    Repeater {
        model: ScriptModel {
            values: Notifs.all.slice().reverse()
        }
        delegate: PauseRow {
            required property var modelData
            iconSource: modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : ""
            label: (modelData.summary || modelData.appName).toUpperCase()
            meta: (modelData.appName || "").toUpperCase()
            danger: modelData.urgency === NotificationUrgency.Critical
            onClicked: {
                const d = modelData.actions.find(a => a.identifier === "default");
                if (d) {
                    d.invoke();
                    root.done();
                }
            }
            onRightClicked: modelData.dismiss()
        }
    }

    Text {
        visible: Notifs.all.length > 0
        topPadding: 6
        text: "CLIC: ABRIR · CLIC DCHO: DESCARTAR"
        color: Theme.telemetry
        font {
            family: "JetBrains Mono"
            pixelSize: 8
            bold: true
            letterSpacing: 1.2
        }
    }
}
