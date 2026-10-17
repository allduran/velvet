pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Ids de los modos del selector (la lista completa está en Modes.qml)
    readonly property var modes: Modes.shown.map(m => m.id)
    // Modo activo. Se guarda en ~/.local/state/velvet/mode (también lo lee Hyprland: scheme/active.lua)
    property string mode: "general"

    readonly property color canvas: "#0C0E14"
    readonly property color surface: "#141824"
    readonly property color paper: "#F5F5F7"
    readonly property color ink: "#0D0E12"

    // Cada modo tiene tres colores. GENERAL = la tríada P5 · P3 · P4
    readonly property var palettes: ({
            general: {
                trio: ["#E60012", "#0055FF", "#FFE600"],
                telemetry: "#C3C5D9"
            },
            dev: {
                trio: ["#0055FF", "#00A6FF", "#40E0D0"],
                telemetry: "#40E0D0"
            },
            art: {
                trio: ["#FFE600", "#FFA800", "#70D600"],
                telemetry: "#FFA800"
            },
            game: {
                trio: ["#E60012", "#FF3B30", "#B0B3BA"],
                telemetry: "#B0B3BA"
            }
        })

    // Estilo del modo activo (general/dev/art/game): de él salen los colores
    readonly property string style: Modes.styleOf(mode)
    readonly property var trio: palettes[style].trio
    readonly property color accent: trio[0]
    readonly property color accent2: trio[1]
    readonly property color accent3: trio[2]
    readonly property color telemetry: palettes[style].telemetry

    // Color por posición: va rotando entre los tres
    function at(i) {
        return trio[i % 3];
    }

    // Texto legible sobre un color (oscuro sobre amarillo, claro sobre el resto)
    function on(c) {
        const k = Qt.lighter(c, 1.0);
        return (0.299 * k.r + 0.587 * k.g + 0.114 * k.b) > 0.6 ? ink : paper;
    }

    // Cambia de modo: colores, fondo y favoritas siguen solos a `mode`.
    // Hyprland relee el archivo al recargar (bordes, sombra, grupos).
    function setMode(m) {
        if (!Modes.exists(m) || m === mode)
            return;
        mode = m;
        modeFile.setText(m + "\n");
        Modes.writeLook();
        hyprReload.restart();
    }

    FileView {
        id: modeFile
        path: Quickshell.env("HOME") + "/.local/state/velvet/mode"
        printErrors: false
        onLoaded: {
            // Aún puede no estar cargada la lista de modos propios: basta con que parezca un id
            const m = text().trim();
            if (/^[a-z0-9]+$/.test(m))
                root.mode = m;
        }
    }

    Timer {
        id: hyprReload
        interval: 300
        onTriggered: Quickshell.execDetached(["hyprctl", "reload"])
    }
}
