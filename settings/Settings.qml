import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Shapes
import "../config"
import "../components"
import "../services"
import "../clip"

// Ajustes de velvet: P3 (menú en banda azul) × P4 (televisor) × P5 (recortes)
// qs -c velvet ipc call settings toggle
PanelWindow {
    id: win
    visible: Ui.settingsScreen !== "" && Ui.settingsScreen === (screen?.name ?? "")
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "velvet-settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    readonly property var sections: [
        {
            name: "APARIENCIA",
            sub: "FONDO · PANELES · MOVIMIENTO"
        },
        {
            name: "LANZADOR",
            sub: "FAVORITAS POR MODO · RANGO"
        },
        {
            name: "ENERGÍA",
            sub: "PERFIL · BLOQUEO · PANTALLA",
            perMode: true
        },
        {
            name: "NOTIFICACIONES",
            sub: "NO MOLESTAR · DURACIÓN",
            perMode: true
        },
        {
            name: "MODO",
            sub: "APPS AL ENTRAR",
            perMode: true
        }
    ]
    // Subtítulo de la sección; las que van por modo dicen de cuál
    function secSub(i) {
        const s = sections[i];
        return s.sub + (s.perMode ? " · MODO " + Theme.mode.toUpperCase() : "");
    }

    // ── Modo: apps al entrar ──
    property int appSlot: -1
    function setApp(i, entry) {
        const arr = JSON.parse(JSON.stringify(Config.apps));
        const ws = arr[i]?.ws ?? (i + 1);
        arr[i] = {
            id: entry.id,
            ws: ws
        };
        Config.setForMode("apps", arr.filter(a => a));
        appSlot = -1;
        say("ENTRADA " + (i + 1) + " → " + entry.name.toUpperCase());
    }
    function setAppWs(i, ws) {
        const arr = JSON.parse(JSON.stringify(Config.apps));
        if (!arr[i])
            return;
        arr[i].ws = ws;
        Config.setForMode("apps", arr);
    }
    function removeApp(i) {
        const arr = JSON.parse(JSON.stringify(Config.apps));
        arr.splice(i, 1);
        Config.setForMode("apps", arr);
        appSlot = -1;
    }
    property int sec: 0
    readonly property color tone: Theme.at(sec)

    // ── Lanzador: edición de favoritas ──
    property string favMode: Theme.mode
    property int pickSlot: -1        // tecla que se está cambiando (-1 = ninguna)
    property string pickQuery: ""

    function findApp(q) {
        const apps = DesktopEntries.applications.values;
        const k = q.toLowerCase();
        return apps.find(e => e.id.toLowerCase() === k) ?? apps.find(e => e.name.toLowerCase() === k) ?? apps.find(e => e.id.toLowerCase().includes(k)) ?? apps.find(e => e.name.toLowerCase().includes(k)) ?? null;
    }
    readonly property var favEntries: (Config.pins[favMode] ?? []).map(id => findApp(id))
    readonly property var pickResults: {
        const q = pickQuery.trim().toLowerCase();
        if (!q)
            return [];
        return DesktopEntries.applications.values.filter(e => !e.noDisplay && (e.name.toLowerCase().includes(q) || e.id.toLowerCase().includes(q) || (e.genericName || "").toLowerCase().includes(q) || (e.keywords || []).some(k => k.toLowerCase().includes(q)))).slice(0, 5);
    }
    function setPin(i, entry) {
        const p = JSON.parse(JSON.stringify(Config.pins));
        if (!p[favMode])
            p[favMode] = [];
        p[favMode][i] = entry.id;
        Config.pins = p;
        pickSlot = -1;
        say("TECLA " + (i + 1) + " → " + entry.name.toUpperCase());
    }

    // ── Avisos ──
    property string flash: ""
    function say(t) {
        flash = t;
        flashT.restart();
    }
    Timer {
        id: flashT
        interval: 1400
        onTriggered: win.flash = ""
    }

    // hypridle se regenera un momento después del último cambio
    Timer {
        id: idleT
        interval: 700
        onTriggered: {
            Config.applyIdle();
            win.say("HYPRIDLE ACTUALIZADO");
        }
    }

    // ── Fecha (P3) ──
    property var now: new Date()
    readonly property string dayName: Qt.locale("es_ES").dayName(now.getDay(), Locale.ShortFormat).replace(".", "").toUpperCase()
    readonly property string dayPart: {
        const h = now.getHours();
        return h < 6 ? "MADRUGADA" : h < 12 ? "MAÑANA" : h < 20 ? "TARDE" : "NOCHE";
    }

    // ── Abrir / cerrar ──
    function close() {
        grab.active = false;
        Ui.settingsScreen = "";
    }
    onVisibleChanged: {
        if (!visible) {
            grab.active = false;
            return;
        }
        now = new Date();
        favMode = Theme.mode;
        pickSlot = -1;
        appSlot = -1;
        flash = "";
        focusT.restart();
    }
    HyprlandFocusGrab {
        id: grab
        windows: [win]
        onCleared: win.close()
    }
    Timer {
        id: focusT
        interval: 30
        onTriggered: {
            if (Config.animations)
                popAnim.restart();
            grab.active = true;
            keys.forceActiveFocus();
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape)
                win.close();
            else if (e.key === Qt.Key_Up)
                win.sec = Math.max(0, win.sec - 1);
            else if (e.key === Qt.Key_Down)
                win.sec = Math.min(win.sections.length - 1, win.sec + 1);
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_5)
                win.sec = e.key - Qt.Key_1;
            else
                return;
            win.pickSlot = -1;
            win.appSlot = -1;
            e.accepted = true;
        }
    }

    // Velo
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.canvas, 0.93)
    }

    // Escenario de 1600×900, escalado a la pantalla
    Item {
        id: stage
        width: 1600
        height: 900
        anchors.centerIn: parent
        scale: Math.min((win.screen?.width ?? 1600) / 1600, (win.screen?.height ?? 900) / 900)

        ParallelAnimation {
            id: popAnim
            NumberAnimation {
                target: stage
                property: "opacity"
                from: 0
                to: 1
                duration: 160
            }
            NumberAnimation {
                target: tv
                property: "x"
                from: 680
                to: 600
                duration: 260
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: band
                property: "x"
                from: -120
                to: 0
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        // ═══════════ P3: banda azul ═══════════
        Item {
            id: band
            width: 600
            height: 900

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Theme.accent2
                    strokeColor: "transparent"
                    PathPolyline {
                        path: [Qt.point(0, 0), Qt.point(560, 0), Qt.point(437, 900), Qt.point(0, 900), Qt.point(0, 0)]
                    }
                }
                ShapePath {
                    fillColor: Theme.ink
                    strokeColor: "transparent"
                    PathPolyline {
                        path: [Qt.point(560, 0), Qt.point(584, 0), Qt.point(461, 900), Qt.point(437, 900), Qt.point(560, 0)]
                    }
                }
            }
            // Reflejo de agua
            Repeater {
                model: 100
                Rectangle {
                    required property int index
                    y: index * 9
                    width: 560 - 123 * y / 900
                    height: 2
                    color: Qt.alpha("#FFFFFF", 0.07)
                }
            }

            // P5: título recortado
            Column {
                x: 52
                y: 46
                spacing: 14
                Text {
                    text: "VELVET // CONFIGURACIÓN · MODE." + Theme.mode.toUpperCase()
                    color: Theme.paper
                    opacity: 0.85
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 10
                        weight: Font.ExtraBold
                        letterSpacing: 2
                    }
                }
                Row {
                    spacing: 4
                    Repeater {
                        model: "AJUSTES".split("")
                        Rectangle {
                            required property string modelData
                            required property int index
                            readonly property int kind: index % 3
                            readonly property color c: Theme.at(index)
                            width: lt.implicitWidth + 18
                            height: lt.implicitHeight + 4
                            y: index % 2 ? -4 : 4
                            rotation: [-5, 4, -2, 6, -4, 3, -6][index]
                            antialiasing: true
                            color: kind === 0 ? Theme.paper : kind === 1 ? Theme.ink : c
                            border.width: kind === 1 ? 3 : 0
                            border.color: Theme.paper
                            Text {
                                id: lt
                                anchors.centerIn: parent
                                text: parent.modelData
                                color: parent.kind === 0 ? Theme.ink : parent.kind === 1 ? Theme.paper : Theme.on(parent.c)
                                font {
                                    family: ["JetBrains Mono", "Montserrat", "Bebas Neue"][parent.index % 3]
                                    weight: [Font.ExtraBold, Font.Black, Font.Normal][parent.index % 3]
                                    pixelSize: [64, 50, 58, 70, 52, 62, 56][parent.index]
                                }
                            }
                        }
                    }
                }
            }

            // Menú de secciones
            Column {
                x: 44
                y: 214
                spacing: 8
                Repeater {
                    model: win.sections
                    MenuEntry {
                        required property var modelData
                        required property int index
                        x: active ? 26 : index * 6
                        code: "0" + (index + 1)
                        name: modelData.name
                        sub: win.secSub(index)
                        active: win.sec === index
                        tone: Theme.at(index)
                        onClicked: {
                            win.sec = index;
                            win.pickSlot = -1;
                            win.appSlot = -1;
                        }
                    }
                }
            }

            // Fecha grande
            Row {
                x: 52
                y: 900 - 40 - height
                spacing: 14
                Text {
                    anchors.bottom: parent.bottom
                    text: Qt.formatDate(win.now, "dd.MM")
                    color: Theme.paper
                    font {
                        family: "Bebas Neue"
                        pixelSize: 96
                    }
                    lineHeight: 0.8
                }
                Column {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    spacing: 4
                    Rectangle {
                        width: dn.implicitWidth + 16
                        height: dn.implicitHeight
                        color: Theme.paper
                        Text {
                            id: dn
                            anchors.centerIn: parent
                            text: win.dayName
                            color: Theme.accent2
                            font {
                                family: "Bebas Neue"
                                pixelSize: 30
                                letterSpacing: 2
                            }
                        }
                    }
                    Text {
                        text: win.dayPart
                        color: Theme.paper
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 9
                            weight: Font.ExtraBold
                            letterSpacing: 2
                        }
                    }
                }
            }
        }

        // ═══════════ P4: televisor ═══════════
        Item {
            id: tv
            x: 600
            y: 72
            width: 950
            height: 716

            // Sombra dura del color de la sección
            Rectangle {
                x: 12
                y: 12
                width: parent.width
                height: parent.height
                radius: 22
                color: win.tone
            }
            Rectangle {
                id: screenBox
                anchors.fill: parent
                radius: 22
                color: Qt.alpha(Theme.ink, 0.97)
                border.width: 3
                border.color: Theme.accent3
                clip: true

                // Líneas de barrido
                Repeater {
                    model: 179
                    Rectangle {
                        required property int index
                        y: index * 4
                        width: screenBox.width
                        height: 1
                        color: Qt.alpha(Theme.paper, 0.03)
                    }
                }

                // Cabecera del canal
                Item {
                    x: 3
                    y: 3
                    width: parent.width - 6
                    height: 46
                    clip: true
                    Rectangle {
                        width: parent.width
                        height: 80
                        radius: 19
                        color: Theme.accent3
                    }
                    Text {
                        x: 26
                        anchors.verticalCenter: parent.verticalCenter
                        text: "◤ CANAL 05 // AJUSTES.0" + (win.sec + 1)
                        color: Theme.on(Theme.accent3)
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 11
                            weight: Font.ExtraBold
                            letterSpacing: 2
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 26
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10
                            height: 10
                            radius: 5
                            color: Theme.accent
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                PauseAnimation {
                                    duration: 600
                                }
                                NumberAnimation {
                                    to: 0
                                    duration: 0
                                }
                                PauseAnimation {
                                    duration: 600
                                }
                                NumberAnimation {
                                    to: 1
                                    duration: 0
                                }
                            }
                        }
                        Text {
                            text: "EN EMISIÓN"
                            color: Theme.on(Theme.accent3)
                            font {
                                family: "JetBrains Mono"
                                pixelSize: 11
                                weight: Font.ExtraBold
                                letterSpacing: 2
                            }
                        }
                    }
                }

                // P5: etiqueta de la sección
                Row {
                    x: 34
                    y: 76
                    spacing: 22
                    Item {
                        width: tagT.implicitWidth + 44
                        height: 64
                        rotation: -2
                        Slant {
                            x: 7
                            y: 7
                            width: parent.width
                            height: parent.height
                            skew: -0.18
                            color: Theme.paper
                        }
                        Slant {
                            anchors.fill: parent
                            skew: -0.18
                            color: win.tone
                        }
                        Text {
                            id: tagT
                            anchors.centerIn: parent
                            text: win.sections[win.sec].name
                            color: Theme.on(win.tone)
                            font {
                                family: "Bebas Neue"
                                pixelSize: 56
                                letterSpacing: 3
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.secSub(win.sec)
                        color: Theme.telemetry
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 10
                            bold: true
                            letterSpacing: 2
                        }
                    }
                }

                // ── Filas ──
                Item {
                    x: 44
                    y: 168
                    width: parent.width - 88
                    height: 470

                    // 01 APARIENCIA
                    Column {
                        visible: win.sec === 0
                        width: parent.width
                        SetRow {
                            label: "FONDO DE PANTALLA"
                            desc: "CAMBIA SOLO CON EL MODO ACTIVO"
                            Row {
                                spacing: 16
                                Item {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 168
                                    height: 94
                                    Image {
                                        anchors.fill: parent
                                        source: Wallpapers.current ? "file://" + Wallpapers.current : ""
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 336
                                        asynchronous: true
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"
                                        border.width: 2
                                        border.color: Theme.paper
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 130
                                    wrapMode: Text.WrapAnywhere
                                    text: Wallpapers.current.split("/").pop()
                                    color: Theme.telemetry
                                    font {
                                        family: "JetBrains Mono"
                                        pixelSize: 10
                                        bold: true
                                        letterSpacing: 1
                                    }
                                }
                                SkewChip {
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: "ELEGIR FONDO ▶"
                                    fill: Theme.paper
                                    shadow: win.tone
                                    size: 23
                                    padding: 22
                                    height: 44
                                    onClicked: {
                                        const s = win.screen.name;
                                        win.close();
                                        Ui.wallpaperScreen = s;
                                    }
                                }
                            }
                        }
                        SetRow {
                            label: "ANIMACIONES"
                            desc: "ENTRADAS Y BARRIDOS DE LOS PANELES"
                            Choice {
                                tone: win.tone
                                options: [
                                    {
                                        label: "SÍ",
                                        value: true
                                    },
                                    {
                                        label: "NO",
                                        value: false
                                    }
                                ]
                                value: Config.animations
                                onPicked: v => Config.animations = v
                            }
                        }
                        SetRow {
                            label: "TEXTO ADAPTATIVO"
                            desc: "LEE EL FONDO Y AJUSTA EL CONTRASTE DE LA BARRA"
                            Choice {
                                tone: win.tone
                                options: [
                                    {
                                        label: "SÍ",
                                        value: true
                                    },
                                    {
                                        label: "NO",
                                        value: false
                                    }
                                ]
                                value: Config.adaptiveText
                                onPicked: v => Config.adaptiveText = v
                            }
                        }
                        SetRow {
                            label: "LUZ NOCTURNA"
                            desc: "HYPRSUNSET · POR MODO (" + Theme.mode.toUpperCase() + ")"
                            Choice {
                                tone: win.tone
                                options: [
                                    {
                                        label: "SÍ",
                                        value: true
                                    },
                                    {
                                        label: "NO",
                                        value: false
                                    }
                                ]
                                value: Config.nightLight
                                onPicked: v => {
                                    Config.setForMode("night", v);
                                    ModeApply.applyNight();
                                }
                            }
                        }
                    }

                    // 02 LANZADOR
                    Column {
                        visible: win.sec === 1
                        width: parent.width
                        SetRow {
                            label: "FAVORITAS"
                            desc: "TECLAS 1–4 DEL LANZADOR, POR MODO"
                            Choice {
                                tone: win.tone
                                options: ["general", "dev", "art", "game"].map(m => ({
                                            label: m.toUpperCase(),
                                            value: m
                                        }))
                                value: win.favMode
                                onPicked: v => {
                                    win.favMode = v;
                                    win.pickSlot = -1;
                                }
                            }
                        }
                        Grid {
                            columns: 2
                            columnSpacing: 30
                            rowSpacing: 22
                            topPadding: 26
                            bottomPadding: 18
                            leftPadding: 6
                            Repeater {
                                model: 4
                                Item {
                                    id: slot
                                    required property int index
                                    readonly property var entry: win.favEntries[index] ?? null
                                    readonly property bool on: win.pickSlot === index
                                    readonly property color c: Theme.at(index)
                                    width: 380
                                    height: 64
                                    rotation: [-2, 1.5, 1, -1.5][index]

                                    Slant {
                                        x: 6
                                        y: 6
                                        width: parent.width
                                        height: parent.height
                                        color: slot.c
                                    }
                                    Slant {
                                        anchors.fill: parent
                                        color: slot.on ? Theme.paper : Qt.alpha(Theme.ink, 0.95)
                                        borderWidth: 2
                                        borderColor: slot.on ? Theme.paper : Qt.alpha(Theme.paper, 0.7)
                                        Row {
                                            x: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 12
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 34
                                                height: 34
                                                color: slot.c
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: slot.index + 1
                                                    color: Theme.on(slot.c)
                                                    font {
                                                        family: "JetBrains Mono"
                                                        pixelSize: 16
                                                        weight: Font.ExtraBold
                                                    }
                                                }
                                            }
                                            IconImage {
                                                anchors.verticalCenter: parent.verticalCenter
                                                implicitSize: 24
                                                source: Quickshell.iconPath(slot.entry?.icon ?? "", "application-x-executable")
                                            }
                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 2
                                                Text {
                                                    width: 250
                                                    elide: Text.ElideRight
                                                    text: (slot.entry?.name ?? "VACÍA").toUpperCase()
                                                    color: slot.on ? Theme.ink : Theme.paper
                                                    font {
                                                        family: "Bebas Neue"
                                                        pixelSize: 28
                                                        letterSpacing: 2
                                                    }
                                                }
                                                Text {
                                                    text: slot.on ? "ESCRIBE PARA BUSCAR APP" : "CLIC PARA CAMBIAR"
                                                    color: slot.on ? Theme.ink : Theme.paper
                                                    opacity: 0.7
                                                    font {
                                                        family: "JetBrains Mono"
                                                        pixelSize: 9
                                                        bold: true
                                                        letterSpacing: 1.5
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            win.pickSlot = slot.on ? -1 : slot.index;
                                            if (win.pickSlot >= 0) {
                                                pickBox.text = "";
                                                pickBox.input.forceActiveFocus();
                                            } else {
                                                keys.forceActiveFocus();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Buscador de app para la tecla elegida
                        Row {
                            visible: win.pickSlot >= 0
                            spacing: 14
                            topPadding: 10
                            SearchBox {
                                id: pickBox
                                width: 320
                                accent: win.tone
                                placeholder: "app para la tecla " + (win.pickSlot + 1) + "…"
                                onTextChanged: win.pickQuery = text
                                onKeyPressed: e => {
                                    if (e.key === Qt.Key_Escape) {
                                        win.pickSlot = -1;
                                        keys.forceActiveFocus();
                                        e.accepted = true;
                                    } else if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && win.pickResults.length) {
                                        win.setPin(win.pickSlot, win.pickResults[0]);
                                        keys.forceActiveFocus();
                                        e.accepted = true;
                                    }
                                }
                            }
                            Repeater {
                                model: win.pickResults
                                SkewChip {
                                    required property var modelData
                                    required property int index
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: modelData.name.toUpperCase()
                                    fill: index === 0 ? win.tone : "transparent"
                                    fg: index === 0 ? Theme.on(win.tone) : Theme.paper
                                    border: index === 0 ? win.tone : Qt.alpha(Theme.paper, 0.35)
                                    size: 19
                                    height: 36
                                    onClicked: {
                                        win.setPin(win.pickSlot, modelData);
                                        keys.forceActiveFocus();
                                    }
                                }
                            }
                        }

                        SetRow {
                            visible: win.pickSlot < 0
                            label: "ORDENAR BÚSQUEDA POR USO"
                            desc: "EL RANGO SUBE CADA VEZ QUE ABRES UNA APP"
                            Choice {
                                tone: win.tone
                                options: [
                                    {
                                        label: "SÍ",
                                        value: true
                                    },
                                    {
                                        label: "NO",
                                        value: false
                                    }
                                ]
                                value: Config.rankSort
                                onPicked: v => Config.rankSort = v
                            }
                        }
                    }

                    // 03 ENERGÍA
                    Column {
                        visible: win.sec === 2
                        width: parent.width
                        SetRow {
                            label: "PERFIL DE ENERGÍA"
                            desc: "POWER-PROFILES-DAEMON"
                            Choice {
                                tone: win.tone
                                options: [
                                    {
                                        label: "AHORRO",
                                        value: "power-saver"
                                    },
                                    {
                                        label: "EQUILIBRADO",
                                        value: "balanced"
                                    }
                                ].concat(PowerProfiles.hasPerformanceProfile ? [
                                    {
                                        label: "RENDIMIENTO",
                                        value: "performance"
                                    }
                                ] : [])
                                value: Config.profile
                                onPicked: v => {
                                    Config.setForMode("profile", v);
                                    ModeApply.applyProfile();
                                }
                            }
                        }
                        SetRow {
                            label: "BLOQUEAR TRAS"
                            desc: "HYPRIDLE · TIEMPO SIN USO"
                            Stepper {
                                value: Config.lockMin
                                from: 0
                                to: 60
                                unit: "MIN"
                                zeroLabel: "NUNCA"
                                onStepped: v => {
                                    Config.setForMode("lock", v);
                                    idleT.restart();
                                }
                            }
                        }
                        SetRow {
                            label: "APAGAR PANTALLA TRAS"
                            desc: "HYPRIDLE · DPMS"
                            Stepper {
                                value: Config.dpmsMin
                                from: 0
                                to: 120
                                unit: "MIN"
                                zeroLabel: "NUNCA"
                                onStepped: v => {
                                    Config.setForMode("dpms", v);
                                    idleT.restart();
                                }
                            }
                        }
                        SetRow {
                            label: "SUSPENDER TRAS"
                            desc: "HYPRIDLE · SYSTEMCTL SUSPEND"
                            Choice {
                                tone: win.tone
                                options: [
                                    {
                                        label: "30 MIN",
                                        value: 30
                                    },
                                    {
                                        label: "1 H",
                                        value: 60
                                    },
                                    {
                                        label: "NUNCA",
                                        value: 0
                                    }
                                ]
                                value: Config.sleepMin
                                onPicked: v => {
                                    Config.setForMode("sleep", v);
                                    idleT.restart();
                                }
                            }
                        }
                        SetRow {
                            label: "GAMEMODE"
                            desc: "FERAL GAMEMODE · CPU Y GPU A TOPE"
                            Choice {
                                tone: win.tone
                                options: [
                                    {
                                        label: "SÍ",
                                        value: true
                                    },
                                    {
                                        label: "NO",
                                        value: false
                                    }
                                ]
                                value: Config.gamemode
                                onPicked: v => {
                                    Config.setForMode("gamemode", v);
                                    ModeApply.applyGamemode();
                                }
                            }
                        }
                    }

                    // 04 NOTIFICACIONES
                    Column {
                        visible: win.sec === 3
                        width: parent.width
                        SetRow {
                            label: "NO MOLESTAR"
                            desc: "SOLO PASAN LAS CRÍTICAS (BANDA ROJA)"
                            Choice {
                                tone: win.tone
                                options: [
                                    {
                                        label: "SÍ",
                                        value: true
                                    },
                                    {
                                        label: "NO",
                                        value: false
                                    }
                                ]
                                value: Config.dnd
                                onPicked: v => Config.setForMode("dnd", v)
                            }
                        }
                        SetRow {
                            label: "DURACIÓN EN PANTALLA"
                            desc: "BURBUJAS NORMALES"
                            Stepper {
                                value: Config.notifSecs
                                from: 2
                                to: 30
                                unit: "S"
                                onStepped: v => Config.notifSecs = v
                            }
                        }
                        SetRow {
                            label: "HISTORIAL DE AVISOS"
                            desc: "LOS QUE SE GUARDAN EN EL CONTADOR DE LA BARRA"
                            SkewChip {
                                label: "BORRAR TODOS ▶"
                                fill: Theme.paper
                                shadow: win.tone
                                size: 23
                                padding: 22
                                height: 44
                                onClicked: {
                                    Notifs.clearAll();
                                    win.say("AVISOS BORRADOS");
                                }
                            }
                        }
                    }

                    // 05 MODO: apps al entrar
                    Column {
                        visible: win.sec === 4
                        width: parent.width
                        spacing: 18
                        Text {
                            text: "SE ABREN AL CAMBIAR A ESTE MODO (SI NO ESTÁN YA ABIERTAS) // MÁX. 4"
                            color: Theme.telemetry
                            topPadding: 6
                            font {
                                family: "JetBrains Mono"
                                pixelSize: 10
                                bold: true
                                letterSpacing: 1.5
                            }
                        }
                        Repeater {
                            model: Math.min(4, Config.apps.length + 1)
                            Item {
                                id: arow
                                required property int index
                                readonly property var app: Config.apps[index] ?? null
                                readonly property var entry: app ? win.findApp(app.id) : null
                                readonly property bool on: win.appSlot === index
                                readonly property color c: Theme.at(index)
                                width: parent.width
                                height: 64

                                Item {
                                    width: 420
                                    height: 58
                                    rotation: [-1.5, 1, -1, 1.5][arow.index]
                                    Slant {
                                        x: 6
                                        y: 6
                                        width: parent.width
                                        height: parent.height
                                        color: arow.c
                                    }
                                    Slant {
                                        anchors.fill: parent
                                        color: arow.on ? Theme.paper : Qt.alpha(Theme.ink, 0.95)
                                        borderWidth: 2
                                        borderColor: arow.on ? Theme.paper : Qt.alpha(Theme.paper, arow.app ? 0.7 : 0.3)
                                        Row {
                                            x: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 12
                                            IconImage {
                                                visible: arow.entry !== null
                                                anchors.verticalCenter: parent.verticalCenter
                                                implicitSize: 24
                                                source: Quickshell.iconPath(arow.entry?.icon ?? "", "application-x-executable")
                                            }
                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 2
                                                Text {
                                                    width: 330
                                                    elide: Text.ElideRight
                                                    text: arow.app ? (arow.entry?.name ?? arow.app.id).toUpperCase() : "+ AÑADIR APP"
                                                    color: arow.on ? Theme.ink : Theme.paper
                                                    opacity: arow.app ? 1 : 0.6
                                                    font {
                                                        family: "Bebas Neue"
                                                        pixelSize: 26
                                                        letterSpacing: 2
                                                    }
                                                }
                                                Text {
                                                    text: arow.on ? "ESCRIBE PARA BUSCAR APP" : "CLIC PARA CAMBIAR"
                                                    color: arow.on ? Theme.ink : Theme.paper
                                                    opacity: 0.7
                                                    font {
                                                        family: "JetBrains Mono"
                                                        pixelSize: 9
                                                        bold: true
                                                        letterSpacing: 1.5
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            win.pickSlot = -1;
                                            win.appSlot = arow.on ? -1 : arow.index;
                                            if (win.appSlot >= 0) {
                                                appBox.text = "";
                                                appBox.input.forceActiveFocus();
                                            } else {
                                                keys.forceActiveFocus();
                                            }
                                        }
                                    }
                                }

                                Row {
                                    visible: arow.app !== null
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 14
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "ESPACIO"
                                        color: Theme.telemetry
                                        font {
                                            family: "JetBrains Mono"
                                            pixelSize: 10
                                            bold: true
                                            letterSpacing: 1.5
                                        }
                                    }
                                    Stepper {
                                        anchors.verticalCenter: parent.verticalCenter
                                        value: arow.app?.ws ?? 1
                                        from: 1
                                        to: 10
                                        unit: ""
                                        onStepped: v => win.setAppWs(arow.index, v)
                                    }
                                    SkewChip {
                                        anchors.verticalCenter: parent.verticalCenter
                                        label: "QUITAR"
                                        fill: "transparent"
                                        fg: Theme.paper
                                        border: Qt.alpha(Theme.paper, 0.35)
                                        size: 19
                                        height: 36
                                        onClicked: win.removeApp(arow.index)
                                    }
                                }
                            }
                        }

                        // Buscador de app para la entrada elegida
                        Row {
                            visible: win.appSlot >= 0
                            spacing: 14
                            SearchBox {
                                id: appBox
                                width: 320
                                accent: win.tone
                                placeholder: "app para la entrada " + (win.appSlot + 1) + "…"
                                onTextChanged: win.pickQuery = text
                                onKeyPressed: e => {
                                    if (e.key === Qt.Key_Escape) {
                                        win.appSlot = -1;
                                        keys.forceActiveFocus();
                                        e.accepted = true;
                                    } else if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && win.pickResults.length) {
                                        win.setApp(win.appSlot, win.pickResults[0]);
                                        keys.forceActiveFocus();
                                        e.accepted = true;
                                    }
                                }
                            }
                            Repeater {
                                model: win.appSlot >= 0 ? win.pickResults : []
                                SkewChip {
                                    required property var modelData
                                    required property int index
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: modelData.name.toUpperCase()
                                    fill: index === 0 ? win.tone : "transparent"
                                    fg: index === 0 ? Theme.on(win.tone) : Theme.paper
                                    border: index === 0 ? win.tone : Qt.alpha(Theme.paper, 0.35)
                                    size: 19
                                    height: 36
                                    onClicked: {
                                        keys.forceActiveFocus();
                                        win.setApp(win.appSlot, modelData);
                                    }
                                }
                            }
                        }
                    }
                }

                // Aviso
                Item {
                    visible: win.flash !== ""
                    anchors.right: parent.right
                    anchors.rightMargin: 34
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 62
                    width: flT.implicitWidth + 44
                    height: 46
                    Slant {
                        x: 6
                        y: 6
                        width: parent.width
                        height: parent.height
                        color: Theme.paper
                    }
                    Slant {
                        anchors.fill: parent
                        color: win.tone
                    }
                    Text {
                        id: flT
                        anchors.centerIn: parent
                        text: "▶▶ " + win.flash
                        color: Theme.on(win.tone)
                        font {
                            family: "Bebas Neue"
                            pixelSize: 24
                            letterSpacing: 2
                        }
                    }
                }

                Text {
                    x: 34
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 30
                    text: "LOS CAMBIOS SE GUARDAN AL INSTANTE // ~/.local/state/velvet/settings.json"
                    color: Theme.telemetry
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 9
                        bold: true
                        letterSpacing: 2
                    }
                }

                // Cinta de precaución
                Item {
                    x: 22
                    width: parent.width - 44
                    height: 16
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    clip: true
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.ink
                    }
                    Repeater {
                        model: 36
                        Rectangle {
                            required property int index
                            x: index * 28 - 20
                            y: -12
                            width: 14
                            height: 40
                            rotation: 45
                            antialiasing: true
                            color: Theme.accent3
                        }
                    }
                }
            }
        }

        // Barra de teclas
        Row {
            x: 600 + (950 - width) / 2
            y: 900 - 40 - height
            spacing: 28
            Repeater {
                model: [
                    {
                        k: "↑↓",
                        t: "SECCIÓN"
                    },
                    {
                        k: "1–5",
                        t: "IR A SECCIÓN"
                    },
                    {
                        k: "CLIC",
                        t: "CAMBIAR VALOR"
                    },
                    {
                        k: "ESC",
                        t: "CERRAR"
                    }
                ]
                Row {
                    id: hint
                    required property var modelData
                    spacing: 8
                    Rectangle {
                        width: hk.implicitWidth + 14
                        height: hk.implicitHeight + 6
                        color: Theme.paper
                        Text {
                            id: hk
                            anchors.centerIn: parent
                            text: hint.modelData.k
                            color: Theme.ink
                            font {
                                family: "JetBrains Mono"
                                pixelSize: 10
                                weight: Font.ExtraBold
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: hint.modelData.t
                        color: Qt.alpha(Theme.paper, 0.75)
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 10
                            bold: true
                            letterSpacing: 1.5
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: hint.modelData.k === "ESC"
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.close()
                    }
                }
            }
        }
    }
}
