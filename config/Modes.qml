pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Modos de velvet: los 4 de serie + los que cree el usuario (se guardan en Config).
// El ESTILO de un modo (general/dev/art/game, que se enseñan como Personas/P3/P4/P5)
// decide paleta, fondos, colores de la terminal y el look de Hyprland por defecto.
Singleton {
    id: root

    readonly property int maxShown: 6

    readonly property var styles: [
        {
            id: "general",
            label: "PERSONAS"
        },
        {
            id: "dev",
            label: "PERSONA 3"
        },
        {
            id: "art",
            label: "PERSONA 4"
        },
        {
            id: "game",
            label: "PERSONA 5"
        }
    ]

    readonly property var builtin: [
        {
            id: "general",
            name: "GENERAL",
            style: "general",
            tag: "TODO A LA VEZ · LA TRÍADA",
            builtin: true
        },
        {
            id: "dev",
            name: "DEV",
            style: "dev",
            tag: "CÓDIGO · UNITY · DEVLOG",
            builtin: true
        },
        {
            id: "art",
            name: "ART",
            style: "art",
            tag: "PINTURA · 3D · VÍDEO",
            builtin: true
        },
        {
            id: "game",
            name: "GAME",
            style: "game",
            tag: "STEAM · HEROIC · CHAT",
            builtin: true
        }
    ]

    // Look de Hyprland por estilo (si el modo no tiene uno propio en Config.modeLook)
    // gaps: normal | compact | none · vrr: 0 no, 1 siempre, 2 solo pantalla completa
    readonly property var lookDefaults: ({
            general: {
                gaps: "normal",
                anim: true,
                blur: true,
                vrr: 0
            },
            dev: {
                gaps: "compact",
                anim: true,
                blur: true,
                vrr: 0
            },
            art: {
                gaps: "normal",
                anim: true,
                blur: true,
                vrr: 0
            },
            game: {
                gaps: "none",
                anim: false,
                blur: false,
                vrr: 2
            }
        })
    readonly property var gapsPx: ({
            normal: [5, 10],
            compact: [3, 6],
            none: [0, 0]
        })

    // Todos: los de serie y luego los propios, en el orden en que se crearon
    readonly property var all: builtin.concat((Config.customModes ?? []).map(c => ({
                id: c.id,
                name: c.name,
                style: c.style,
                tag: "MODO PROPIO · " + styleLabel(c.style),
                builtin: false
            })))
    // Los que salen en el selector
    readonly property var shown: all.filter(m => !(Config.hiddenModes ?? []).includes(m.id))

    // Se emite al guardar el modo activo: ModeApply vuelve a aplicar energía, idle, etc.
    signal activeEdited

    function get(id) {
        return all.find(m => m.id === id) ?? null;
    }
    function exists(id) {
        return get(id) !== null;
    }
    function styleOf(id) {
        return get(id)?.style ?? "general";
    }
    function nameOf(id) {
        return get(id)?.name ?? String(id).toUpperCase();
    }
    function styleLabel(style) {
        return styles.find(s => s.id === style)?.label ?? "PERSONAS";
    }
    function look(id) {
        return Object.assign({}, lookDefaults[styleOf(id)], (Config.modeLook ?? {})[id] ?? {});
    }

    // ── Ocultar / mostrar (de serie) y borrar (propios) ──
    // Devuelven "" si fue bien o el motivo para avisar
    function hide(id) {
        if (shown.length <= 1)
            return "DEBE QUEDAR AL MENOS UN MODO";
        Config.hiddenModes = (Config.hiddenModes ?? []).concat([id]);
        leaveIfActive(id);
        return "";
    }
    function unhide(id) {
        if (shown.length >= maxShown)
            return "MÁXIMO " + maxShown + " MODOS EN EL SELECTOR";
        Config.hiddenModes = (Config.hiddenModes ?? []).filter(x => x !== id);
        return "";
    }
    function remove(id) {
        const m = get(id);
        if (!m || m.builtin)
            return "LOS MODOS DE SERIE SOLO SE OCULTAN";
        if (shown.length <= 1 && shown[0].id === id)
            return "DEBE QUEDAR AL MENOS UN MODO";
        leaveIfActive(id);
        Config.customModes = Config.customModes.filter(c => c.id !== id);
        Config.hiddenModes = (Config.hiddenModes ?? []).filter(x => x !== id);
        Config.forgetMode(id);
        return "";
    }
    // Si el modo que desaparece es el activo, pasa al primero que quede
    function leaveIfActive(id) {
        if (Theme.mode !== id)
            return;
        const next = shown.find(m => m.id !== id);
        if (next)
            Theme.setMode(next.id);
    }

    // ── Crear / editar ──
    // id "" = nuevo. data: { name, style, look: {gaps, anim, blur, vrr}, settings: {profile, lock, dpms, dnd, night, gamemode} }
    // Devuelve { id, error }
    function save(id, data) {
        const name = (data.name ?? "").trim().toUpperCase().slice(0, 10);
        let md = id;
        if (!md) {
            if (!name)
                return {
                    id: "",
                    error: "PONLE NOMBRE AL MODO"
                };
            if (shown.length >= maxShown)
                return {
                    id: "",
                    error: "MÁXIMO " + maxShown + " MODOS EN EL SELECTOR"
                };
            md = slug(name);
            Config.customModes = (Config.customModes ?? []).concat([
                {
                    id: md,
                    name: name,
                    style: data.style
                }
            ]);
        } else if (!get(md)?.builtin) {
            if (!name)
                return {
                    id: md,
                    error: "PONLE NOMBRE AL MODO"
                };
            Config.customModes = Config.customModes.map(c => c.id === md ? {
                    id: md,
                    name: name,
                    style: data.style
                } : c);
        }

        const lk = JSON.parse(JSON.stringify(Config.modeLook ?? {}));
        lk[md] = data.look;
        Config.modeLook = lk;
        Config.setModeSettings(md, data.settings);

        if (md === Theme.mode) {
            writeLook();
            hyprReload.restart();
            activeEdited();
        }
        return {
            id: md,
            error: ""
        };
    }

    // "Mi Estudio" → "miestudio" (sin repetir ni pisar uno de serie)
    function slug(name) {
        const base = name.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-z0-9]/g, "") || "modo";
        let s = base, i = 2;
        while (exists(s))
            s = base + i++;
        return s;
    }

    // ── Look de Hyprland del modo activo → ~/.local/state/velvet/look (lo lee hypr/shell.lua) ──
    FileView {
        id: lookFile
        path: Quickshell.env("HOME") + "/.local/state/velvet/look"
        printErrors: false
    }
    function writeLook() {
        const md = Theme.mode;
        const l = look(md);
        const g = gapsPx[l.gaps] ?? gapsPx.normal;
        lookFile.setText(["mode=" + md, "style=" + styleOf(md), "gapsIn=" + g[0], "gapsOut=" + g[1], "animations=" + (l.anim ? 1 : 0), "blur=" + (l.blur ? 1 : 0), "vrr=" + l.vrr].join("\n") + "\n");
    }
    Timer {
        id: hyprReload
        interval: 300
        onTriggered: Quickshell.execDetached(["hyprctl", "reload"])
    }
}
