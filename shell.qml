import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "config"
import "bar"
import "launcher"
import "notifications"
import "lock"
import "wallpaper"
import "perf"
import "osd"
import "capture"
import "clip"
import "services"
import "settings"
import "modes"

Scope {
    // Fuentes propias de velvet (se registran para todo el shell)
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/BebasNeue-Regular.ttf")
    }
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/Montserrat-Regular.ttf")
    }
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/Montserrat-Medium.ttf")
    }
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/Montserrat-SemiBold.ttf")
    }
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/Montserrat-Bold.ttf")
    }
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/Montserrat-ExtraBold.ttf")
    }
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/Montserrat-Black.ttf")
    }

    // Aplica energía, bloqueo, luz nocturna, gamemode y apps según el modo
    readonly property var modeApply: ModeApply

    Variants {
        model: Quickshell.screens

        Scope {
            id: s
            required property var modelData

            Wallpaper {
                screen: s.modelData
            }
            Bar {
                modelData: s.modelData
            }
            Corner {
                screen: s.modelData
            }
            Launcher {
                screen: s.modelData
            }
            Popups {
                screen: s.modelData
            }
            Banner {
                screen: s.modelData
            }
            WallPicker {
                screen: s.modelData
            }
            Perf {
                screen: s.modelData
            }
            Settings {
                screen: s.modelData
            }
            ModeSelect {
                screen: s.modelData
            }
        }
    }

    Lock {}
    Osd {}
    Capture {}
    ClipPicker {}
    EmojiPicker {}

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            Ui.launcherScreen = Ui.launcherScreen !== "" ? "" : (Hyprland.focusedMonitor?.name ?? "");
        }
    }

    // qs -c velvet ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            Ui.wallpaperScreen = Ui.wallpaperScreen !== "" ? "" : (Hyprland.focusedMonitor?.name ?? "");
        }
    }

    // qs -c velvet ipc call session open → menú de pausa en ENERGÍA
    IpcHandler {
        target: "session"
        function open(): void {
            Ui.openCornerTab(Hyprland.focusedMonitor?.name ?? "", 5);
        }
    }

    // qs -c velvet ipc call notifs clear
    IpcHandler {
        target: "notifs"
        function clear(): void {
            Notifs.clearAll();
        }
    }

    // qs -c velvet ipc call settings toggle
    IpcHandler {
        target: "settings"
        function toggle(): void {
            Ui.settingsScreen = Ui.settingsScreen !== "" ? "" : (Hyprland.focusedMonitor?.name ?? "");
        }
    }

    // qs -c velvet ipc call mode toggle  |  qs -c velvet ipc call mode set dev
    IpcHandler {
        target: "mode"
        function toggle(): void {
            Ui.modeScreen = Ui.modeScreen !== "" ? "" : (Hyprland.focusedMonitor?.name ?? "");
        }
        function set(m: string): void {
            Theme.setMode(m);
        }
    }
}
