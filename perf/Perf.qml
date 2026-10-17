import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import "../config"
import "../components"
import "../services"

// Panel de rendimiento "Informe del Canal 05" (P4) con los colores del modo.
// Se abre al llevar el ratón al centro del borde derecho.
PanelWindow {
    id: win

    anchors.right: true                 // solo derecha → centrado en vertical
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top   // se esconde bajo pantalla completa
    WlrLayershell.namespace: "velvet-perf"
    color: "transparent"

    // ── Colores (salen del modo activo) ──
    // Usa la tríada completa del modo (en GENERAL: amarillo P4 · azul P3 · rojo P5)
    readonly property color main: Theme.accent3     // televisor: marco, franja, OSD, pestaña
    readonly property color shade: Theme.accent2    // sombra dura del televisor
    readonly property color warn: Theme.accent      // recuadro de CPU y avisos
    readonly property color mainInk: Theme.on(main)

    // ── Medidas ──
    readonly property int panelW: 560
    readonly property int panelH: 770
    readonly property int margin: 14                // separación del borde (deja ver la sombra)
    readonly property int hotH: 300
    // ¿Hay otro monitor pegado a la derecha? Entonces el borde no frena el ratón:
    // la zona es más ancha y hay que pararse un momento en ella para abrir.
    readonly property bool sharedEdge: {
        const s = win.screen;
        if (!s)
            return false;
        const right = s.x + s.width;
        return Quickshell.screens.some(o => o !== s && Math.abs(o.x - right) <= 2 && o.y < s.y + s.height && o.y + o.height > s.y);
    }
    implicitWidth: panelW + margin + 12
    implicitHeight: panelH + 12

    mask: Region {
        item: win.p > 0.01 ? panel : hot
    }

    // ── Estado ──
    property real p: 0
    property bool open: false
    property bool pinned: false
    Behavior on p {
        enabled: Config.animations
        NumberAnimation {
            duration: win.open ? 240 : 180
            easing.type: Easing.OutCubic
        }
    }
    onOpenChanged: {
        p = open ? 1 : 0;
        const me = win.screen?.name ?? "";
        if (open)
            Ui.perfScreen = me;
        else if (Ui.perfScreen === me)
            Ui.perfScreen = "";
    }

    readonly property bool hovering: hotHover.hovered || panelHover.hovered
    onHoveringChanged: {
        if (hovering) {
            closeT.stop();
            if (!open)
                openT.restart();
        } else {
            openT.stop();
            if (!pinned)
                closeT.restart();
        }
    }
    Timer {
        id: openT
        interval: win.sharedEdge ? 350 : 150
        onTriggered: win.open = true
    }
    Timer {
        id: closeT
        interval: 300
        onTriggered: if (!win.pinned && !win.hovering)
            win.open = false
    }

    // ── Datos ──
    readonly property var bat: UPower.displayDevice
    readonly property real batPct: bat.percentage > 1 ? bat.percentage / 100 : bat.percentage
    readonly property string batState: {
        switch (bat.state) {
        case UPowerDeviceState.Charging:
            return "AC · CARGANDO";
        case UPowerDeviceState.FullyCharged:
            return "AC · LLENA";
        case UPowerDeviceState.PendingCharge:
            return "AC";
        case UPowerDeviceState.Discharging:
            return bat.timeToEmpty > 0 ? "QUEDAN " + fmtDur(bat.timeToEmpty) : "DESCARGANDO";
        default:
            return "";
        }
    }
    readonly property real ramF: SysStats.memTotal > 0 ? SysStats.memUsed / SysStats.memTotal : 0
    readonly property real cpuPct: SysStats.cpu * 100
    readonly property var weather: cpuPct < 25 ? ["☀", "DESPEJADO"] : cpuPct < 60 ? ["☁", "NUBLADO"] : cpuPct < 85 ? ["☂", "LLUVIA"] : ["⛈", "TORMENTA"]

    function gb(b) {
        return (b / 1073741824).toFixed(1);
    }
    function fmtDur(s) {
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
        return h + "H " + String(m).padStart(2, "0") + "M";
    }
    function clamp01(v) {
        return Math.max(0, Math.min(1, v));
    }

    // Recuadros de lectura
    readonly property var tiles: {
        const t = [
            {
                k: "MEMORIA",
                sub: win.gb(SysStats.memTotal) + " GB",
                v: win.gb(SysStats.memUsed) + " GB",
                f: ramF,
                hot: ramF > 0.9
            },
            {
                k: "BATERÍA",
                sub: batState,
                v: Math.round(batPct * 100) + "%",
                f: batPct,
                hot: batPct < 0.2
            }
        ];
        for (const d of SysStats.disks) {
            const f = d.size > 0 ? d.used / d.size : 0;
            t.push({
                k: d.label === "/" ? "DISCO /" : d.label,
                sub: Math.round(f * 100) + "% USADO",
                v: Math.round(d.used / 1e9) + " / " + Math.round(d.size / 1e9) + " G",
                f: f,
                hot: f > 0.9
            });
        }
        t.push({
            k: "RED · " + SysStats.iface.toUpperCase(),
            sub: SysStats.ping >= 0 ? "PING " + SysStats.ping + " ms" : "SIN PING",
            v: "↓" + SysStats.netDown.toFixed(1) + " ↑" + SysStats.netUp.toFixed(1),
            f: clamp01(SysStats.netDown / 20),
            hot: false
        });
        t.push({
            k: "IRIS XE",
            sub: (SysStats.gpuMaxMhz || 1300) + " MHz MÁX",
            v: SysStats.gpuMhz + " MHz",
            f: clamp01(SysStats.gpuMhz / (SysStats.gpuMaxMhz || 1300)),
            hot: false
        });
        return t;
    }

    // ═══════════ Zona caliente + indicador ═══════════
    Item {
        id: hot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: win.sharedEdge ? 24 : 4
        height: win.hotH
        HoverHandler {
            id: hotHover
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 90
            color: win.main
            opacity: win.p < 0.01 ? 0.7 : 0
        }
    }

    // ═══════════ Panel ═══════════
    Item {
        id: panel
        width: win.panelW + 12
        height: win.panelH + 12
        x: 2 + (width + 20) * (1 - win.p)
        y: 0
        visible: win.p > 0
        HoverHandler {
            id: panelHover
        }

        // Sombra dura (abajo-izquierda)
        Rectangle {
            x: 0
            y: 12
            width: win.panelW
            height: win.panelH
            color: win.shade
        }

        // Televisor
        Rectangle {
            id: tv
            x: 10
            y: 0
            width: win.panelW
            height: win.panelH
            color: "#141311"
            border.width: 4
            border.color: win.main

            // Franja de precaución
            Canvas {
                id: hazard
                x: 4
                y: 4
                width: parent.width - 8
                height: 18
                onPaint: {
                    const g = getContext("2d");
                    g.reset();
                    g.fillStyle = String(win.main);
                    g.fillRect(0, 0, width, height);
                    g.fillStyle = String(Theme.ink);
                    for (let x = -height; x < width; x += 28) {
                        g.beginPath();
                        g.moveTo(x, height);
                        g.lineTo(x + 14, height);
                        g.lineTo(x + 14 + height, 0);
                        g.lineTo(x + height, 0);
                        g.closePath();
                        g.fill();
                    }
                }
                Connections {
                    target: win
                    function onMainChanged() {
                        hazard.requestPaint();
                    }
                }
            }

            // Pantalla
            Item {
                id: tvScreen
                x: 4
                y: 22
                width: parent.width - 8
                height: parent.height - 26
                clip: true

                SequentialAnimation on opacity {
                    running: win.p > 0
                    loops: Animation.Infinite
                    PauseAnimation {
                        duration: 1470
                    }
                    NumberAnimation {
                        to: 0.85
                        duration: 30
                    }
                    NumberAnimation {
                        to: 1
                        duration: 30
                    }
                    PauseAnimation {
                        duration: 1470
                    }
                }

                Shape {
                    anchors.fill: parent
                    ShapePath {
                        strokeWidth: -1
                        fillGradient: RadialGradient {
                            centerX: tvScreen.width / 2
                            centerY: tvScreen.height / 2
                            focalX: centerX
                            focalY: centerY
                            centerRadius: tvScreen.height * 0.7
                            GradientStop {
                                position: 0
                                color: "#24231C"
                            }
                            GradientStop {
                                position: 1
                                color: "#0B0B09"
                            }
                        }
                        PathPolyline {
                            path: [Qt.point(0, 0), Qt.point(tvScreen.width, 0), Qt.point(tvScreen.width, tvScreen.height), Qt.point(0, tvScreen.height), Qt.point(0, 0)]
                        }
                    }
                }
                Canvas {
                    anchors.fill: parent
                    z: 10
                    onPaint: {
                        const g = getContext("2d");
                        g.fillStyle = "rgba(255,255,255,0.04)";
                        for (let y = 0; y < height; y += 4)
                            g.fillRect(0, y, width, 1);
                    }
                }

                ColumnLayout {
                    x: 22
                    y: 16
                    width: parent.width - 44
                    spacing: 14

                    // ── OSD ──
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "CH 05"
                                color: win.main
                                style: Text.Raised
                                styleColor: Theme.ink
                                font.family: "JetBrains Mono"
                                font.pixelSize: 22
                                font.weight: Font.ExtraBold
                            }
                            Mono {
                                text: "INFORME DEL SISTEMA"
                                opacity: 0.7
                                font.letterSpacing: 3
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: 6
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 6
                                Mono {
                                    text: "●"
                                    Timer {
                                        interval: 500
                                        running: win.p > 0
                                        repeat: true
                                        onTriggered: parent.visible = !parent.visible
                                    }
                                }
                                Mono {
                                    text: "EN DIRECTO · " + win.fmtDur(SysStats.uptime)
                                    font.pixelSize: 11
                                    font.letterSpacing: 2
                                }
                            }
                            Item {
                                Layout.alignment: Qt.AlignRight
                                implicitWidth: pinT.implicitWidth + 24
                                implicitHeight: 24
                                Rectangle {
                                    anchors.fill: parent
                                    color: win.pinned ? win.main : Qt.alpha(win.main, 0.15)
                                }
                                Text {
                                    id: pinT
                                    anchors.centerIn: parent
                                    text: win.pinned ? "● FIJADO" : "○ FIJAR"
                                    color: win.pinned ? win.mainInk : win.main
                                    font.family: "Bebas Neue"
                                    font.pixelSize: 16
                                    font.letterSpacing: 2
                                }
                                TapHandler {
                                    onTapped: {
                                        win.pinned = !win.pinned;
                                        if (!win.pinned && !win.hovering)
                                            win.open = false;
                                    }
                                }
                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                    }

                    // ── Previsión de carga ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        spacing: 16

                        Rectangle {
                            id: cpuBox
                            Layout.preferredWidth: 150
                            Layout.fillHeight: true
                            color: win.warn
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: win.weather[0]
                                    color: Theme.on(cpuBox.color)
                                    font.pixelSize: 42
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Math.round(win.cpuPct) + "%"
                                    color: Theme.on(cpuBox.color)
                                    font.family: "Bebas Neue"
                                    font.pixelSize: 56
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "CPU · " + win.weather[1]
                                    color: Theme.on(cpuBox.color)
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 9
                                    font.weight: Font.ExtraBold
                                    font.letterSpacing: 2
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4
                            Text {
                                text: "PREVISIÓN DE CARGA · 60 s"
                                color: win.main
                                font.family: "Bebas Neue"
                                font.pixelSize: 22
                                font.letterSpacing: 3
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 2
                                    color: Qt.alpha(win.main, 0.4)
                                }
                                Row {
                                    anchors.fill: parent
                                    anchors.bottomMargin: 2
                                    spacing: 2
                                    Repeater {
                                        model: 30
                                        delegate: Item {
                                            required property int index
                                            readonly property var h: SysStats.history
                                            readonly property real v: {
                                                const i = h.length - 60 + index * 2 + 1;
                                                return i >= 0 && i < h.length ? h[i] : 0;
                                            }
                                            width: (parent.width - 29 * 2) / 30
                                            height: parent.height
                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                width: parent.width
                                                height: Math.max(2, parent.height * parent.v)
                                                color: parent.v > 0.85 ? win.warn : win.main
                                                opacity: 0.9
                                                Behavior on height {
                                                    NumberAnimation {
                                                        duration: 400
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Mono {
                                    text: "-60 s"
                                    font.pixelSize: 9
                                    opacity: 0.6
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Mono {
                                    text: SysStats.freqGHz.toFixed(1) + " GHz · " + Math.round(SysStats.temp) + " °C"
                                    color: SysStats.temp >= 80 ? win.warn : win.main
                                    font.pixelSize: 9
                                    opacity: SysStats.temp >= 80 ? 1 : 0.6
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Mono {
                                    text: "AHORA"
                                    font.pixelSize: 9
                                    opacity: 0.6
                                }
                            }
                        }
                    }

                    // ── Lecturas ──
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10
                        Repeater {
                            model: win.tiles
                            delegate: Rectangle {
                                id: tile
                                required property var modelData
                                required property int index
                                readonly property color c: Theme.at(index)
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: tileCol.implicitHeight + 20
                                color: Qt.alpha(Theme.ink, 0.6)
                                border.width: 2
                                border.color: tile.modelData.hot ? win.warn : Qt.alpha(tile.c, 0.35)
                                ColumnLayout {
                                    id: tileCol
                                    x: 12
                                    y: 10
                                    width: parent.width - 24
                                    spacing: 5
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Mono {
                                            text: (tile.modelData.hot ? "▲ " : "") + tile.modelData.k
                                            color: tile.c
                                            font.weight: Font.ExtraBold
                                            font.letterSpacing: 2
                                        }
                                        Item {
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: tile.modelData.sub
                                            color: Qt.alpha(Theme.paper, 0.55)
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }
                                    Big {
                                        text: tile.modelData.v
                                        font.pixelSize: 30
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 5
                                        color: Qt.alpha(tile.c, 0.12)
                                        Rectangle {
                                            height: parent.height
                                            width: parent.width * win.clamp01(tile.modelData.f)
                                            color: tile.modelData.hot ? Theme.paper : tile.c
                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: 450
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Sospechosos (caja de diálogo P4) ──
                    Item {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        implicitHeight: box.height + 14

                        Rectangle {
                            id: box
                            y: 14
                            width: parent.width
                            height: suspects.implicitHeight + 32
                            color: Qt.alpha(Theme.ink, 0.95)
                            border.width: 3
                            border.color: win.main

                            ColumnLayout {
                                id: suspects
                                x: 18
                                y: 22
                                width: parent.width - 36
                                spacing: 6
                                Repeater {
                                    model: SysStats.procs
                                    delegate: RowLayout {
                                        id: sus
                                        required property var modelData
                                        required property int index
                                        readonly property real maxCpu: Math.max(1, SysStats.procs[0]?.cpu ?? 1)
                                        Layout.fillWidth: true
                                        spacing: 10
                                        Text {
                                            text: "▶"
                                            color: Theme.at(sus.index)
                                            font.family: "Bebas Neue"
                                            font.pixelSize: 18
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: sus.modelData.name
                                            elide: Text.ElideRight
                                            color: Theme.paper
                                            font.family: "Montserrat"
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                        }
                                        Rectangle {
                                            Layout.preferredWidth: 120
                                            height: 6
                                            color: Qt.alpha(Theme.at(sus.index), 0.12)
                                            Rectangle {
                                                height: parent.height
                                                width: parent.width * Math.min(1, sus.modelData.cpu / sus.maxCpu)
                                                color: Theme.at(sus.index)
                                                Behavior on width {
                                                    NumberAnimation {
                                                        duration: 300
                                                    }
                                                }
                                            }
                                        }
                                        Mono {
                                            Layout.preferredWidth: 40
                                            horizontalAlignment: Text.AlignRight
                                            text: sus.modelData.cpu.toFixed(1)
                                            font.pixelSize: 11
                                            font.weight: Font.ExtraBold
                                        }
                                    }
                                }
                            }
                        }

                        // Pestaña
                        Item {
                            x: 18
                            y: 0
                            width: susT.implicitWidth + 32
                            height: 28
                            Slant {
                                anchors.fill: parent
                                color: win.main
                            }
                            Text {
                                id: susT
                                anchors.centerIn: parent
                                text: "SOSPECHOSOS"
                                color: win.mainInk
                                font.family: "Bebas Neue"
                                font.pixelSize: 20
                                font.letterSpacing: 3
                            }
                        }
                    }
                }
            }
        }
    }
}
