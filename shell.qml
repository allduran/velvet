import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "config"
import "bar"
import "launcher"
import "notifications"
import "lock"
import "wallpaper"
import "perf"
import "osd"
import "capture"

Scope {
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
        }
    }

    Lock {}
    Osd {}
    Capture {}

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
}
