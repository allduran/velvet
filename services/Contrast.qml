pragma Singleton
import QtQuick
import Quickshell

// Brillo y variación de la franja superior del fondo, por monitor y zona (left / center / right).
// Lo rellena Wallpaper.qml cada vez que cambia el fondo.
Singleton {
    id: root

    // Brillo medio (0–1) por encima del cual el fondo es claro → tinta oscura
    property real threshold: 0.55
    // Desviación (0–0.5) por encima de la cual la zona es "variada" → placa oscura
    property real busyThreshold: 0.16

    // { "eDP-1": { left: { mean: 0.21, dev: 0.05 }, center: {...}, right: {...} } }
    property var zones: ({})

    function set(screenName, z) {
        const c = Object.assign({}, zones);
        c[screenName] = z;
        zones = c;
    }

    function busy(screenName, zone) {
        const z = zones[screenName];
        return !!z && !!z[zone] && z[zone].dev > busyThreshold;
    }

    // Claro y uniforme → tinta oscura. Si es variado gana la placa (tinta clara).
    function light(screenName, zone) {
        const z = zones[screenName];
        return !!z && !!z[zone] && !busy(screenName, zone) && z[zone].mean > threshold;
    }
}
