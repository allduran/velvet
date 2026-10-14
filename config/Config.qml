pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Ajustes de velvet. Se guardan solos en ~/.local/state/velvet/settings.json
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/velvet"

    // Apariencia
    property alias panelOpacity: store.panelOpacity     // 0.1–1 (paso 3: lo leerán los paneles)
    property alias animations: store.animations          // paso 3
    property alias adaptiveText: store.adaptiveText      // Contrast.qml
    // Lanzador
    property alias pins: store.pins                      // { general: [id, id, id, id], ... }
    property alias rankSort: store.rankSort
    // Energía (hypridle)
    property alias lockMin: store.lockMin
    property alias dpmsMin: store.dpmsMin
    property alias sleepMin: store.sleepMin              // 0 = nunca
    // Notificaciones (paso 2)
    property alias dnd: store.dnd
    property alias notifSecs: store.notifSecs

    // Reescribe hypridle.conf con los tiempos actuales y reinicia hypridle
    function applyIdle() {
        Quickshell.execDetached(["sh", Quickshell.shellDir + "/scripts/idle.sh", String(lockMin), String(dpmsMin), String(sleepMin)]);
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    FileView {
        path: root.dir + "/settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store
            property real panelOpacity: 0.95
            property bool animations: true
            property bool adaptiveText: true
            property var pins: ({
                    general: ["zen", "nemo", "komikku", "bitwarden"],
                    dev: ["unityhub", "code", "zen", "obs"],
                    art: ["krita", "blender", "kdenlive", "dolphin"],
                    game: ["steam", "heroic", "vesktop", "obs"]
                })
            property bool rankSort: true
            property int lockMin: 5
            property int dpmsMin: 10
            property int sleepMin: 0
            property bool dnd: false
            property int notifSecs: 5
        }
    }
}
