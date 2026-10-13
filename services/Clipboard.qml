pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Historial del portapapeles vía cliphist (lo alimenta 'wl-paste --watch cliphist store')
Singleton {
    id: root

    property var entries: []        // [{ id, line, kind, preview, info }]
    property string fullText: ""     // texto completo de la entrada elegida
    property string imagePath: ""    // miniatura de la entrada elegida (si es imagen)
    readonly property string thumb: Quickshell.env("XDG_RUNTIME_DIR") + "/velvet-clip.png"

    function refresh() {
        if (!list.running)
            list.running = true;
    }

    function load(entry) {
        fullText = "";
        imagePath = "";
        if (!entry)
            return;
        if (entry.kind === "IMAGEN") {
            img.command = ["sh", "-c", "cliphist decode \"$1\" > \"$2\"", "sh", entry.id, root.thumb];
            img.running = true;
        } else {
            txt.command = ["cliphist", "decode", entry.id];
            txt.running = true;
        }
    }
    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entry.id]);
    }
    // Copia y pega con Ctrl+V en la ventana que recupera el foco
    function paste(entry) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy && sleep 0.15 && wtype -M ctrl v -m ctrl", "sh", entry.id]);
    }
    function remove(entry) {
        del.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", entry.line];
        del.running = true;
    }
    function wipe() {
        del.command = ["cliphist", "wipe"];
        del.running = true;
    }

    function classify(preview) {
        if (preview.startsWith("[[ binary data"))
            return "IMAGEN";
        if (/^https?:\/\//.test(preview))
            return "ENLACE";
        if (/[{};]|=>|::|\(\)|^\s*(import|const|let|var|def|function|class|#include)\b/.test(preview))
            return "CÓDIGO";
        return "TEXTO";
    }

    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l.includes("\t")).map(l => {
                    const tab = l.indexOf("\t");
                    const preview = l.slice(tab + 1);
                    const kind = root.classify(preview);
                    let info = "";
                    if (kind === "IMAGEN") {
                        const m = preview.match(/(\w+)\s+(\d+x\d+)/);
                        info = m ? m[1].toUpperCase() + " " + m[2].replace("x", " × ") : "IMAGEN";
                    }
                    return {
                        id: l.slice(0, tab),
                        line: l,
                        kind: kind,
                        preview: kind === "IMAGEN" ? info : preview,
                        info: info
                    };
                });
            }
        }
    }
    Process {
        id: txt
        stdout: StdioCollector {
            onStreamFinished: root.fullText = text
        }
    }
    Process {
        id: img
        onExited: root.imagePath = "file://" + root.thumb + "?" + Date.now()
    }
    Process {
        id: del
        onExited: root.refresh()
    }
}
