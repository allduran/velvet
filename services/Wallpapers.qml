pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Fondos de ~/Pictures/Wallpapers con nombre wallpaper-<color>-<n>.<jpg|jpeg|png>
// Cada modo guarda el suyo en ~/.local/state/velvet/wallpapers.json
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    // Color permitido por ESTILO ("" = todos). Sale de trio[0] de cada paleta en Theme.
    readonly property var modeColor: ({
            general: "",
            dev: "blue",
            art: "yellow",
            game: "red"
        })
    readonly property var colorOrder: ["red", "blue", "yellow"]

    property var all: []   // [{ path, name, color, num }]

    // filter: "all" | "red" | "blue" | "yellow" (solo cuenta en general)
    function forMode(mode, filter) {
        const c = modeColor[Modes.styleOf(mode)] || (filter && filter !== "all" ? filter : "");
        return c ? all.filter(w => w.color === c) : all;
    }

    // Fondo efectivo de cualquier modo (el guardado si es válido, si no el primero permitido)
    readonly property var builtinIds: ["general", "dev", "art", "game"]
    function saved(m) {
        return builtinIds.includes(m) ? store[m] : (store.custom[m] ?? "");
    }

    function currentFor(m) {
        const saved = root.saved(m);
        const allowed = forMode(m, "all");
        if (allowed.some(w => w.path === saved))
            return saved;
        return allowed.length ? allowed[0].path : "";
    }

    // Fondo efectivo del modo actual: el guardado si es válido, si no el primero permitido
    readonly property string current: currentFor(Theme.mode)

    function set(path) {
        if (builtinIds.includes(Theme.mode)) {
            store[Theme.mode] = path;   // JsonAdapter → se escribe solo
        } else {
            const c = JSON.parse(JSON.stringify(store.custom));
            c[Theme.mode] = path;
            store.custom = c;
        }
    }

    function refresh() {
        if (!ls.running)
            ls.running = true;
    }

    Process {
        id: ls
        command: ["ls", "-1", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const re = /^wallpaper-(red|blue|yellow)-(\d+)\.(jpe?g|png)$/i;
                const out = [];
                for (const raw of text.split("\n")) {
                    const name = raw.trim();
                    const m = name.match(re);
                    if (!m)
                        continue;
                    out.push({
                        path: root.dir + "/" + name,
                        name: name.replace(/\.[^.]+$/, ""),
                        color: m[1].toLowerCase(),
                        num: parseInt(m[2])
                    });
                }
                out.sort((a, b) => root.colorOrder.indexOf(a.color) - root.colorOrder.indexOf(b.color) || a.num - b.num);
                root.all = out;
            }
        }
    }

    Component.onCompleted: refresh()

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/velvet/wallpapers.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store
            property string general: ""
            property string dev: ""
            property string art: ""
            property string game: ""
            property var custom: ({})   // modos propios: { id: ruta }
        }
    }
}
