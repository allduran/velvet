pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Atajos de velvet (Ajustes → 06 ATAJOS)
//  · Apps: Hyprland llama a `duran ipc app <hueco>` y velvet abre la app elegida
//          (o la predeterminada del sistema si no se ha elegido ninguna).
//  · Workspaces especiales: se escribe ~/.config/hypr/toggles.json, que
//          utils/functions.lua lee en cada pulsación (sin recargar Hyprland).
//  · Teclado: ~/.local/state/velvet/keyboard, que lee hypr/shell.lua al recargar.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // ── Apps ──
    readonly property var slots: [
        {
            id: "terminal",
            name: "TERMINAL",
            combo: "SUPER + T",
            mime: "",
            cat: "TerminalEmulator",
            fallback: ["foot", "kitty", "Alacritty", "org.kde.konsole", "org.gnome.Console"]
        },
        {
            id: "browser",
            name: "NAVEGADOR",
            combo: "SUPER + W",
            mime: "x-scheme-handler/https",
            cat: "WebBrowser",
            fallback: ["zen", "firefox", "vivaldi-stable", "chromium", "brave-browser"]
        },
        {
            id: "editor",
            name: "EDITOR",
            combo: "SUPER + C",
            mime: "text/plain",
            cat: "TextEditor",
            fallback: ["codium", "code", "org.kde.kate", "org.kde.kwrite", "org.gnome.TextEditor"]
        },
        {
            id: "files",
            name: "ARCHIVOS",
            combo: "SUPER + E",
            mime: "inode/directory",
            cat: "FileManager",
            fallback: ["nemo", "org.kde.dolphin", "org.gnome.Nautilus", "thunar", "pcmanfm-qt"]
        },
        {
            id: "audio",
            name: "AJUSTES DE AUDIO",
            combo: "CTRL + ALT + V",
            mime: "",
            cat: "Mixer",
            fallback: ["com.saivert.pwvucontrol", "pavucontrol", "org.pulseaudio.pavucontrol"]
        }
    ]

    // ── Workspaces especiales (los mismos que define utils/functions.lua) ──
    readonly property var spaces: [
        {
            id: "communication",
            name: "COMUNICACIÓN",
            combo: "SUPER + D",
            builtin: [
                {
                    key: "whatsapp",
                    name: "WhatsApp",
                    cls: "FFPWA-01M48T68KH03YDWT8DKA8M2G4Y"
                },
                {
                    key: "discord",
                    name: "Discord",
                    cls: "discord",
                    off: true
                }
            ]
        },
        {
            id: "music",
            name: "MÚSICA",
            combo: "SUPER + M",
            builtin: [
                {
                    key: "spotify",
                    name: "Spotify",
                    cls: "Spotify"
                },
                {
                    key: "feishin",
                    name: "Feishin",
                    cls: "feishin"
                }
            ]
        },
        {
            id: "todo",
            name: "TAREAS",
            combo: "SUPER + R",
            builtin: []
        },
        {
            id: "sysmon",
            name: "MONITOR",
            combo: "CTRL + SHIFT + ESC",
            builtin: [
                {
                    key: "btop",
                    name: "btop",
                    cls: "btop"
                }
            ]
        }
    ]

    // ── Teclado ──
    readonly property var layouts: [
        {
            code: "es",
            name: "ESPAÑOL"
        },
        {
            code: "us",
            name: "INGLÉS EE. UU."
        },
        {
            code: "latam",
            name: "LATINOAMERICANO"
        },
        {
            code: "gb",
            name: "INGLÉS R. U."
        },
        {
            code: "fr",
            name: "FRANCÉS"
        },
        {
            code: "de",
            name: "ALEMÁN"
        },
        {
            code: "it",
            name: "ITALIANO"
        },
        {
            code: "pt",
            name: "PORTUGUÉS"
        }
    ]
    readonly property var toggles: [
        {
            label: "ALT + SHIFT",
            value: "grp:alt_shift_toggle"
        },
        {
            label: "SUPER + ESPACIO",
            value: "grp:win_space_toggle"
        },
        {
            label: "CTRL + SHIFT",
            value: "grp:ctrl_shift_toggle"
        }
    ]

    // ═════════ Entradas de escritorio ═════════
    function entry(id) {
        if (!id)
            return null;
        const clean = id.replace(/\.desktop$/, "");
        return DesktopEntries.byId(clean) ?? DesktopEntries.applications.values.find(e => e.id.toLowerCase() === clean.toLowerCase()) ?? null;
    }

    // Predeterminadas del sistema (xdg-mime), se leen al arrancar
    property var xdg: ({})
    Process {
        id: xdgQuery
        running: true
        command: ["sh", "-c", "for m in x-scheme-handler/https text/plain inode/directory; do printf '%s=%s\\n' \"$m\" \"$(xdg-mime query default \"$m\" 2>/dev/null)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0 && line.slice(i + 1).trim())
                        out[line.slice(0, i)] = line.slice(i + 1).trim();
                }
                root.xdg = out;
            }
        }
    }

    function autoEntry(slot) {
        const s = slots.find(x => x.id === slot);
        if (!s)
            return null;
        const fromXdg = s.mime ? entry(xdg[s.mime]) : null;
        if (fromXdg)
            return fromXdg;
        for (const id of s.fallback) {
            const e = entry(id);
            if (e)
                return e;
        }
        return DesktopEntries.applications.values.find(e => !e.noDisplay && (e.categories || []).includes(s.cat)) ?? null;
    }
    function chosen(slot) {
        return entry(Config.shortcutApps[slot] ?? "");
    }
    function entryFor(slot) {
        return chosen(slot) ?? autoEntry(slot);
    }

    function setApp(slot, id) {
        const p = JSON.parse(JSON.stringify(Config.shortcutApps));
        if (id)
            p[slot] = id;
        else
            delete p[slot];
        Config.shortcutApps = p;
    }

    // duran ipc app <hueco>
    function launch(slot) {
        const e = entryFor(slot);
        if (e)
            e.execute();
        else
            Quickshell.execDetached(["notify-send", "-a", "velvet", "Sin app para " + slot, "Elige una en Ajustes → Atajos"]);
    }

    // ═════════ Workspaces ═════════
    // Lista que se muestra: la elegida en Ajustes o, si no se ha tocado, la de functions.lua
    function wsList(ws) {
        const own = Config.wsApps[ws];
        if (own)
            return own;
        const sp = spaces.find(x => x.id === ws);
        return sp ? sp.builtin.filter(b => !b.off).map(b => ({
                    id: b.key,
                    name: b.name,
                    cls: b.cls,
                    builtin: b.key
                })) : [];
    }

    function fromEntry(e) {
        const term = e.runInTerminal ?? false;
        return {
            id: e.id,
            name: e.name,
            icon: e.icon ?? "",
            cls: term ? e.id : (e.startupClass || e.id),
            cmd: (term ? ["foot", "-a", e.id, "-e"].concat(e.command) : e.command).filter(a => !/=$/.test(a))   // quita "--uri=" y similares (restos de %U)
        };
    }

    function addToWs(ws, e) {
        const p = JSON.parse(JSON.stringify(Config.wsApps));
        const list = wsList(ws).slice();
        if (list.some(a => a.id === e.id))
            return;
        list.push(fromEntry(e));
        p[ws] = list;
        Config.wsApps = p;
        writeToggles();
    }
    function removeFromWs(ws, id) {
        const p = JSON.parse(JSON.stringify(Config.wsApps));
        p[ws] = wsList(ws).filter(a => a.id !== id);
        Config.wsApps = p;
        writeToggles();
    }

    FileView {
        id: togglesFile
        path: root.home + "/.config/hypr/toggles.json"
        printErrors: false
    }

    // Reescribe solo los workspaces tocados en Ajustes; el resto del archivo se respeta
    function writeToggles() {
        let doc = {};
        try {
            doc = JSON.parse(togglesFile.text() || "{}") ?? {};
        } catch (err) {
            doc = {};
        }
        doc.toggles = doc.toggles ?? {};
        for (const sp of spaces) {
            const list = Config.wsApps[sp.id];
            if (!list)
                continue;
            const cat = {};
            for (const b of sp.builtin)
                cat[b.key] = {
                    enable: list.some(a => a.builtin === b.key)
                };
            for (const a of list) {
                if (a.builtin)
                    continue;
                cat["velvet_" + a.id.replace(/[^A-Za-z0-9_]/g, "_")] = {
                    enable: true,
                    match: [
                        {
                            class: a.cls
                        }
                    ],
                    command: a.cmd,
                    move: true
                };
            }
            doc.toggles[sp.id] = cat;
        }
        togglesFile.setText(JSON.stringify(doc, null, 2) + "\n");
    }

    // ═════════ Teclado ═════════
    // Lo que usa Hyprland ahora mismo (para mostrarlo antes de tocar nada)
    property string detected: ""
    Process {
        id: kbQuery
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards ?? [];
                    const main = kbs.find(k => k.main) ?? kbs[0];
                    root.detected = main?.layout ?? "";
                } catch (err) {}
            }
        }
    }
    readonly property var activeLayouts: (Config.kbLayouts || detected || "us").split(",").map(s => s.trim()).filter(s => s)

    function layoutName(code) {
        return layouts.find(l => l.code === code)?.name ?? code.toUpperCase();
    }

    // Pulsar un idioma: lo añade al final o, si ya estaba (y no es el único), lo quita
    function toggleLayout(code) {
        let list = activeLayouts.slice();
        if (list.includes(code)) {
            if (list.length === 1)
                return;
            list = list.filter(c => c !== code);
        } else {
            if (list.length >= 3)
                return;
            list.push(code);
        }
        Config.kbLayouts = list.join(",");
        applyKeyboard();
    }
    function setToggle(v) {
        Config.kbToggle = v;
        applyKeyboard();
    }

    FileView {
        id: kbFile
        path: root.home + "/.local/state/velvet/keyboard"
        printErrors: false
    }
    Timer {
        id: reloadT
        interval: 400
        onTriggered: Quickshell.execDetached(["hyprctl", "reload"])
    }
    function applyKeyboard() {
        const list = activeLayouts;
        const opts = list.length > 1 ? Config.kbToggle : "";
        kbFile.setText("layouts=" + list.join(",") + "\noptions=" + opts + "\n");
        reloadT.restart();
    }
}
