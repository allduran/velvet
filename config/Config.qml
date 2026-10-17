pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Ajustes de velvet. Se guardan solos en ~/.local/state/velvet/settings.json
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/velvet"

    // ── Globales ──
    property alias animations: store.animations
    property alias adaptiveText: store.adaptiveText      // Contrast.qml
    property alias pins: store.pins                      // { general: [id, id, id, id], ... }
    property alias rankSort: store.rankSort
    property alias notifSecs: store.notifSecs
    property alias shortcutApps: store.shortcutApps      // { terminal: id, browser: id, … } (vacío = del sistema)
    property alias wsApps: store.wsApps                  // { communication: [{ id, name, cls, cmd }], … }
    property alias kbLayouts: store.kbLayouts            // "us,es" ("" = el que tenga Hyprland)
    property alias kbToggle: store.kbToggle              // xkb: grp:alt_shift_toggle…

    // ── Modos (Modes.qml) ──
    property alias customModes: store.customModes        // [{ id, name, style }]
    property alias hiddenModes: store.hiddenModes        // ids de los modos de serie ocultos
    property alias modeLook: store.modeLook              // { id: { gaps, anim, blur, vrr } } (Hyprland)

    // ── Por modo (siempre los del modo activo) ──
    readonly property var m: forMode(Theme.mode)
    readonly property string profile: m.profile ?? "balanced"   // power-saver | balanced | performance
    readonly property int lockMin: m.lock ?? 5                   // 0 = nunca
    readonly property int dpmsMin: m.dpms ?? 10                  // 0 = nunca
    readonly property int sleepMin: m.sleep ?? 0                 // 0 = nunca
    readonly property bool dnd: m.dnd ?? false
    readonly property bool nightLight: m.night ?? true
    readonly property bool gamemode: m.gamemode ?? false
    readonly property var apps: m.apps ?? []                     // [{ id, ws }]

    // Ajustes de cualquier modo: los guardados o, si no hay, los de su estilo
    function forMode(md) {
        return store.perMode[md] ?? defaults[Modes.styleOf(md)];
    }

    // Cambia un valor del modo activo (o de otro modo si se indica)
    function setForMode(key, value, mode) {
        const md = mode ?? Theme.mode;
        const p = JSON.parse(JSON.stringify(store.perMode));
        if (!p[md])
            p[md] = JSON.parse(JSON.stringify(forMode(md)));
        p[md][key] = value;
        store.perMode = p;
    }

    // Cambia varios valores de un modo de golpe (formulario de Administrar modos)
    function setModeSettings(md, values) {
        const p = JSON.parse(JSON.stringify(store.perMode));
        p[md] = Object.assign(JSON.parse(JSON.stringify(forMode(md))), values);
        store.perMode = p;
    }

    // Borra todo lo guardado de un modo propio que se elimina
    function forgetMode(md) {
        const p = JSON.parse(JSON.stringify(store.perMode));
        delete p[md];
        store.perMode = p;
        const pi = JSON.parse(JSON.stringify(store.pins));
        delete pi[md];
        store.pins = pi;
        const l = JSON.parse(JSON.stringify(store.modeLook));
        delete l[md];
        store.modeLook = l;
    }

    readonly property var defaults: ({
            general: {
                profile: "balanced",
                lock: 5,
                dpms: 10,
                sleep: 0,
                dnd: false,
                night: true,
                gamemode: false,
                apps: []
            },
            dev: {
                profile: "balanced",
                lock: 15,
                dpms: 20,
                sleep: 0,
                dnd: false,
                night: true,
                gamemode: false,
                apps: [
                    {
                        id: "code",
                        ws: 1
                    },
                    {
                        id: "unityhub",
                        ws: 2
                    },
                    {
                        id: "foot",
                        ws: 3
                    }
                ]
            },
            art: {
                profile: "performance",
                lock: 20,
                dpms: 30,
                sleep: 0,
                dnd: true,
                night: false,
                gamemode: false,
                apps: [
                    {
                        id: "krita",
                        ws: 1
                    },
                    {
                        id: "zen",
                        ws: 2
                    }
                ]
            },
            game: {
                profile: "performance",
                lock: 0,
                dpms: 0,
                sleep: 0,
                dnd: true,
                night: false,
                gamemode: true,
                apps: [
                    {
                        id: "steam",
                        ws: 1
                    },
                    {
                        id: "vesktop",
                        ws: 2
                    }
                ]
            }
        })

    // Reescribe hypridle.conf con los tiempos del modo activo y reinicia hypridle
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
            property bool animations: true
            property bool adaptiveText: true
            property var pins: ({
                    general: ["zen", "nemo", "komikku", "bitwarden"],
                    dev: ["unityhub", "code", "zen", "obs"],
                    art: ["krita", "blender", "kdenlive", "dolphin"],
                    game: ["steam", "heroic", "vesktop", "obs"]
                })
            property bool rankSort: true
            property int notifSecs: 5
            property var shortcutApps: ({})
            property var wsApps: ({})
            property string kbLayouts: ""
            property string kbToggle: "grp:alt_shift_toggle"
            property var perMode: ({})
            property var customModes: []
            property var hiddenModes: []
            property var modeLook: ({})
        }
    }
}
