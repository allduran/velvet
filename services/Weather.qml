pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tiempo actual vía wttr.in (sin API key). city vacío = ubicación por IP.
Singleton {
    id: root

    property string city: ""
    property string condition: ""   // "Parcialmente nublado"
    property int temp: 0            // °C
    property bool ready: false

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    Process {
        id: proc
        command: ["curl", "-sf", "--max-time", "8", "https://wttr.in/" + encodeURIComponent(root.city) + "?format=j1&lang=es"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const cur = JSON.parse(text).current_condition[0];
                    const es = cur.lang_es && cur.lang_es[0] ? cur.lang_es[0].value : cur.weatherDesc[0].value;
                    root.condition = es.trim().replace(/\s+/g, " ");
                    root.temp = parseInt(cur.temp_C);
                    root.ready = true;
                } catch (e) {
                    // sin red o respuesta rara: se mantiene el último dato
                }
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
