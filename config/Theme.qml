pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property string mode: "general"   // "general" | "dev" | "art" | "game"

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

    readonly property var trio: palettes[mode].trio
    readonly property color accent: trio[0]     // rojo
    readonly property color accent2: trio[1]    // azul
    readonly property color accent3: trio[2]    // amarillo
    readonly property color telemetry: palettes[mode].telemetry

    // Color por posición: va rotando entre los tres
    function at(i) {
        return trio[i % 3];
    }

    // Texto legible sobre un color (oscuro sobre amarillo, claro sobre el resto)
    function on(c) {
        const k = Qt.lighter(c, 1.0);
        return (0.299 * k.r + 0.587 * k.g + 0.114 * k.b) > 0.6 ? ink : paper;
    }
}
