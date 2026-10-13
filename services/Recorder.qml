pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Estado de la grabación de pantalla. La fuente de verdad es si wf-recorder está corriendo.
Singleton {
    id: root

    property bool recording: false
    property int secs: 0
    property real startedAt: 0
    readonly property string elapsed: String(Math.floor(secs / 60)).padStart(2, "0") + ":" + String(secs % 60).padStart(2, "0")

    readonly property string script: Quickshell.shellDir + "/scripts/capture.sh"

    // target: "output:NOMBRE" o "X,Y WxH" (coordenadas globales)
    function start(target, audio) {
        if (recording)
            return;
        Quickshell.execDetached([script, "rec-start", target, audio ? "1" : "0"]);
        startedAt = Date.now();
        secs = 0;
        recording = true;
        grace.restart();
    }
    function stop() {
        Quickshell.execDetached([script, "rec-stop"]);
        recording = false;
    }

    // Da tiempo a que wf-recorder arranque antes de comprobarlo
    Timer {
        id: grace
        interval: 1500
    }

    // Cada segundo: ¿sigue grabando? (cubre fallos al arrancar y reinicios del shell)
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!check.running)
                check.running = true;
            if (root.recording)
                root.secs = Math.floor((Date.now() - root.startedAt) / 1000);
        }
    }
    Process {
        id: check
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: code => {
            const running = code === 0;
            if (running && !root.recording) {      // grabación que ya estaba en marcha
                root.startedAt = Date.now();
                root.recording = true;
            } else if (!running && root.recording && !grace.running) {
                root.recording = false;            // terminó o no llegó a arrancar
            }
        }
    }
}
