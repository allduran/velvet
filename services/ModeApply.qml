pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import "../config"

// Aplica los ajustes de sistema del modo activo:
// energía, hypridle, luz nocturna, gamemode y apps al entrar.
// (Colores, fondo, favoritas y no molestar siguen solos a Theme.mode / Config.)
Singleton {
    id: root

    readonly property var profiles: ({
            "power-saver": PowerProfile.PowerSaver,
            "balanced": PowerProfile.Balanced,
            "performance": PowerProfile.Performance
        })

    // Al arrancar, Theme lee el modo guardado: eso no cuenta como "cambiar de modo"
    property bool ready: false

    // Al cambiar de modo: todo, apps incluidas
    Connections {
        target: Theme
        function onModeChanged() {
            if (root.ready)
                settle.restart();
        }
    }
    Timer {
        id: settle
        interval: 600          // deja que Hyprland recargue antes
        onTriggered: {
            root.applySystem();
            root.launchApps();
        }
    }

    // Al arrancar velvet: lo de sistema, sin abrir apps
    Timer {
        running: true
        interval: 1500
        onTriggered: {
            root.ready = true;
            root.applySystem();
        }
    }

    function applySystem() {
        applyProfile();
        Config.applyIdle();          // bloqueo / pantalla / suspensión
        applyNight();
        applyGamemode();
        applyTerm();
    }

    function applyTerm() {
        Quickshell.execDetached(["bash", Quickshell.shellDir + "/scripts/term.sh"].concat(Theme.trio.map(c => String(c).replace("#", "").toLowerCase())));
    }

    function applyProfile() {
        const p = profiles[Config.profile] ?? PowerProfile.Balanced;
        if (p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)
            PowerProfiles.profile = p;
    }

    function applyNight() {
        Quickshell.execDetached(["sh", "-c", Config.nightLight ? "pgrep -x hyprsunset >/dev/null || setsid hyprsunset >/dev/null 2>&1 &" : "pkill -x hyprsunset || true"]);
    }

    function applyGamemode() {
        Quickshell.execDetached(["sh", "-c", Config.gamemode ? "pgrep -f '^gamemoded -r' >/dev/null || setsid gamemoded -r >/dev/null 2>&1 &" : "pkill -f '^gamemoded -r' || true"]);
    }

    function findApp(q) {
        const apps = DesktopEntries.applications.values;
        const k = q.toLowerCase();
        return apps.find(e => e.id.toLowerCase() === k) ?? apps.find(e => e.name.toLowerCase() === k) ?? apps.find(e => e.id.toLowerCase().includes(k)) ?? null;
    }

    // ¿Hay ya una ventana de esta app? (compara el app id de Wayland con el id del .desktop)
    function isOpen(entry) {
        const id = entry.id.toLowerCase().replace(/\.desktop$/, "");
        const tail = id.split(".").pop();
        return ToplevelManager.toplevels.values.some(t => {
            const a = (t.appId ?? "").toLowerCase();
            return a === id || a === tail || a.endsWith("." + tail) || a.includes(tail);
        });
    }

    function launchApps() {
        for (const a of Config.apps) {
            const e = findApp(a.id);
            if (!e || isOpen(e))
                continue;
            const cmd = e.command.map(c => c.includes(" ") ? "'" + c + "'" : c).join(" ");
            const lua = "hl.dsp.exec_cmd(" + JSON.stringify("[workspace " + a.ws + " silent] " + cmd) + ")";
            Quickshell.execDetached(["hyprctl", "dispatch", lua]);
        }
    }
}
