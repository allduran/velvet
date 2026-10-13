pragma Singleton
import Quickshell
import QtQuick

Singleton {
    signal openCorner(string screenName)

    // Monitor donde está abierto el launcher ("" = cerrado)
    property string launcherScreen: ""
    // Monitor donde está abierto el menú de esquina ("" = cerrado)
    property string cornerScreen: ""
    // Monitor donde está abierto el selector de fondos ("" = cerrado)
    property string wallpaperScreen: ""
    // Monitor con el panel de rendimiento abierto ("" = cerrado)
    property string perfScreen: ""
}
