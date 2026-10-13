import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import "../config"
import "../components"
import "../services"

// Panel de rendimiento "Ficha de STATUS" (P5).
// Se abre al llevar el ratón al centro del borde derecho. Colores del modo vía Theme.
PanelWindow {
    id: win

    anchors.right: true                 // solo derecha → centrado en vertical
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top   // se esconde bajo pantalla completa
    WlrLayershell.namespace: "velvet-perf"
    color: "transparent"

    // ── Medidas ──
    readonly property int panelW: 600
    readonly property int panelH: 830
    readonly property int hotH: 300
    implicitWidth: panelW
    implicitHeight: panelH

    mask: Region {
        item: win.p > 0.01 ? panel : hot
    }

    // ── Estado ──
    property real p: 0
    property bool open: false
    property bool pinned: false
    Behavior on p {
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
        if (open)
            stampIn.restart();
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
        interval: 150
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
    readonly property real ramF: SysStats.memTotal > 0 ? SysStats.memUsed / SysStats.memTotal : 0
    readonly property real diskF: {
        const d = SysStats.disks;
        return d.length ? d.reduce((a, x) => a + x.used / x.size, 0) / d.length : 0;
    }
    function clamp01(v) {
        return Math.max(0, Math.min(1, v));
    }
    function gb(b) {
        return (b / 1073741824).toFixed(1);
    }

    // Ejes del pentágono (animados)
    readonly property var names: ["CPU", "RAM", "TEMP", "DISCO", "RED"]
    property real v0: SysStats.cpu
    property real v1: ramF
    property real v2: clamp01((SysStats.temp - 30) / 70)
    property real v3: diskF
    property real v4: clamp01(SysStats.netDown / 20)
    Behavior on v0 {
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutCubic
        }
    }
    Behavior on v1 {
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutCubic
        }
    }
    Behavior on v2 {
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutCubic
        }
    }
    Behavior on v3 {
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutCubic
        }
    }
    Behavior on v4 {
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutCubic
        }
    }

    readonly property real cx: 150
    readonly property real cy: 150
    readonly property real rad: 105
    function pt(i, f) {
        const a = (-90 + i * 72) * Math.PI / 180;
        return Qt.point(cx + Math.cos(a) * rad * f, cy + Math.sin(a) * rad * f);
    }
    function ring(f) {
        return [0, 1, 2, 3, 4, 0].map(i => pt(i, f));
    }

    // ═══════════ Zona caliente + indicador ═══════════
    Item {
        id: hot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: win.hotH
        HoverHandler {
            id: hotHover
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 90
            color: Theme.accent
            opacity: win.p < 0.01 ? 0.7 : 0
        }
    }

    // ═══════════ Panel ═══════════
    Item {
        id: panel
        width: win.panelW
        height: win.panelH
        x: (win.panelW + 20) * (1 - win.p)
        visible: win.p > 0
        HoverHandler {
            id: panelHover
        }

        readonly property real pw: width
        readonly property real ph: height
        // Interior desplazado (borde dentado de color asoma a la izquierda)
        readonly property real ix: 14
        readonly property real iy: 10
        readonly property real iw: pw - ix
        readonly property real ih: ph - iy * 2

        // Borde dentado (color del modo)
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: Theme.accent
                strokeColor: "transparent"
                PathPolyline {
                    path: [Qt.point(panel.pw * 0.08, 0), Qt.point(panel.pw, 0), Qt.point(panel.pw, panel.ph), Qt.point(0, panel.ph), Qt.point(panel.pw * 0.05, panel.ph * 0.72), Qt.point(panel.pw * 0.01, panel.ph * 0.70), Qt.point(panel.pw * 0.06, panel.ph * 0.40), Qt.point(panel.pw * 0.02, panel.ph * 0.38), Qt.point(panel.pw * 0.08, 0)]
                }
            }
        }
        // Cuerpo negro
        Shape {
            id: bodyShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property var poly: [Qt.point(panel.ix + panel.iw * 0.08, panel.iy), Qt.point(panel.pw, panel.iy), Qt.point(panel.pw, panel.ph - panel.iy), Qt.point(panel.ix + panel.iw * 0.01, panel.ph - panel.iy), Qt.point(panel.ix + panel.iw * 0.05, panel.iy + panel.ih * 0.72), Qt.point(panel.ix + panel.iw * 0.01, panel.iy + panel.ih * 0.70), Qt.point(panel.ix + panel.iw * 0.06, panel.iy + panel.ih * 0.40), Qt.point(panel.ix + panel.iw * 0.02, panel.iy + panel.ih * 0.38), Qt.point(panel.ix + panel.iw * 0.08, panel.iy)]
            ShapePath {
                fillColor: Qt.alpha(Theme.ink, 0.97)
                strokeColor: "transparent"
                PathPolyline {
                    path: bodyShape.poly
                }
            }
        }
        // Trama de puntos en el color del modo
        Canvas {
            id: dots
            anchors.fill: parent
            onPaint: {
                const g = getContext("2d");
                g.reset();
                const poly = bodyShape.poly;
                g.beginPath();
                g.moveTo(poly[0].x, poly[0].y);
                for (let i = 1; i < poly.length; i++)
                    g.lineTo(poly[i].x, poly[i].y);
                g.closePath();
                g.clip();
                const c = Theme.accent;
                g.fillStyle = "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ",0.25)";
                for (let y = 0; y < height; y += 12)
                    for (let x = 0; x < width; x += 12) {
                        g.beginPath();
                        g.arc(x, y, 1.4, 0, Math.PI * 2);
                        g.fill();
                    }
            }
            Connections {
                target: Theme
                function onAccentChanged() {
                    dots.requestPaint();
                }
            }
        }

        ColumnLayout {
            x: 74
            y: 34
            width: panel.pw - 74 - 28
            spacing: 14

            // ── Ficha de personaje ──
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 6
                    Item {
                        id: stamp
                        implicitWidth: stampT.implicitWidth + 32
                        implicitHeight: stampT.implicitHeight
                        rotation: -8
                        Rectangle {
                            x: 6
                            y: 6
                            width: parent.width
                            height: parent.height
                            color: Theme.accent
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.paper
                        }
                        Text {
                            id: stampT
                            anchors.centerIn: parent
                            text: "STATUS"
                            color: Theme.ink
                            font.family: "Bebas Neue"
                            font.pixelSize: 54
                            font.letterSpacing: 4
                        }
                        ParallelAnimation {
                            id: stampIn
                            NumberAnimation {
                                target: stamp
                                property: "scale"
                                from: 1.6
                                to: 1
                                duration: 350
                                easing.type: Easing.OutBack
                            }
                            NumberAnimation {
                                target: stamp
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                            }
                        }
                    }
                    Row {
                        Layout.topMargin: 6
                        spacing: 10
                        Text {
                            id: pcName
                            text: "ALDURAN-PC"
                            color: Theme.paper
                            font.family: "Montserrat"
                            font.pixelSize: 20
                            font.weight: Font.Black
                            font.italic: true
                        }
                        Text {
                            anchors.baseline: pcName.baseline
                            text: "LV " + Math.floor(SysStats.uptime / 3600)
                            color: Theme.accent
                            font.family: "Bebas Neue"
                            font.pixelSize: 20
                            font.letterSpacing: 2
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                Item {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: pinT.implicitWidth + 24
                    implicitHeight: 26
                    Slant {
                        anchors.fill: parent
                        color: win.pinned ? Theme.paper : Theme.accent
                    }
                    Text {
                        id: pinT
                        anchors.centerIn: parent
                        text: win.pinned ? "● FIJADO" : "○ FIJAR"
                        color: win.pinned ? Theme.ink : Theme.on(Theme.accent)
                        font.family: "Bebas Neue"
                        font.pixelSize: 17
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

            // ── HP / SP ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: [
                        {
                            k: "HP",
                            f: win.batPct,
                            v: Math.round(win.batPct * 100) + " / 100",
                            c: win.batPct < 0.2 ? Theme.accent : Theme.accent3
                        },
                        {
                            k: "SP",
                            f: 1 - win.ramF,
                            v: win.gb(SysStats.memTotal - SysStats.memUsed) + " / " + win.gb(SysStats.memTotal),
                            c: Theme.accent2
                        }
                    ]
                    delegate: RowLayout {
                        id: gauge
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 34
                            text: gauge.modelData.k
                            color: gauge.modelData.c
                            font.family: "Bebas Neue"
                            font.pixelSize: 24
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 14
                            Rectangle {
                                id: track
                                anchors.fill: parent
                                color: "#2A2B30"
                                border.width: 2
                                border.color: Theme.paper
                                antialiasing: true
                                transform: Matrix4x4 {
                                    matrix: Qt.matrix4x4(1, -0.36, 0, 0.36 * track.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                                }
                                Rectangle {
                                    x: 2
                                    y: 2
                                    height: parent.height - 4
                                    width: (parent.width - 4) * win.clamp01(gauge.modelData.f)
                                    color: gauge.modelData.c
                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 450
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }
                        }
                        Text {
                            Layout.preferredWidth: 110
                            horizontalAlignment: Text.AlignRight
                            text: gauge.modelData.v
                            color: Theme.paper
                            font.family: "Bebas Neue"
                            font.pixelSize: 22
                            font.letterSpacing: 1
                        }
                    }
                }
                Text {
                    text: "HP = BATERÍA · SP = MEMORIA LIBRE · LV = HORAS ENCENDIDO"
                    color: Qt.alpha(Theme.paper, 0.5)
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1
                }
            }

            // ── Pentágono + stats ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 280
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        // Rejilla
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Qt.alpha(Theme.paper, 0.18)
                            strokeWidth: 1
                            PathPolyline {
                                path: win.ring(1 / 3)
                            }
                        }
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Qt.alpha(Theme.paper, 0.18)
                            strokeWidth: 1
                            PathPolyline {
                                path: win.ring(2 / 3)
                            }
                        }
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Qt.alpha(Theme.paper, 0.18)
                            strokeWidth: 1
                            PathPolyline {
                                path: win.ring(1)
                            }
                        }
                        // Radios
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Qt.alpha(Theme.paper, 0.12)
                            strokeWidth: 1
                            PathMultiline {
                                paths: [0, 1, 2, 3, 4].map(i => [Qt.point(win.cx, win.cy), win.pt(i, 1)])
                            }
                        }
                        // Valores
                        ShapePath {
                            fillColor: Qt.alpha(Theme.accent, 0.55)
                            strokeColor: Theme.paper
                            strokeWidth: 3
                            joinStyle: ShapePath.RoundJoin
                            PathPolyline {
                                path: {
                                    const v = [win.v0, win.v1, win.v2, win.v3, win.v4].map(x => Math.max(0.06, x));
                                    return [0, 1, 2, 3, 4, 0].map(i => win.pt(i, v[i]));
                                }
                            }
                        }
                    }
                    Repeater {
                        model: win.names
                        delegate: Text {
                            required property string modelData
                            required property int index
                            readonly property point at: win.pt(index, 1.2)
                            x: at.x - implicitWidth / 2
                            y: at.y - implicitHeight / 2
                            text: modelData
                            color: Theme.paper
                            font.family: "Bebas Neue"
                            font.pixelSize: 18
                            font.letterSpacing: 2
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [
                            {
                                k: "CPU",
                                v: Math.round(SysStats.cpu * 100) + "% · " + SysStats.freqGHz.toFixed(1) + " GHz",
                                hot: SysStats.cpu > 0.85,
                                alt: false
                            },
                            {
                                k: "TEMP",
                                v: Math.round(SysStats.temp) + " °C",
                                hot: SysStats.temp >= 80,
                                alt: false
                            },
                            {
                                k: "DISCO",
                                v: SysStats.disks.map(d => d.label + " " + Math.round(d.used / d.size * 100) + "%").join(" · "),
                                hot: false,
                                alt: false
                            },
                            {
                                k: "RED",
                                v: "↓" + SysStats.netDown.toFixed(1) + " ↑" + SysStats.netUp.toFixed(1),
                                hot: false,
                                alt: false
                            },
                            {
                                k: "IRIS XE",
                                v: SysStats.gpuMhz + " MHz",
                                hot: false,
                                alt: true
                            }
                        ]
                        delegate: RowLayout {
                            id: stat
                            required property var modelData
                            readonly property color chip: modelData.hot ? Theme.accent : modelData.alt ? Theme.accent2 : Theme.paper
                            Layout.fillWidth: true
                            spacing: 8
                            Item {
                                implicitWidth: statK.implicitWidth + 20
                                implicitHeight: 20
                                Slant {
                                    anchors.fill: parent
                                    color: stat.chip
                                }
                                Text {
                                    id: statK
                                    anchors.centerIn: parent
                                    text: stat.modelData.k
                                    color: Theme.on(stat.chip)
                                    font.family: "Bebas Neue"
                                    font.pixelSize: 17
                                    font.letterSpacing: 2
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            Text {
                                text: stat.modelData.v
                                color: Theme.paper
                                font.family: "Bebas Neue"
                                font.pixelSize: 20
                            }
                        }
                    }
                }
            }

            // ── Objetivos (top procesos) ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Item {
                    implicitWidth: objT.implicitWidth + 28
                    implicitHeight: 26
                    Slant {
                        anchors.fill: parent
                        color: Theme.accent
                    }
                    Text {
                        id: objT
                        anchors.centerIn: parent
                        text: "TARGETS"
                        color: Theme.on(Theme.accent)
                        font.family: "Bebas Neue"
                        font.pixelSize: 22
                        font.letterSpacing: 3
                    }
                }
                Repeater {
                    model: SysStats.procs
                    delegate: Item {
                        id: target
                        required property var modelData
                        required property int index
                        readonly property bool first: index === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26

                        Rectangle {
                            id: rowBg
                            anchors.fill: parent
                            color: target.first ? Theme.paper : Qt.alpha(Theme.paper, 0.06)
                            antialiasing: true
                            transform: Matrix4x4 {
                                matrix: Qt.matrix4x4(1, -0.18, 0, 0.18 * rowBg.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                            }
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10
                            Text {
                                Layout.preferredWidth: 26
                                text: String(target.index + 1).padStart(2, "0")
                                color: Theme.accent
                                font.family: "Bebas Neue"
                                font.pixelSize: 20
                            }
                            Text {
                                Layout.fillWidth: true
                                text: target.modelData.name
                                elide: Text.ElideRight
                                color: target.first ? Theme.ink : Theme.paper
                                font.family: "Montserrat"
                                font.pixelSize: 13
                                font.weight: Font.ExtraBold
                                font.italic: true
                            }
                            Text {
                                text: target.modelData.cpu.toFixed(1) + "%"
                                color: target.first ? Theme.ink : Theme.paper
                                font.family: "Bebas Neue"
                                font.pixelSize: 20
                            }
                        }
                    }
                }
            }
        }
    }
}
