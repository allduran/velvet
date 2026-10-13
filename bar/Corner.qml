import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Shapes
import "../config"
import "../components"
import "../services"
import "pause"

PanelWindow {
    id: win
    anchors {
        top: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top   // Top: se esconde bajo las ventanas a pantalla completa
    WlrLayershell.namespace: "velvet-corner"
    color: "transparent"

    // ── Medidas ──
    readonly property int panelW: 512
    readonly property int panelH: 372
    readonly property int cut: 32            // inclinación del borde izquierdo
    readonly property int shadow: 6          // desplazamiento de la sombra dura
    readonly property int pad: 24            // margen interior
    readonly property int bodyY: 116          // donde empiezan pestañas y contenido
    readonly property int contentX: 184      // donde empieza el contenido
    implicitWidth: panelW
    implicitHeight: panelH

    mask: Region {
        item: win.p > 0.01 ? body : clockArea
    }

    // ── Estado ──
    property real p: 0
    property bool open: false
    property bool pinned: false
    property int tab: 0
    readonly property var names: ["SISTEMA", "RED", "BLUETOOTH", "APPS", "AVISOS", "ENERGÍA"]
    readonly property var codes: ["SYS.CORE", "NET.WLAN0", "BT.HCI0", "TRAY.ITEMS", "NOTIF.LOG", "PWR.STATE"]

    Behavior on p {
        NumberAnimation {
            duration: win.open ? 220 : 160
            easing.type: Easing.OutCubic
        }
    }
    onOpenChanged: {
        const me = win.screen?.name ?? "";
        if (open)
            Ui.cornerScreen = me;
        else if (Ui.cornerScreen === me)
            Ui.cornerScreen = "";

        p = open ? 1 : 0;
        if (open) {
            tab = 0;
            for (let i = 0; i < tabs.count; i++)
                tabs.itemAt(i).enter();
        }
    }
    onTabChanged: {
        pages.contentY = 0;
        if (tab === 4)
            Notifs.markRead();
    }

    function l(a, b) {
        return a + (b - a) * p;
    }
    function edge(y) {
        return shadow + cut * y / (panelH - shadow);
    }
    function close() {
        pinned = false;
        grab.active = false;
        open = false;
    }

    // ── Batería ──
    readonly property var bat: UPower.displayDevice
    readonly property real pct: bat.percentage > 1 ? bat.percentage / 100 : bat.percentage
    readonly property bool charging: bat.state === UPowerDeviceState.Charging
    readonly property bool lowBattery: pct < 0.2 && !charging

    // ── Contraste con el fondo (solo con el panel cerrado) ──
    readonly property bool light: Contrast.light(win.screen?.name ?? "", "right") && win.p < 0.5
    readonly property color fg: light ? Theme.ink : Theme.paper
    readonly property bool plate: Contrast.busy(win.screen?.name ?? "", "right") && win.p < 0.5

    // ── Hover ──
    readonly property bool hovering: clockHover.hovered || bodyHover.hovered
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
        interval: 250
        onTriggered: win.open = true
    }
    Timer {
        id: closeT
        interval: 300
        onTriggered: if (!win.pinned && !win.hovering)
            win.open = false
    }

    HyprlandFocusGrab {
        id: grab
        windows: [win]
        onCleared: win.close()
    }

    Connections {
        target: Ui
        function onOpenCorner(name) {
            if (name !== win.screen?.name)
                return;
            win.pinned = true;
            win.open = true;
            Qt.callLater(() => grab.active = true);
        }
    }

    // ═══════════ Panel ═══════════
    Item {
        id: body
        anchors {
            top: parent.top
            right: parent.right
        }
        width: win.panelW * win.p
        height: win.panelH * win.p
        clip: true
        visible: win.p > 0
        HoverHandler {
            id: bodyHover
        }

        Item {
            anchors {
                top: parent.top
                right: parent.right
            }
            width: win.panelW
            height: win.panelH

            // Sombra dura
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Theme.accent
                    strokeColor: "transparent"
                    startX: 0
                    startY: win.shadow
                    PathLine {
                        x: win.panelW - win.shadow
                        y: win.shadow
                    }
                    PathLine {
                        x: win.panelW - win.shadow
                        y: win.panelH
                    }
                    PathLine {
                        x: win.cut
                        y: win.panelH
                    }
                    PathLine {
                        x: 0
                        y: win.shadow
                    }
                }
            }
            // Panel
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Qt.alpha(Theme.surface, 0.97)
                    strokeColor: "transparent"
                    startX: win.shadow
                    startY: 0
                    PathLine {
                        x: win.panelW
                        y: 0
                    }
                    PathLine {
                        x: win.panelW
                        y: win.panelH - win.shadow
                    }
                    PathLine {
                        x: win.cut + win.shadow
                        y: win.panelH - win.shadow
                    }
                    PathLine {
                        x: win.shadow
                        y: 0
                    }
                }
            }

            // ── Cabecera izquierda: título + batería ──
            Text {
                id: title
                x: win.pad + 4
                y: 14
                text: win.names[win.tab]
                color: Theme.paper
                font {
                    family: "Bebas Neue"
                    pixelSize: 50
                    letterSpacing: 2
                }
            }
            Slant {
                x: title.x + 2
                y: title.y + title.height
                width: 70
                height: 3
                skew: -0.6
                color: Theme.accent3
            }
            Text {
                x: title.x + 2
                y: title.y + title.height + 8
                text: win.codes[win.tab] + "  //  SYS.MENU"
                color: Theme.telemetry
                font {
                    family: "JetBrains Mono"
                    pixelSize: 8
                    bold: true
                    letterSpacing: 1.2
                }
            }

            // ── Pestañas ──
            Repeater {
                id: tabs
                model: win.names
                delegate: PauseTab {
                    required property string modelData
                    required property int index
                    readonly property real ty: win.bodyY + index * 34
                    y: ty
                    x: win.edge(ty) + 6
                    label: modelData
                    order: index
                    active: win.tab === index
                    onPicked: win.tab = index
                }
            }

            // ── Contenido ──
            Flickable {
                id: pages
                x: win.contentX
                y: win.bodyY
                width: win.panelW - x - win.pad
                height: win.panelH - y - win.pad
                clip: true
                contentWidth: width
                contentHeight: [pSys, pWifi, pBt, pApps, pNotif, pPower][win.tab].height
                boundsBehavior: Flickable.StopAtBounds

                Item {
                    x: 6
                    width: pages.width - 6
                    height: pages.contentHeight

                    PageSystem {
                        id: pSys
                        visible: win.tab === 0
                        width: parent.width
                    }
                    PageWifi {
                        id: pWifi
                        visible: win.tab === 1
                        width: parent.width
                        onDone: win.close()
                    }
                    PageBluetooth {
                        id: pBt
                        visible: win.tab === 2
                        width: parent.width
                    }
                    PageApps {
                        id: pApps
                        visible: win.tab === 3
                        width: parent.width
                        onDone: win.close()
                        onOpenItemChanged: pages.contentY = 0
                    }
                    PageNotifs {
                        id: pNotif
                        visible: win.tab === 4
                        width: parent.width
                        onDone: win.close()
                    }
                    PagePower {
                        id: pPower
                        visible: win.tab === 5
                        width: parent.width
                        onDone: win.close()
                    }
                }
            }
            Rectangle {
                visible: pages.contentHeight > pages.height
                x: pages.x + pages.width + 8
                y: pages.y + pages.visibleArea.yPosition * pages.height
                width: 2
                height: pages.visibleArea.heightRatio * pages.height
                color: Theme.accent2
            }
        }
    }

    // ── Placa desde la esquina superior derecha (solo cerrado) ──
    Shape {
        id: clockPlate
        readonly property real slant: 16
        anchors {
            top: parent.top
            right: parent.right
        }
        width: clockArea.width + clockArea.anchors.rightMargin + 28   // desde el borde derecho hasta pasado el reloj
        height: 48                                                     // = alto de la barra, igual que la izquierda
        preferredRendererType: Shape.CurveRenderer
        opacity: win.plate ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        ShapePath {
            fillColor: Qt.alpha(Theme.ink, 0.72)
            strokeColor: "transparent"
            startX: 0
            startY: 0
            PathLine {
                x: clockPlate.width
                y: 0
            }
            PathLine {
                x: clockPlate.width
                y: clockPlate.height
            }
            PathLine {
                x: clockPlate.slant
                y: clockPlate.height
            }
            PathLine {
                x: 0
                y: 0
            }
        }
    }

    // ═══════════ Reloj ═══════════
    Item {
        id: clockArea
        anchors {
            top: parent.top
            right: parent.right
            topMargin: win.l(10, 14)
            rightMargin: win.l(12, win.pad)
        }
        width: clockCol.implicitWidth
        height: clockCol.implicitHeight

        HoverHandler {
            id: clockHover
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: {
                if (win.pinned) {
                    win.close();
                    return;
                }
                win.pinned = true;
                win.open = true;
                Qt.callLater(() => grab.active = true);
            }
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Column {
            id: clockCol
            spacing: win.l(0, 8)

            Row {
                id: clockRow
                spacing: win.l(8, 10)

                Slant {
                    visible: Notifs.unread > 0 && win.p < 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: unreadT.implicitWidth + 16
                    height: 18
                    color: Theme.accent
                    Text {
                        id: unreadT
                        anchors.centerIn: parent
                        text: Notifs.unread + " AVISOS"
                        color: Theme.paper
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 10
                            weight: Font.ExtraBold
                            letterSpacing: 1
                        }
                    }
                }

                // Aviso de batería baja (solo en la barra)
                Slant {
                    visible: win.lowBattery && win.p < 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: warn.implicitWidth + 14
                    height: 16
                    color: Theme.accent
                    Text {
                        id: warn
                        anchors.centerIn: parent
                        text: "BAT " + Math.round(win.pct * 100) + "%"
                        color: Theme.paper
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 10
                            bold: true
                            letterSpacing: 1
                        }
                    }
                }

                Slant {
                    anchors.verticalCenter: parent.verticalCenter
                    width: win.l(4, 5)
                    height: win.l(22, 38)
                    color: Theme.accent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: win.fg
                    font {
                        family: "Bebas Neue"
                        pixelSize: win.l(30, 50)
                        letterSpacing: win.l(1, 2)
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: win.l(2, 4)
                    Slant {
                        width: day.implicitWidth + 12
                        height: day.implicitHeight
                        skew: -0.14
                        color: win.fg
                        Slant {
                            width: 3
                            height: parent.height
                            skew: -0.14
                            color: Theme.accent2
                        }
                        Text {
                            id: day
                            anchors.centerIn: parent
                            text: Qt.formatDateTime(clock.date, win.p > 0.5 ? "dddd" : "ddd").toUpperCase()
                            color: win.light ? Theme.paper : Theme.ink
                            font {
                                family: "JetBrains Mono"
                                pixelSize: 11
                                bold: true
                                letterSpacing: 1
                            }
                        }
                    }
                    Text {
                        text: Qt.formatDateTime(clock.date, win.p > 0.5 ? "dd.MM.yyyy" : "dd.MM")
                        color: win.light ? Qt.alpha(Theme.ink, 0.7) : Theme.telemetry
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 12
                            bold: true
                            letterSpacing: 1
                        }
                    }
                }
            }

            // Batería: ocupa el ancho del reloj (solo abierto)
            Item {
                visible: win.p > 0.01
                opacity: win.p
                width: clockRow.width
                height: 12

                SegBar {
                    anchors.verticalCenter: parent.verticalCenter
                    count: 16
                    gap: 2
                    segH: 8
                    segW: Math.max(2, Math.floor((parent.width - batPct.width - 10 - (count - 1) * gap) / count))
                    value: win.pct
                    fill: win.lowBattery ? Theme.accent : Theme.paper
                }
                Text {
                    id: batPct
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: (win.charging ? "CHG " : "") + Math.round(win.pct * 100) + "%"
                    color: win.lowBattery ? Theme.accent : Theme.paper
                    font {
                        family: "Bebas Neue"
                        pixelSize: 16
                        letterSpacing: 1
                    }
                }
            }
        }
    }
}
