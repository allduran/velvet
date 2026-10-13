import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config"
import "../services"

// Capturas y grabación con selector propio.
//   qs -c velvet ipc call capture screen        → captura del monitor enfocado
//   qs -c velvet ipc call capture region        → selector (pantalla congelada)
//   qs -c velvet ipc call capture window        → selector empezando en modo ventana
//   qs -c velvet ipc call capture record        → grabar región (o parar si ya graba)
//   qs -c velvet ipc call capture recordScreen  → grabar monitor entero (o parar)
//   qs -c velvet ipc call capture recordSound   → grabar monitor entero con sonido (o parar)
Scope {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/capture.sh"
    readonly property string freezePath: Quickshell.env("XDG_RUNTIME_DIR") + "/velvet-freeze.png"

    property bool active: false
    property string kind: "shot"        // "shot" | "rec"
    property string mode: "region"      // "region" | "window" | "screen"
    property string screenName: ""
    property var windows: []            // ventanas visibles del monitor, en coordenadas locales
    property int freezeId: 0            // fuerza recargar la imagen congelada

    function focused() {
        return Hyprland.focusedMonitor?.name ?? "";
    }

    function open(kind, mode) {
        if (active)
            return;
        root.kind = kind;
        root.mode = mode;
        root.screenName = focused();
        winProc.running = true;
        if (kind === "shot") {
            freeze.command = ["grim", "-o", root.screenName, root.freezePath];
            freeze.running = true;          // el selector se abre al terminar
        } else {
            active = true;
        }
    }
    function close() {
        active = false;
    }

    IpcHandler {
        target: "capture"
        function screen(): void {
            Quickshell.execDetached([root.script, "shot-full", root.focused()]);
        }
        function region(): void {
            root.open("shot", "region");
        }
        function window(): void {
            root.open("shot", "window");
        }
        function record(): void {
            Recorder.recording ? Recorder.stop() : root.open("rec", "region");
        }
        function recordScreen(): void {
            Recorder.recording ? Recorder.stop() : Recorder.start("output:" + root.focused(), false);
        }
        function recordSound(): void {
            Recorder.recording ? Recorder.stop() : Recorder.start("output:" + root.focused(), true);
        }
    }

    // Congela la pantalla antes de mostrar el selector
    Process {
        id: freeze
        onExited: code => {
            if (code !== 0)
                return;
            root.freezeId++;
            root.active = true;
        }
    }

    // Ventanas visibles en el monitor (para el modo ventana)
    Process {
        id: winProc
        command: ["sh", "-c", "hyprctl -j monitors; echo '@@'; hyprctl -j clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = text.split("@@");
                    const mon = JSON.parse(parts[0]).find(m => m.name === root.screenName);
                    if (!mon) {
                        root.windows = [];
                        return;
                    }
                    root.windows = JSON.parse(parts[1]).filter(c => c.mapped && !c.hidden && c.workspace.id === mon.activeWorkspace.id).sort((a, b) => a.focusHistoryID - b.focusHistoryID)    // la más reciente primero
                    .map(c => ({
                                x: c.at[0] - mon.x,
                                y: c.at[1] - mon.y,
                                w: c.size[0],
                                h: c.size[1]
                            }));
                } catch (e) {
                    root.windows = [];
                }
            }
        }
    }

    // ═══ Selector: una ventana por monitor, solo visible en el elegido ═══
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: root.active && root.screenName === modelData.name
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velvet-picker"
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            readonly property bool isShot: root.kind === "shot"
            readonly property color tint: isShot ? Theme.accent2 : Theme.accent
            readonly property color tintInk: Theme.on(tint)

            // Selección en coordenadas locales (lógicas)
            property real sx: 0
            property real sy: 0
            property real sw: 0
            property real sh: 0
            readonly property bool hasSel: sw > 2 && sh > 2
            property point dragFrom: Qt.point(-1, -1)
            property bool flashing: false

            onVisibleChanged: {
                if (!visible)
                    return;
                sw = 0;
                sh = 0;
                flashing = false;
                if (root.mode === "screen")
                    selectScreen();
                keys.forceActiveFocus();
            }

            function selectScreen() {
                sx = 0;
                sy = 0;
                sw = width;
                sh = height;
            }
            function setMode(m) {
                root.mode = m;
                if (m === "screen")
                    selectScreen();
                else {
                    sw = 0;
                    sh = 0;
                }
            }
            function winAt(px, py) {
                return root.windows.find(w => px >= w.x && px <= w.x + w.w && py >= w.y && py <= w.y + w.h) ?? null;
            }
            function selectRect(r) {
                sx = Math.max(0, r.x);
                sy = Math.max(0, r.y);
                sw = Math.min(width, r.x + r.w) - sx;
                sh = Math.min(height, r.y + r.h) - sy;
            }

            function confirm() {
                if (!hasSel)
                    return;
                if (isShot) {
                    // Recorte en píxeles reales de la imagen congelada
                    const k = frozen.implicitWidth > 0 ? frozen.implicitWidth / width : 1;
                    const geom = Math.round(sw * k) + "x" + Math.round(sh * k) + "+" + Math.round(sx * k) + "+" + Math.round(sy * k);
                    Quickshell.execDetached([root.script, "shot-crop", root.freezePath, geom]);
                    flashing = true;
                    flashT.restart();
                } else {
                    const target = root.mode === "screen" ? "output:" + modelData.name : Math.round(modelData.x + sx) + "," + Math.round(modelData.y + sy) + " " + Math.round(sw) + "x" + Math.round(sh);
                    root.close();
                    startRec.target = target;
                    startRec.restart();      // deja que el selector desaparezca antes de grabar
                }
            }

            Timer {
                id: flashT
                interval: 220
                onTriggered: root.close()
            }
            Timer {
                id: startRec
                property string target: ""
                interval: 200
                onTriggered: Recorder.start(target, false)
            }

            // Pantalla congelada (solo capturas)
            Image {
                id: frozen
                anchors.fill: parent
                visible: win.isShot
                source: win.isShot && root.freezeId > 0 ? "file://" + root.freezePath + "?" + root.freezeId : ""
                cache: false
                asynchronous: false
                fillMode: Image.Stretch
            }

            // Oscurecido alrededor de la selección
            Rectangle {
                visible: !win.hasSel
                anchors.fill: parent
                color: Qt.alpha(Theme.ink, 0.55)
            }
            Rectangle {
                visible: win.hasSel
                x: 0
                y: 0
                width: parent.width
                height: win.sy
                color: Qt.alpha(Theme.ink, 0.55)
            }
            Rectangle {
                visible: win.hasSel
                x: 0
                y: win.sy + win.sh
                width: parent.width
                height: parent.height - y
                color: Qt.alpha(Theme.ink, 0.55)
            }
            Rectangle {
                visible: win.hasSel
                x: 0
                y: win.sy
                width: win.sx
                height: win.sh
                color: Qt.alpha(Theme.ink, 0.55)
            }
            Rectangle {
                visible: win.hasSel
                x: win.sx + win.sw
                y: win.sy
                width: parent.width - x
                height: win.sh
                color: Qt.alpha(Theme.ink, 0.55)
            }

            // Ratón
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.CrossCursor
                onPressed: mouse => {
                    if (root.mode === "region") {
                        win.dragFrom = Qt.point(mouse.x, mouse.y);
                        win.sx = mouse.x;
                        win.sy = mouse.y;
                        win.sw = 0;
                        win.sh = 0;
                    }
                }
                onPositionChanged: mouse => {
                    if (root.mode === "window") {
                        const w = win.winAt(mouse.x, mouse.y);
                        if (w)
                            win.selectRect(w);
                        else {
                            win.sw = 0;
                            win.sh = 0;
                        }
                    } else if (root.mode === "region" && pressed) {
                        const d = win.dragFrom;
                        win.sx = Math.min(d.x, mouse.x);
                        win.sy = Math.min(d.y, mouse.y);
                        win.sw = Math.abs(mouse.x - d.x);
                        win.sh = Math.abs(mouse.y - d.y);
                    }
                }
                onClicked: if (root.mode === "window" && win.hasSel)
                    win.confirm()
            }

            // Cabecera
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 70
                spacing: 14
                Item {
                    width: headT.implicitWidth + 36
                    height: headT.implicitHeight
                    Rectangle {
                        x: 5
                        y: 5
                        width: parent.width
                        height: parent.height
                        color: Theme.ink
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * 22, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: win.tint
                        antialiasing: true
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * 22, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    Text {
                        id: headT
                        anchors.centerIn: parent
                        text: win.isShot ? "CAPTURA" : "GRABAR"
                        color: win.tintInk
                        font.family: "Bebas Neue"
                        font.pixelSize: 34
                        font.letterSpacing: 4
                    }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: hintT.implicitWidth + 24
                    height: 26
                    color: Qt.alpha(Theme.ink, 0.85)
                    Text {
                        id: hintT
                        anchors.centerIn: parent
                        text: (root.mode === "window" ? "CLIC EN UNA VENTANA" : "ARRASTRA") + " · ENTER " + (win.isShot ? "CAPTURAR" : "GRABAR") + " · TAB MODO · ESC SALIR"
                        color: Qt.alpha(Theme.paper, 0.85)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2
                    }
                }
            }

            // Selección: borde, esquinas y medidas
            Item {
                visible: win.hasSel
                x: win.sx
                y: win.sy
                width: win.sw
                height: win.sh

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    color: "transparent"
                    border.width: 2
                    border.color: win.tint
                }
                Repeater {
                    model: [[0, 0], [1, 0], [0, 1], [1, 1]]
                    delegate: Item {
                        required property var modelData
                        x: modelData[0] ? parent.width - 18 : -8
                        y: modelData[1] ? parent.height - 18 : -8
                        width: 26
                        height: 26
                        Rectangle {
                            x: parent.modelData[0] ? 21 : 0
                            width: 5
                            height: 26
                            color: Theme.paper
                        }
                        Rectangle {
                            y: parent.modelData[1] ? 21 : 0
                            width: 26
                            height: 5
                            color: Theme.paper
                        }
                    }
                }
                Item {
                    x: -2
                    y: -34
                    width: sizeT.implicitWidth + 20
                    height: sizeT.implicitHeight
                    Rectangle {
                        anchors.fill: parent
                        color: win.tint
                        antialiasing: true
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * 12, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    Text {
                        id: sizeT
                        anchors.centerIn: parent
                        text: Math.round(win.sw) + " × " + Math.round(win.sh)
                        color: win.tintInk
                        font.family: "Bebas Neue"
                        font.pixelSize: 20
                        font.letterSpacing: 2
                    }
                }
                Text {
                    anchors.right: parent.right
                    y: -28
                    text: "X " + Math.round(win.sx) + " · Y " + Math.round(win.sy)
                    color: Qt.alpha(Theme.paper, 0.8)
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            // Barra de acciones
            Row {
                visible: win.hasSel
                x: Math.max(10, Math.min(win.sx, win.width - width - 10))
                y: Math.min(win.sy + win.sh + 18, win.height - 50)
                spacing: 6

                Repeater {
                    model: [["region", "REGIÓN"], ["window", "VENTANA"], ["screen", "PANTALLA"]]
                    delegate: Item {
                        id: modeBtn
                        required property var modelData
                        readonly property bool on: root.mode === modelData[0]
                        width: modeT.implicitWidth + 24
                        height: 32
                        Rectangle {
                            anchors.fill: parent
                            color: modeBtn.on ? win.tint : Qt.alpha(Theme.ink, 0.9)
                            antialiasing: true
                            transform: Matrix4x4 {
                                matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * 16, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                            }
                        }
                        Text {
                            id: modeT
                            anchors.centerIn: parent
                            text: modeBtn.modelData[1]
                            color: modeBtn.on ? win.tintInk : Theme.paper
                            font.family: "Bebas Neue"
                            font.pixelSize: 18
                            font.letterSpacing: 2
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.setMode(modeBtn.modelData[0])
                        }
                    }
                }
                Item {
                    width: 10
                    height: 32
                }
                Item {
                    width: okT.implicitWidth + 32
                    height: 32
                    Rectangle {
                        x: 4
                        y: 4
                        width: parent.width
                        height: parent.height
                        color: win.tint
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * 16, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.paper
                        antialiasing: true
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * 16, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    Text {
                        id: okT
                        anchors.centerIn: parent
                        text: "✓ " + (win.isShot ? "CAPTURAR" : "GRABAR")
                        color: Theme.ink
                        font.family: "Bebas Neue"
                        font.pixelSize: 20
                        font.letterSpacing: 2
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.confirm()
                    }
                }
                Item {
                    width: 36
                    height: 32
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.ink
                        antialiasing: true
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * 16, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.paper
                        font.family: "Bebas Neue"
                        font.pixelSize: 20
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            // Destello al capturar
            Rectangle {
                anchors.fill: parent
                color: Theme.paper
                opacity: win.flashing ? 0.9 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }

            // Teclado
            Item {
                id: keys
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape)
                        root.close();
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        win.confirm();
                    else if (event.key === Qt.Key_Tab) {
                        const o = ["region", "window", "screen"];
                        win.setMode(o[(o.indexOf(root.mode) + 1) % 3]);
                    } else
                        return;
                    event.accepted = true;
                }
            }
        }
    }
}
