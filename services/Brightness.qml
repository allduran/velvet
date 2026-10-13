pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Brillo de todas las pantallas a la vez vía scripts/brightness.sh
Singleton {
    id: root

    property real value: 0.5      // 0–1 (el primer monitor de la lista manda)
    property var monitors: []

    function refresh(rescan) {
        list.command = [Quickshell.shellDir + "/scripts/brightness.sh", "list"].concat(rescan ? ["rescan"] : []);
        list.running = true;
    }
    function set(v) {
        value = Math.max(0.05, Math.min(1, v));
        apply.restart();
    }
    function step(d) {
        set(value + d);
    }

    Component.onCompleted: refresh(false)

    Process {
        id: list
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text);
                    if (root.monitors.length)
                        root.value = root.monitors[0].value / 100;
                } catch (e) {}
            }
        }
    }

    Process {
        id: setter
    }
    // Agrupa pulsaciones seguidas (ddcutil es lento)
    Timer {
        id: apply
        interval: 200
        onTriggered: {
            if (setter.running) {
                restart();
                return;
            }
            setter.command = [Quickshell.shellDir + "/scripts/brightness.sh", "set", "all", Math.round(root.value * 100).toString()];
            setter.running = true;
        }
    }
}
