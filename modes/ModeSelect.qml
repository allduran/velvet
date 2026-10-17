import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../config"
import "../services"
import "../clip"

// Selector de modo: de 1 a 6 cartas en abanico + Administrar modos.
// qs -c velvet ipc call mode toggle
PanelWindow {
    id: win
    property string screenName: ""
    visible: Ui.modeScreen !== "" && Ui.modeScreen === screenName
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "velvet-mode"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    // Modos del selector (Modes.shown) y página: select | manage | edit
    readonly property var list: Modes.shown
    readonly property int n: list.length
    property string page: "select"

    property int sel: 0
    readonly property string selMode: list[Math.min(sel, n - 1)]?.id ?? "general"
    // El fondo se tiñe con el estilo de lo que se está mirando en cada página
    readonly property string washStyle: page === "edit" ? editor.fStyle : page === "manage" ? manage.focusStyle : Modes.styleOf(selMode)
    readonly property var selPal: Theme.palettes[washStyle]
    readonly property var selTrio: selPal.trio

    property bool confirming: false

    // Avisos (Administrar / editar)
    property string flash: ""
    function say(t) {
        flash = t;
        flashT.restart();
    }
    Timer {
        id: flashT
        interval: 1600
        onTriggered: win.flash = ""
    }
    onPageChanged: {
        flash = "";
        if (page === "manage")
            manage.sel = Math.max(0, Modes.all.findIndex(m => m.id === (editId || selMode)));
        if (page === "edit")
            editor.load(editId);
        else
            // pone el foco en el nombre si es un modo propio
            keys.forceActiveFocus();
    }

    function findApp(q) {
        const apps = DesktopEntries.applications.values;
        const k = q.toLowerCase();
        return apps.find(e => e.id.toLowerCase() === k) ?? apps.find(e => e.name.toLowerCase() === k) ?? apps.find(e => e.id.toLowerCase().includes(k)) ?? apps.find(e => e.name.toLowerCase().includes(k)) ?? null;
    }
    function favNames(m) {
        return (Config.pins[m] ?? Config.pins.general ?? []).map(id => (findApp(id)?.name ?? id).toUpperCase());
    }

    function close() {
        grab.active = false;
        Ui.modeScreen = "";
    }

    // Reparto de las cartas: con 4 quedan como antes; con 5–6 se encogen
    readonly property real step: Math.min(370, 1480 / Math.max(1, n))
    readonly property real cardScale: Math.min(1, (step - 20) / 350)

    // Cabecera y teclas de cada página
    readonly property string title1: page === "select" ? "ELIGE TU" : page === "manage" ? "TUS" : (editId ? "EDITAR" : "NUEVO")
    readonly property string title2: page === "select" ? "MODO" : page === "manage" ? "MODOS" : (editId ? Modes.nameOf(editId) : "MODO")
    property string editId: ""          // modo que se edita ("" = nuevo)
    readonly property var hints: ({
            select: [
                {
                    k: "← →",
                    t: "ELEGIR"
                },
                {
                    k: "1–" + n,
                    t: "SALTO DIRECTO"
                },
                {
                    k: "ENTER",
                    t: "CAMBIAR DE MODO"
                },
                {
                    k: "M",
                    t: "ADMINISTRAR"
                },
                {
                    k: "ESC",
                    t: "CANCELAR"
                }
            ],
            manage: [
                {
                    k: "↑↓",
                    t: "MODO"
                },
                {
                    k: "E",
                    t: "EDITAR"
                },
                {
                    k: "H",
                    t: "OCULTAR / BORRAR"
                },
                {
                    k: "N",
                    t: "NUEVO"
                },
                {
                    k: "ESC",
                    t: "VOLVER"
                }
            ],
            edit: [
                {
                    k: "ENTER · CTRL + S",
                    t: "GUARDAR"
                },
                {
                    k: "ESC",
                    t: "CANCELAR"
                }
            ]
        })

    function confirm(i) {
        if (confirming)
            return;
        sel = i;
        if (list[i].id === Theme.mode) {
            close();
            return;
        }
        if (!Config.animations) {
            Theme.setMode(list[i].id);
            close();
            return;
        }
        confirming = true;
        sweep.restart();
    }

    onVisibleChanged: {
        if (!visible) {
            grab.active = false;
            confirming = false;
            return;
        }
        page = "select";
        sel = Math.max(0, list.findIndex(m => m.id === Theme.mode));
        focusT.restart();
    }
    HyprlandFocusGrab {
        id: grab
        windows: [win]
        onCleared: if (!win.confirming)
            win.close()
    }
    Timer {
        id: focusT
        interval: 30
        onTriggered: {
            grab.active = true;
            keys.forceActiveFocus();
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (win.confirming)
                return;
            if (win.page === "manage") {
                const m = manage.rows[manage.sel];
                if (e.key === Qt.Key_Escape)
                    win.page = "select";
                else if (e.key === Qt.Key_Up)
                    manage.move(-1);
                else if (e.key === Qt.Key_Down)
                    manage.move(1);
                else if (e.key === Qt.Key_E || e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                    manage.edit(m.id);
                else if (e.key === Qt.Key_H || e.key === Qt.Key_Delete)
                    manage.toggle(m);
                else if (e.key === Qt.Key_N)
                    manage.newMode();
                else
                    return;
            } else if (win.page === "edit") {
                if (e.key === Qt.Key_Escape)
                    win.page = "manage";
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || (e.key === Qt.Key_S && (e.modifiers & Qt.ControlModifier)))
                    editor.save();
                else
                    return;
            } else if (e.key === Qt.Key_Escape)
                win.close();
            else if (e.key === Qt.Key_Left)
                win.sel = (win.sel + win.n - 1) % win.n;
            else if (e.key === Qt.Key_Right)
                win.sel = (win.sel + 1) % win.n;
            else if (e.key >= Qt.Key_1 && e.key < Qt.Key_1 + win.n)
                win.sel = e.key - Qt.Key_1;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                win.confirm(win.sel);
            else if (e.key === Qt.Key_M)
                win.page = "manage";
            else
                return;
            e.accepted = true;
        }
    }

    // Velo
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.canvas, 0.94)
    }

    Item {
        id: stage
        width: 1600
        height: 900
        anchors.centerIn: parent
        scale: Math.min((win.screen?.width ?? 1600) / 1600, (win.screen?.height ?? 900) / 900)

        // Lavado diagonal con los colores del modo elegido (vista previa)
        Item {
            x: -300
            y: 0
            width: 2300
            height: 900
            rotation: -10
            Rectangle {
                y: 226
                width: parent.width
                height: 10
                color: win.selTrio[0]
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }
            Rectangle {
                y: 244
                width: parent.width
                height: 5
                color: win.selTrio[1]
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }
            Rectangle {
                y: 250
                width: parent.width
                height: 330
                color: Qt.alpha(win.selTrio[0], 0.16)
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }
            Rectangle {
                y: 600
                width: parent.width
                height: 6
                color: win.selTrio[2]
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }
        }

        // Cabecera
        Column {
            x: 56
            y: 44
            spacing: 8
            Text {
                text: "VELVET // CAMBIO DE MODO" + (win.page === "select" ? " · ACTUAL: MODE." + Modes.nameOf(Theme.mode) : " › ADMINISTRAR" + (win.page === "edit" ? " › " + win.title2 : ""))
                color: win.selPal.telemetry
                font {
                    family: "JetBrains Mono"
                    pixelSize: 10
                    weight: Font.ExtraBold
                    letterSpacing: 2
                }
            }
            Row {
                spacing: 18
                Text {
                    text: win.title1
                    color: Theme.paper
                    font {
                        family: "Bebas Neue"
                        pixelSize: 84
                        letterSpacing: 4
                    }
                }
                Item {
                    width: modoT.implicitWidth + 36
                    height: modoT.implicitHeight
                    rotation: -2
                    Rectangle {
                        x: 8
                        y: 8
                        width: parent.width
                        height: parent.height
                        color: win.selTrio[1]
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: win.selTrio[0]
                    }
                    Text {
                        id: modoT
                        anchors.centerIn: parent
                        text: win.title2
                        color: Theme.on(win.selTrio[0])
                        font {
                            family: "Bebas Neue"
                            pixelSize: 84
                            letterSpacing: 4
                        }
                    }
                }
            }
        }

        // Cartas en abanico
        Item {
            anchors.fill: parent
            visible: win.page === "select"

            Repeater {
                model: win.list
                ModeCard {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property bool on: win.sel === index
                    readonly property var pal: Theme.palettes[modelData.style]
                    n: index + 1
                    name: modelData.name
                    persona: Modes.styleLabel(modelData.style)
                    tag: modelData.tag
                    trio: pal.trio
                    tele: pal.telemetry
                    wallpaper: Wallpapers.currentFor(modelData.id)
                    favs: win.favNames(modelData.id)
                    active: on
                    current: modelData.id === Theme.mode

                    x: 800 + (index - (win.n - 1) / 2) * win.step - width / 2
                    y: 200 + (on ? 0 : 30)
                    z: on ? 5 : 1
                    rotation: on ? -1 : (win.n > 1 ? (index - (win.n - 1) / 2) / ((win.n - 1) / 2) * 5 : 0)
                    scale: (on ? 1.08 : 0.94) * win.cardScale
                    opacity: on ? 1 : 0.62
                    Behavior on y {
                        enabled: Config.animations
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutBack
                        }
                    }
                    Behavior on scale {
                        enabled: Config.animations
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutBack
                        }
                    }
                    Behavior on rotation {
                        enabled: Config.animations
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    onPicked: win.sel = index
                    onConfirmed: win.confirm(index)
                }
            }

            // Acceso a Administrar modos (también con M)
            SkewChip {
                x: 1600 - 64 - width
                y: 84
                height: 52
                label: "M · ADMINISTRAR MODOS"
                fill: Theme.ink
                fg: Theme.paper
                border: Theme.paper
                shadow: win.selTrio[0]
                size: 28
                padding: 24
                onClicked: win.page = "manage"
            }
        }

        // Administrar modos
        ModeManage {
            id: manage
            visible: win.page === "manage"
            onEdit: id => {
                win.editId = id;
                win.page = "edit";
            }
            onBack: win.page = "select"
            onSay: t => win.say(t)
        }

        // Crear / editar modo
        ModeEdit {
            id: editor
            visible: win.page === "edit"
            favs: win.favNames(modeId || "general")
            onDone: id => {
                win.editId = id;
                win.page = "manage";
            }
            onCancel: win.page = "manage"
            onSay: t => win.say(t)
        }

        // Aviso
        SkewChip {
            visible: win.flash !== ""
            x: 1600 - 64 - width
            y: 900 - 84 - height
            height: 48
            label: "▶▶ " + win.flash
            fill: win.selTrio[0]
            fg: Theme.on(win.selTrio[0])
            shadow: Theme.paper
            size: 26
            padding: 24
        }

        // Barra de teclas
        Row {
            x: (1600 - width) / 2
            y: 900 - 36 - height
            spacing: 28
            Repeater {
                model: win.hints[win.page]
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
                }
            }
        }

        // Confirmación: barrido con el nombre del modo + sello
        Item {
            id: banner
            visible: win.confirming
            x: -200
            y: 0
            width: 2100
            height: 900
            rotation: -10
            transform: Translate {
                id: bannerX
            }
            Rectangle {
                y: 300
                width: parent.width
                height: 12
                color: win.selTrio[1]
            }
            Rectangle {
                y: 322
                width: parent.width
                height: 230
                color: win.selTrio[0]
                Text {
                    anchors.centerIn: parent
                    text: "MODO " + Modes.nameOf(win.selMode)
                    color: Theme.on(win.selTrio[0])
                    style: Text.Raised
                    styleColor: Theme.ink
                    font {
                        family: "Bebas Neue"
                        pixelSize: 150
                        letterSpacing: 10
                    }
                }
            }
            Rectangle {
                y: 562
                width: parent.width
                height: 12
                color: win.selTrio[2]
            }
        }
        Rectangle {
            id: stamp
            visible: win.confirming
            x: 1600 - 120 - width
            y: 620
            width: stampT.implicitWidth + 32
            height: stampT.implicitHeight + 16
            rotation: -8
            color: Theme.ink
            border.width: 3
            border.color: Theme.paper
            Text {
                id: stampT
                anchors.centerIn: parent
                text: "COLORES · FONDO · FAVORITAS ✓"
                color: Theme.paper
                font {
                    family: "JetBrains Mono"
                    pixelSize: 18
                    weight: Font.ExtraBold
                    letterSpacing: 3
                }
            }
        }

        SequentialAnimation {
            id: sweep
            ParallelAnimation {
                NumberAnimation {
                    target: bannerX
                    property: "x"
                    from: -2400
                    to: 0
                    duration: 300
                    easing.type: Easing.OutCubic
                }
                SequentialAnimation {
                    PauseAnimation {
                        duration: 120
                    }
                    NumberAnimation {
                        target: stamp
                        property: "scale"
                        from: 2.4
                        to: 1
                        duration: 280
                        easing.type: Easing.OutBack
                    }
                }
            }
            // El cambio se aplica con la banda tapando la pantalla
            ScriptAction {
                script: Theme.setMode(win.selMode)
            }
            PauseAnimation {
                duration: 900
            }
            ScriptAction {
                script: win.close()
            }
        }
    }
}
