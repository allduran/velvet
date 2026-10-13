import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config"
import "../services"
import "../lock"

// Selector de fondos. Abrir: qs -c velvet ipc call wallpaper toggle
PanelWindow {
    id: win

    visible: Ui.wallpaperScreen !== "" && Ui.wallpaperScreen === (screen ? screen.name : "")

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "velvet-wallpicker"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    HyprlandFocusGrab {
        windows: [win]
        active: win.visible
        onCleared: Ui.wallpaperScreen = ""
    }

    // ── Estado ──────────────────────────────────────────
    readonly property var hex: ({ red: "#E60012", blue: "#0055FF", yellow: "#FFE600" })
    readonly property var tags: ({ red: "RED", blue: "BLUE", yellow: "YELLOW" })
    readonly property string lockColor: Wallpapers.modeColor[Theme.mode] || ""
    readonly property bool locked: lockColor !== ""

    property string filter: "all"
    property int idx: 0
    property bool flash: false

    readonly property var list: Wallpapers.forMode(Theme.mode, filter)
    readonly property int n: list.length
    readonly property var focusWp: n > 0 ? list[Math.min(idx, n - 1)] : null

    readonly property color accent: Theme.accent
    readonly property color accentInk: Theme.on(Theme.accent)
    readonly property real s: Math.min(width / 1600, height / 900)

    function focusCurrent() {
        const i = list.findIndex(w => w.path === Wallpapers.current);
        idx = Math.max(0, i);
    }
    function move(d) { if (n > 0) idx = (idx + d + n) % n }
    function apply() {
        if (!focusWp) return;
        Wallpapers.set(focusWp.path);
        flash = true;
        flashOff.restart();
    }
    function cycleFilter() {
        if (locked) return;
        const order = ["all", "red", "blue", "yellow"];
        filter = order[(order.indexOf(filter) + 1) % 4];
        focusCurrent();
    }
    function close() { Ui.wallpaperScreen = "" }

    onVisibleChanged: {
        if (!visible) return;
        filter = "all";
        flash = false;
        Wallpapers.refresh();
        focusCurrent();
        keys.forceActiveFocus();
    }
    onNChanged: if (idx >= n) idx = Math.max(0, n - 1)

    Timer { id: flashOff; interval: 900; onTriggered: win.flash = false }

    // ── Fondo: vista previa difuminada ──────────────────
    Rectangle { anchors.fill: parent; color: Theme.ink }

    Image {
        id: preview
        anchors.fill: parent
        anchors.margins: -40
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(640, 360)
        source: win.focusWp ? "file://" + win.focusWp.path : ""
        visible: false
    }
    MultiEffect {
        anchors.fill: preview
        source: preview
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        brightness: -0.55
    }

    Canvas {
        anchors.fill: parent
        onPaint: {
            const g = getContext("2d");
            const step = 14 * win.s, r = 1.7 * win.s;
            g.fillStyle = "rgba(13,14,18,0.5)";
            for (let y = 0; y < height; y += step)
                for (let x = 0; x < width; x += step) {
                    g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2); g.fill();
                }
        }
    }

    // ── Escenario 1600×900 ──────────────────────────────
    Item {
        id: stage
        width: 1600; height: 900
        anchors.centerIn: parent
        scale: win.s

        // Tajo de color del modo
        Item {
            x: -200; y: 236; width: 2200; height: 420
            rotation: -8
            Rectangle {
                anchors.fill: parent
                opacity: 0.9
                color: win.locked ? win.hex[win.lockColor] : "transparent"
                gradient: win.locked ? null : tri
                Gradient {
                    id: tri
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#E60012" }
                    GradientStop { position: 0.33; color: "#E60012" }
                    GradientStop { position: 0.3301; color: "#0055FF" }
                    GradientStop { position: 0.66; color: "#0055FF" }
                    GradientStop { position: 0.6601; color: "#FFE600" }
                    GradientStop { position: 1.0; color: "#FFE600" }
                }
            }
            Shape {
                anchors.fill: parent
                ShapePath {
                    fillColor: Theme.ink; strokeWidth: -1
                    PathPolyline { path: [Qt.point(0, 420 * 0.18), Qt.point(2200, 0), Qt.point(2200, 420 * 0.82), Qt.point(0, 420)] }
                }
            }
        }

        // Cabecera
        Row {
            x: 64; y: 48; spacing: 22
            Item {
                width: ttl.implicitWidth + 6; height: ttl.implicitHeight + 6
                Text { x: 6; y: 6; text: ttl.text; font: ttl.font; color: win.accent }
                Text { id: ttl; text: "FONDOS"; color: Theme.paper; font.family: "Bebas Neue"; font.pixelSize: 120; font.letterSpacing: 6 }
            }
            Column {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 22
                spacing: 8
                Item {
                    width: mn.implicitWidth + 28; height: mn.implicitHeight
                    SkewRect { anchors.fill: parent; color: win.accent }
                    Text { id: mn; anchors.centerIn: parent; text: "MODO " + Theme.mode.toUpperCase(); color: win.accentInk; font.family: "Bebas Neue"; font.pixelSize: 30; font.letterSpacing: 3 }
                }
                Text {
                    text: (win.locked ? "SOLO FONDOS " + win.tags[win.lockColor] : "TODOS LOS COLORES")
                          + " · GUARDADO: " + (Wallpapers.current.split("/").pop().replace(/\.[^.]+$/, "").toUpperCase() || "—")
                    color: Qt.rgba(0.96, 0.96, 0.97, 0.7)
                    font.family: "JetBrains Mono"; font.pixelSize: 12; font.weight: Font.ExtraBold; font.letterSpacing: 2
                }
            }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 64; y: 62; spacing: 6
            Text { id: posT; text: String(Math.min(win.idx, win.n - 1) + 1).padStart(2, "0"); color: Theme.paper; font.family: "Bebas Neue"; font.pixelSize: 90 }
            Text { anchors.baseline: posT.baseline; text: "/ " + String(win.n).padStart(2, "0"); color: Qt.rgba(0.96, 0.96, 0.97, 0.5); font.family: "Bebas Neue"; font.pixelSize: 40 }
        }

        // Carrusel inclinado
        Item {
            x: 0; y: 250; width: 1600; height: 400

            Repeater {
                model: win.list
                delegate: Item {
                    id: card
                    required property var modelData
                    required property int index

                    readonly property int off: {
                        let o = index - win.idx;
                        if (o > win.n / 2) o -= win.n;
                        if (o < -win.n / 2) o += win.n;
                        return o;
                    }
                    readonly property int dist: Math.abs(off)
                    readonly property bool center: off === 0
                    readonly property real k: Math.tan(-8 * Math.PI / 180)

                    width: center ? 620 : 300
                    height: center ? 350 : 170
                    x: 800 + off * 300 + (off > 0 ? 170 : off < 0 ? -170 : 0) - width / 2
                    y: 200 - height / 2 + (center ? 0 : (off % 2 ? -26 : 26))
                    rotation: center ? -2 : (off % 2 ? 3 : -3)
                    opacity: dist > 2 ? 0 : dist === 2 ? 0.55 : 1
                    visible: dist <= 3
                    z: 10 - dist

                    Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 250 } }

                    // Sombra dura
                    SkewRect { skew: -8; x: 12; y: 12; width: parent.width; height: parent.height; color: Theme.ink; visible: card.center }
                    // Marco
                    SkewRect { skew: -8; anchors.fill: parent; color: card.center ? Theme.paper : Theme.ink }

                    // Imagen recortada en paralelogramo
                    Item {
                        id: clipBox
                        anchors.fill: parent
                        anchors.margins: 6
                        clip: true
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, card.k, 0, -card.k * clipBox.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                        Image {
                            anchors.fill: parent
                            anchors.leftMargin: -40; anchors.rightMargin: -40
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(640, 360)
                            source: "file://" + card.modelData.path
                            transform: Matrix4x4 {
                                matrix: Qt.matrix4x4(1, -card.k, 0, card.k * clipBox.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.ink
                            opacity: card.center ? 0 : 0.35
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }
                    }

                    // Guardado del modo
                    Item {
                        visible: card.modelData.path === Wallpapers.current
                        anchors.right: parent.right; anchors.rightMargin: 36
                        y: -14
                        width: act.implicitWidth + 20; height: act.implicitHeight + 8
                        SkewRect { x: 3; y: 3; width: parent.width; height: parent.height; color: Theme.ink }
                        SkewRect { anchors.fill: parent; color: Theme.paper }
                        Text { id: act; anchors.centerIn: parent; text: "● ACTUAL"; color: Theme.ink; font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.ExtraBold; font.letterSpacing: 2 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.center ? win.apply() : (win.idx = card.index)
                    }
                }
            }
        }

        // Ficha del enfocado
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 668; spacing: 16
            visible: win.focusWp !== null
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: tg.implicitWidth + 24; height: tg.implicitHeight
                SkewRect { anchors.fill: parent; color: win.focusWp ? win.hex[win.focusWp.color] : "transparent" }
                Text {
                    id: tg; anchors.centerIn: parent
                    text: win.focusWp ? win.tags[win.focusWp.color] : ""
                    color: win.focusWp ? Theme.on(win.hex[win.focusWp.color]) : Theme.paper
                    font.family: "Bebas Neue"; font.pixelSize: 26; font.letterSpacing: 3
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: win.focusWp ? win.focusWp.name.toUpperCase() : ""
                color: Theme.paper
                font.family: "JetBrains Mono"; font.pixelSize: 18; font.weight: Font.ExtraBold; font.letterSpacing: 3
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 400
            visible: win.n === 0
            text: "NO HAY FONDOS EN ~/PICTURES/WALLPAPERS"
            color: Theme.paper
            font.family: "Bebas Neue"; font.pixelSize: 48; font.letterSpacing: 4
        }

        // Filtros
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 730; spacing: 10

            Repeater {
                model: [["all", "TODOS", "#F5F5F7"], ["red", "ROJO", "#E60012"], ["blue", "AZUL", "#0055FF"], ["yellow", "AMARILLO", "#FFE600"]]
                delegate: Item {
                    id: fb
                    required property var modelData
                    readonly property bool active: win.locked ? modelData[0] === win.lockColor : modelData[0] === win.filter
                    readonly property bool disabled: win.locked && !active

                    width: fl.implicitWidth + 40; height: 40
                    opacity: disabled ? 0.25 : 1

                    SkewRect {
                        anchors.fill: parent
                        color: fb.active ? fb.modelData[2] : "transparent"
                        border.width: 2
                        border.color: fb.active ? fb.modelData[2] : Qt.rgba(0.96, 0.96, 0.97, 0.25)
                    }
                    Text {
                        id: fl; anchors.centerIn: parent
                        text: (win.locked && fb.active ? "🔒 " : "") + fb.modelData[1]
                        color: fb.active ? Theme.on(fb.modelData[2]) : Qt.rgba(0.96, 0.96, 0.97, 0.7)
                        font.family: "Bebas Neue"; font.pixelSize: 22; font.letterSpacing: 3
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !win.locked
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { win.filter = fb.modelData[0]; win.focusCurrent(); }
                    }
                }
            }
        }

        // Teclas
        Row {
            x: 64; anchors.bottom: parent.bottom; anchors.bottomMargin: 40; spacing: 22
            Repeater {
                model: [["← →", "ELEGIR"], ["ENTER", "APLICAR"], ["TAB", "FILTRO"], ["ESC", "CERRAR"]]
                delegate: Text {
                    required property var modelData
                    textFormat: Text.StyledText
                    text: "<b><font color='" + win.accent + "'>" + modelData[0] + "</font></b> " + modelData[1]
                    color: Qt.rgba(0.96, 0.96, 0.97, 0.75)
                    font.family: "JetBrains Mono"; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 2
                }
            }
        }

        // ¡FONDO FIJADO!
        Item {
            id: stamp
            anchors.centerIn: parent
            visible: win.flash
            width: sf.implicitWidth + 72; height: sf.implicitHeight
            rotation: -8
            onVisibleChanged: if (visible) stampIn.restart()

            Rectangle { x: 10; y: 10; width: parent.width; height: parent.height; color: Theme.ink }
            Rectangle { anchors.fill: parent; color: win.accent }
            Text { id: sf; anchors.centerIn: parent; text: "¡FONDO FIJADO!"; color: win.accentInk; font.family: "Bebas Neue"; font.pixelSize: 110; font.letterSpacing: 8 }

            ParallelAnimation {
                id: stampIn
                NumberAnimation { target: stamp; property: "scale"; from: 2; to: 1; duration: 350; easing.type: Easing.OutBack }
                NumberAnimation { target: stamp; property: "opacity"; from: 0; to: 1; duration: 180 }
            }
        }
    }

    // Teclado
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Right: win.move(1); break;
            case Qt.Key_Left: win.move(-1); break;
            case Qt.Key_Return:
            case Qt.Key_Enter: win.apply(); break;
            case Qt.Key_Tab: win.cycleFilter(); break;
            case Qt.Key_Escape: win.close(); break;
            default: return;
            }
            event.accepted = true;
        }
        z: -1
    }
}
