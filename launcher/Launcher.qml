import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import "../config"
import "../components"

PanelWindow {
    id: win
    property string screenName: ""
    visible: Ui.launcherScreen !== "" && Ui.launcherScreen === screenName
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "velvet-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    // ═══════════ CONFIGURACIÓN ═══════════
    // Posiciones en fracción de pantalla: x 0 = izquierda, 1 = derecha; y 0 = arriba, 1 = abajo.
    // rot = inclinación en grados, s = escala.
    readonly property var favSpots: [
        {
            x: 0.65,
            y: 0.3,
            rot: -24,
            s: 1.12
        }   // favorita 1 (la más usada)
        ,
        {
            x: 0.69,
            y: 0.43,
            rot: -4,
            s: 1.00
        }   // favorita 2
        ,
        {
            x: 0.65,
            y: 0.55,
            rot: 3,
            s: 0.95
        }   // favorita 3
        ,
        {
            x: 0.7,
            y: 0.68,
            rot: 24,
            s: 0.90
        }    // favorita 4
    ]
    readonly property var coreSpots: [
        {
            x: 0.19,
            y: 0.48,
            rot: -6,
            s: 1.25
        }   // terminal
        ,
        {
            x: 0.24,
            y: 0.60,
            rot: 5,
            s: 1.18
        }    // ajustes
    ]
    // Desplazamiento de cada grupo entero, en píxeles
    readonly property point favOffset: Qt.point(0, 0)
    readonly property point coreOffset: Qt.point(0, 0)

    // Favoritas por modo: nombre o id de la app
    readonly property var pins: Config.pins
    readonly property var core: [
        {
            key: "5",
            label: "TERMINAL",
            meta: "FOOT"
        },
        {
            key: "6",
            label: "AJUSTES",
            meta: "SISTEMA"
        }
    ]
    // ══════════════════════════════════════

    readonly property real sx: width / 1600
    readonly property real sy: height / 900

    // Busca una app por id o nombre (primero coincidencia exacta, luego parcial)
    function findApp(q) {
        const apps = DesktopEntries.applications.values;
        const k = q.toLowerCase();
        return apps.find(e => e.id.toLowerCase() === k) ?? apps.find(e => e.name.toLowerCase() === k) ?? apps.find(e => e.id.toLowerCase().includes(k)) ?? apps.find(e => e.name.toLowerCase().includes(k)) ?? null;
    }
    readonly property var pinEntries: (pins[Theme.mode] ?? pins.general).map(id => findApp(id)).filter(e => e !== null)

    // ── Estado ──
    property string query: ""
    property int sel: 0

    readonly property var results: {
        const q = query.trim().toLowerCase();
        if (!q)
            return [];
        return DesktopEntries.applications.values.filter(e => !e.noDisplay && (e.name.toLowerCase().includes(q) || (e.genericName || "").toLowerCase().includes(q) || (e.keywords || []).some(k => k.toLowerCase().includes(q)))).map(e => ({
                    e: e,
                    score: (e.name.toLowerCase().startsWith(q) ? 100 : 0) + (Config.rankSort ? win.rank(e.id) * 5 : 0)
                })).sort((a, b) => b.score - a.score).slice(0, 6).map(x => x.e);
    }
    readonly property var current: results[sel] ?? null

    // ── Rango por uso ──
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/velvet"
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", stateDir])

    FileView {
        path: win.stateDir + "/launcher.json"
        watchChanges: false
        printErrors: false
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }
        JsonAdapter {
            id: usage
            property var counts: ({})
            property var last: ({})
        }
    }

    function rank(id) {
        const c = usage.counts[id] || 0;
        return Math.min(10, Math.ceil(Math.sqrt(c) * 2));
    }
    function ago(t) {
        if (!t)
            return "NUNCA";
        const m = Math.round((Date.now() - t) / 60000);
        if (m < 1)
            return "AHORA";
        if (m < 60)
            return "HACE " + m + " MIN";
        const h = Math.round(m / 60);
        if (h < 24)
            return "HACE " + h + " H";
        const d = Math.round(h / 24);
        return d === 1 ? "AYER" : "HACE " + d + " DÍAS";
    }

    // ── Acciones ──
    onVisibleChanged: {
        if (!visible) {
            grab.active = false;
            return;
        }
        input.text = "";
        sel = 0;
        content.opacity = 0;        // oculto hasta que arranque la animación
        focusT.restart();
    }

    // El foco del teclado se pide cuando la ventana ya existe en pantalla
    HyprlandFocusGrab {
        id: grab
        windows: [win]
        onCleared: win.close()
    }

    Timer {
        id: focusT
        interval: 30
        onTriggered: {
            if (Config.animations) {
                popAnim.restart();
                for (let i = 0; i < pinRep.count; i++)
                    pinRep.itemAt(i).enter();
                for (let i = 0; i < coreRep.count; i++)
                    coreRep.itemAt(i).enter();
            } else {
                content.opacity = 1;
            }
            grab.active = true;
            input.forceActiveFocus();
        }
    }

    function close() {
        grab.active = false;
        Ui.launcherScreen = "";
    }

    function launch(entry) {
        if (!entry)
            return;
        const c = Object.assign({}, usage.counts);
        c[entry.id] = (c[entry.id] || 0) + 1;
        usage.counts = c;
        const l = Object.assign({}, usage.last);
        l[entry.id] = Date.now();
        usage.last = l;
        entry.execute();
        close();
    }
    function runCore(i) {
        if (i === 0) {           // Terminal
            close();
            Quickshell.execDetached(["foot"]);
        }
        if (i === 1) {           // Ajustes
            const s = win.screen.name;
            close();
            Ui.settingsScreen = s;
        }
    }

    // ═══════════ Fondo ═══════════
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }
    }

    // ═══════════ Contenido ═══════════
    Item {
        id: content
        anchors.fill: parent
        transformOrigin: Item.Center

        // Popup: el conjunto crece desde el centro
        ParallelAnimation {
            id: popAnim
            NumberAnimation {
                target: scrim
                property: "opacity"
                from: 0
                to: 1
                duration: 160
            }
            NumberAnimation {
                target: content
                property: "scale"
                from: 0.9
                to: 1
                duration: 240
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: content
                property: "opacity"
                from: 0
                to: 1
                duration: 160
            }
            NumberAnimation {
                target: box
                property: "scale"
                from: 0.5
                to: 1
                duration: 260
                easing.type: Easing.OutBack
            }
        }

        // ── Buscador: carta de aviso ──
        Item {
            id: search
            anchors.horizontalCenter: parent.horizontalCenter
            y: (win.query ? 150 : 390) * win.sy
            Behavior on y {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
            width: box.width
            height: lbl.height + 10 + box.height

            Text {
                id: lbl
                anchors.horizontalCenter: parent.horizontalCenter
                text: "BUSCAR // APPS"
                color: Theme.telemetry
                font {
                    family: "JetBrains Mono"
                    pixelSize: 9
                    bold: true
                    letterSpacing: 2
                }
            }

            Item {
                id: box
                y: lbl.height + 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(520, letters.width + 80)
                height: 76
                transformOrigin: Item.Center
                Behavior on width {
                    NumberAnimation {
                        duration: 80
                    }
                }

                Slant {
                    x: 12
                    y: 12
                    width: parent.width
                    height: parent.height
                    skew: -0.14
                    color: Theme.accent2
                }
                Slant {
                    x: 6
                    y: 6
                    width: parent.width
                    height: parent.height
                    skew: -0.14
                    color: Theme.accent
                }
                Slant {
                    anchors.fill: parent
                    skew: -0.14
                    color: Qt.alpha(Theme.ink, 0.96)
                    borderWidth: 2
                    borderColor: Theme.paper
                }

                Row {
                    id: letters
                    anchors.centerIn: parent
                    spacing: 3

                    Text {
                        visible: win.query === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ESCRIBE O PULSA 1–5"
                        color: Qt.alpha(Theme.paper, 0.45)
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 14
                            bold: true
                            letterSpacing: 3
                        }
                    }

                    Repeater {
                        model: win.query.toUpperCase().split("")
                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            readonly property bool space: modelData === " "
                            readonly property int kind: (index * 7 + modelData.charCodeAt(0)) % 3
                            readonly property int f: (index + modelData.charCodeAt(0)) % 3
                            readonly property color tone: Theme.at(index)

                            width: space ? 16 : t.implicitWidth + 16
                            height: t.implicitHeight + 4
                            y: (letters.height - height) / 2 + (index % 2 ? -3 : 3)
                            rotation: [-6, 4, -2, 7, -4, 3, -7, 2][index % 8]
                            antialiasing: true
                            color: space ? "transparent" : kind === 0 ? Theme.paper : kind === 1 ? Theme.ink : tone
                            border.width: !space && kind === 1 ? 2 : 0
                            border.color: Theme.paper

                            Text {
                                id: t
                                anchors.centerIn: parent
                                text: parent.space ? "" : parent.modelData
                                color: parent.kind === 0 ? Theme.ink : parent.kind === 1 ? Theme.paper : Theme.on(parent.tone)
                                font {
                                    family: ["Bebas Neue", "JetBrains Mono", "Montserrat"][parent.f]
                                    weight: [Font.Normal, Font.ExtraBold, Font.Black][parent.f]
                                    pixelSize: [46, 36, 40, 50, 38, 44][parent.index % 6]
                                }
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "▋"
                        color: Theme.accent3
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 30
                        }
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 0
                                duration: 0
                            }
                            PauseAnimation {
                                duration: 500
                            }
                            NumberAnimation {
                                to: 1
                                duration: 0
                            }
                            PauseAnimation {
                                duration: 500
                            }
                        }
                    }
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    opacity: 0
                    focus: true
                    onTextChanged: {
                        win.query = text;
                        win.sel = 0;
                    }
                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Escape) {
                            win.close();
                        } else if (e.key === Qt.Key_Down) {
                            win.sel = Math.min(win.sel + 1, Math.max(0, win.results.length - 1));
                        } else if (e.key === Qt.Key_Up) {
                            win.sel = Math.max(0, win.sel - 1);
                        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            win.launch(win.current);
                        } else if (win.query === "" && e.key >= Qt.Key_1 && e.key <= Qt.Key_6) {
                            const n = e.key - Qt.Key_1;
                            if (n < 4)
                                win.launch(win.pinEntries[n] ?? null);
                            else
                                win.runCore(n - 4);
                        } else {
                            return;
                        }
                        e.accepted = true;
                    }
                }
            }
        }

        // ── Sin escribir: favoritas + fijas ──
        Item {
            id: slots
            anchors.fill: parent
            visible: win.query === ""

            // Centro de la pantalla: origen de la animación
            readonly property real ox: (win.screen?.width ?? 1920) / 2 - 125
            readonly property real oy: (win.screen?.height ?? 1080) / 2 - 31

            Repeater {
                id: pinRep
                model: win.pinEntries
                delegate: Slab {
                    required property var modelData
                    required property int index
                    readonly property var p: win.favSpots[index]
                    tx: p.x * slots.width + win.favOffset.x
                    ty: p.y * slots.height + win.favOffset.y
                    ox: slots.ox
                    oy: slots.oy
                    rot: p.rot
                    s: p.s
                    order: index
                    key: (index + 1).toString()
                    label: modelData.name.toUpperCase()
                    meta: (modelData.genericName || "APP").toUpperCase()
                    tone: Theme.at(index)
                    iconSource: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    onClicked: win.launch(modelData)
                }
            }

            Repeater {
                id: coreRep
                model: win.core
                delegate: Slab {
                    required property var modelData
                    required property int index
                    readonly property var p: win.coreSpots[index]
                    tx: p.x * slots.width + win.coreOffset.x
                    ty: p.y * slots.height + win.coreOffset.y
                    ox: slots.ox
                    oy: slots.oy
                    rot: p.rot
                    s: p.s
                    order: index + 4
                    core: true
                    key: modelData.key
                    label: modelData.label
                    meta: modelData.meta
                    tone: Theme.at(index + 1)
                    onClicked: win.runCore(index)
                }
            }
        }

        // ── Con búsqueda: ficha del seleccionado ──
        Item {
            id: card
            visible: win.query !== "" && win.current !== null
            x: 200 * win.sx
            y: 300 * win.sy
            width: 420
            height: 400

            Shape {
                x: 10
                y: 10
                width: parent.width
                height: parent.height
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Theme.accent2
                    strokeColor: "transparent"
                    startX: 0
                    startY: 0
                    PathLine {
                        x: card.width
                        y: 0
                    }
                    PathLine {
                        x: card.width
                        y: card.height
                    }
                    PathLine {
                        x: card.width * 0.08
                        y: card.height
                    }
                    PathLine {
                        x: 0
                        y: 0
                    }
                }
            }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Qt.alpha(Theme.surface, 0.97)
                    strokeColor: "transparent"
                    startX: 0
                    startY: 0
                    PathLine {
                        x: card.width
                        y: 0
                    }
                    PathLine {
                        x: card.width
                        y: card.height
                    }
                    PathLine {
                        x: card.width * 0.08
                        y: card.height
                    }
                    PathLine {
                        x: 0
                        y: 0
                    }
                }
            }

            Column {
                x: 44
                y: 28
                width: parent.width - 74
                spacing: 14

                Row {
                    spacing: 18
                    Item {
                        width: 92
                        height: 92
                        Slant {
                            anchors.fill: parent
                            skew: -0.14
                            color: Theme.paper
                        }
                        Slant {
                            width: 5
                            height: parent.height
                            skew: -0.14
                            color: Theme.accent
                        }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 56
                            source: Quickshell.iconPath(win.current?.icon ?? "", "application-x-executable")
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: card.width - 74 - 110
                        spacing: 6
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: "APP · " + (win.current?.genericName ?? "").toUpperCase()
                            color: Theme.telemetry
                            font {
                                family: "JetBrains Mono"
                                pixelSize: 9
                                bold: true
                                letterSpacing: 2
                            }
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            text: (win.current?.name ?? "").toUpperCase()
                            color: Theme.paper
                            font {
                                family: "Bebas Neue"
                                pixelSize: 34
                                letterSpacing: 2
                            }
                        }
                    }
                }

                Row {
                    spacing: 12
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "RANGO"
                        color: Theme.telemetry
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 9
                            bold: true
                            letterSpacing: 2
                        }
                    }
                    SegBar {
                        anchors.verticalCenter: parent.verticalCenter
                        count: 10
                        segW: 14
                        segH: 12
                        gap: 3
                        value: win.current ? win.rank(win.current.id) / 10 : 0
                        fill: Theme.accent3
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (win.current ? win.rank(win.current.id) : 0) + "/10"
                        color: Theme.paper
                        font {
                            family: "Bebas Neue"
                            pixelSize: 22
                            letterSpacing: 1
                        }
                    }
                }

                Text {
                    text: "ÚLTIMA VEZ // " + win.ago(win.current ? usage.last[win.current.id] : 0)
                    color: Qt.alpha(Theme.paper, 0.7)
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 10
                        bold: true
                        letterSpacing: 1
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 2
                    color: Qt.alpha(Theme.paper, 0.15)
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    text: win.current?.comment ?? ""
                    color: Qt.alpha(Theme.paper, 0.8)
                    font {
                        family: "Montserrat"
                        pixelSize: 13
                    }
                }
            }
        }

        // ── Con búsqueda: resultados escalonados ──
        Column {
            visible: win.query !== ""
            x: 700 * win.sx
            y: 300 * win.sy
            spacing: 10

            Text {
                text: win.results.length + " RESULTADOS"
                color: Theme.telemetry
                font {
                    family: "JetBrains Mono"
                    pixelSize: 9
                    bold: true
                    letterSpacing: 2
                }
            }
            Repeater {
                model: win.results
                delegate: ResultRow {
                    required property var modelData
                    required property int index
                    x: index * 16
                    entry: modelData
                    order: index
                    active: win.sel === index
                    onPicked: win.sel = index
                    onLaunched: win.launch(modelData)
                }
            }
            Text {
                visible: win.results.length === 0
                text: "SIN RESULTADOS"
                color: Qt.alpha(Theme.paper, 0.5)
                font {
                    family: "Bebas Neue"
                    pixelSize: 30
                    letterSpacing: 2
                }
            }
        }
    }
}
