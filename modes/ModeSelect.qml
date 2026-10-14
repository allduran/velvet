import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../config"
import "../services"

// Selector de modo: cuatro cartas en abanico.
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

    readonly property var info: ({
            general: {
                name: "GENERAL",
                persona: "P3 · P4 · P5",
                tag: "TODO A LA VEZ · LA TRÍADA"
            },
            dev: {
                name: "DEV",
                persona: "PERSONA 3",
                tag: "CÓDIGO · UNITY · DEVLOG"
            },
            art: {
                name: "ART",
                persona: "PERSONA 4",
                tag: "PINTURA · 3D · VÍDEO"
            },
            game: {
                name: "GAME",
                persona: "PERSONA 5",
                tag: "STEAM · HEROIC · CHAT"
            }
        })

    property int sel: 0
    readonly property string selMode: Theme.modes[sel]
    readonly property var selTrio: Theme.palettes[selMode].trio
    property bool confirming: false

    function findApp(q) {
        const apps = DesktopEntries.applications.values;
        const k = q.toLowerCase();
        return apps.find(e => e.id.toLowerCase() === k) ?? apps.find(e => e.name.toLowerCase() === k) ?? apps.find(e => e.id.toLowerCase().includes(k)) ?? apps.find(e => e.name.toLowerCase().includes(k)) ?? null;
    }
    function favNames(m) {
        return (Config.pins[m] ?? []).map(id => (findApp(id)?.name ?? id).toUpperCase());
    }

    function close() {
        grab.active = false;
        Ui.modeScreen = "";
    }
    function confirm(i) {
        if (confirming)
            return;
        sel = i;
        if (Theme.modes[i] === Theme.mode) {
            close();
            return;
        }
        if (!Config.animations) {
            Theme.setMode(Theme.modes[i]);
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
        sel = Math.max(0, Theme.modes.indexOf(Theme.mode));
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
            if (e.key === Qt.Key_Escape)
                win.close();
            else if (e.key === Qt.Key_Left)
                win.sel = (win.sel + 3) % 4;
            else if (e.key === Qt.Key_Right)
                win.sel = (win.sel + 1) % 4;
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_4)
                win.sel = e.key - Qt.Key_1;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                win.confirm(win.sel);
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
                text: "VELVET // CAMBIO DE MODO · ACTUAL: MODE." + Theme.mode.toUpperCase()
                color: Theme.palettes[win.selMode].telemetry
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
                    text: "ELIGE TU"
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
                        text: "MODO"
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
        Repeater {
            model: Theme.modes
            ModeCard {
                id: card
                required property string modelData
                required property int index
                readonly property bool on: win.sel === index
                n: index + 1
                name: win.info[modelData].name
                persona: win.info[modelData].persona
                tag: win.info[modelData].tag
                trio: Theme.palettes[modelData].trio
                tele: Theme.palettes[modelData].telemetry
                wallpaper: Wallpapers.currentFor(modelData)
                favs: win.favNames(modelData)
                active: on
                current: modelData === Theme.mode

                x: [70, 440, 810, 1180][index]
                y: 200 + (on ? 0 : 30)
                z: on ? 5 : 1
                rotation: on ? -1 : [-5, -2, 2, 5][index]
                scale: on ? 1.08 : 0.94
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

        // Barra de teclas
        Row {
            x: (1600 - width) / 2
            y: 900 - 36 - height
            spacing: 28
            Repeater {
                model: [
                    {
                        k: "← →",
                        t: "ELEGIR"
                    },
                    {
                        k: "1–4",
                        t: "SALTO DIRECTO"
                    },
                    {
                        k: "ENTER",
                        t: "CAMBIAR DE MODO"
                    },
                    {
                        k: "ESC",
                        t: "CANCELAR"
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
                    text: "MODO " + win.info[win.selMode].name
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
