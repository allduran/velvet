import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "../config"
import "../services"

// OSD de volumen / brillo + tarjeta de pista.
//   qs -c velvet ipc call osd volumeUp | volumeDown | mute | brightnessUp | brightnessDown
//   qs -c velvet ipc call media toggle | next | previous | stop
Scope {
    id: root

    readonly property real volStep: 0.05
    readonly property real briStep: 0.05

    // ── Audio ──
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio.volume ?? 0
    readonly property bool muted: sink?.audio.muted ?? false
    PwObjectTracker {
        objects: [root.sink]
    }

    // ── Estado del OSD ──
    property string kind: "vol"         // "vol" | "bri"
    property bool osdShown: false
    Timer {
        id: osdHide
        interval: 1600
        onTriggered: root.osdShown = false
    }
    function showOsd(k) {
        kind = k;
        osdShown = true;
        osdHide.restart();
    }

    function setVol(v) {
        if (!sink)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
        showOsd("vol");
    }

    // Teclas de volumen: por wpctl (mezclador de WirePlumber), que respeta el volumen
    // por hardware de cada dispositivo. Escribir sink.audio.volume daba pasos dobles
    // en algunos (Poly BT700). -l 1 = tope del 100 %.
    function stepVol(sign) {
        if (!sink)
            return;
        Quickshell.execDetached(["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " + Math.round(volStep * 100) + "%" + sign]);
        showOsd("vol");
    }

    // ── Reproductor (el que suena, si no el último usado) ──
    property MprisPlayer player: null
    function pick() {
        const list = Mpris.players.values;
        const playing = list.find(p => p.isPlaying);
        if (playing)
            player = playing;
        else if (!player || !list.includes(player))
            player = list.length ? list[0] : null;
    }

    property string trackTag: "AHORA SUENA"
    property bool trackShown: false
    Timer {
        id: trackHide
        interval: 2600
        onTriggered: root.trackShown = false
    }
    function showTrack(tag) {
        trackTag = tag;
        trackShown = true;
        trackHide.restart();
    }

    IpcHandler {
        target: "osd"
        function volumeUp(): void {
            root.stepVol("+");
        }
        function volumeDown(): void {
            root.stepVol("-");
        }
        function mute(): void {
            if (!root.sink)
                return;
            root.sink.audio.muted = !root.muted;
            root.showOsd("vol");
        }
        function brightnessUp(): void {
            Brightness.step(root.briStep);
            root.showOsd("bri");
        }
        function brightnessDown(): void {
            Brightness.step(-root.briStep);
            root.showOsd("bri");
        }
    }

    IpcHandler {
        target: "media"
        function toggle(): void {
            root.pick();
            if (!root.player)
                return;
            const wasPlaying = root.player.isPlaying;
            root.player.togglePlaying();
            root.showTrack(wasPlaying ? "EN PAUSA" : "AHORA SUENA");
        }
        function next(): void {
            root.pick();
            if (!root.player?.canGoNext)
                return;
            root.player.next();
            root.showTrack("SIGUIENTE ▶▶");
        }
        function previous(): void {
            root.pick();
            if (!root.player?.canGoPrevious)
                return;
            root.player.previous();
            root.showTrack("◀◀ ANTERIOR");
        }
        function stop(): void {
            root.pick();
            if (!root.player)
                return;
            root.player.stop();
            root.showTrack("DETENIDO");
        }
    }

    // ── Ventanas: solo se pintan en el monitor enfocado ──
    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData
            readonly property bool here: (Hyprland.focusedMonitor?.name ?? "") === modelData.name

            // ═══ OSD volumen / brillo (abajo, centrado) ═══
            PanelWindow {
                id: osdWin
                screen: perScreen.modelData
                anchors.bottom: true
                margins.bottom: 90
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "velvet-osd"
                color: "transparent"
                implicitWidth: 528
                implicitHeight: 104
                mask: Region {}                      // no captura el ratón

                property real p: root.osdShown && perScreen.here ? 1 : 0
                Behavior on p {
                    enabled: Config.animations
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                visible: p > 0

                readonly property bool isVol: root.kind === "vol"
                readonly property bool off: isVol && root.muted
                readonly property real value: isVol ? root.vol : Brightness.value
                readonly property color chip: isVol ? Theme.accent : Theme.accent3

                Item {
                    id: osd
                    width: 528
                    height: 104
                    opacity: osdWin.p
                    transform: Translate {
                        y: (1 - osdWin.p) * 40
                    }

                    // Sombra dura
                    Shape {
                        x: 8
                        y: 8
                        width: 520
                        height: 96
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: osdWin.chip
                            strokeColor: "transparent"
                            PathPolyline {
                                path: [Qt.point(21, 0), Qt.point(520, 0), Qt.point(499, 96), Qt.point(0, 96), Qt.point(21, 0)]
                            }
                        }
                    }
                    // Placa
                    Shape {
                        width: 520
                        height: 96
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: Qt.alpha(Theme.ink, 0.96)
                            strokeColor: "transparent"
                            PathPolyline {
                                path: [Qt.point(21, 0), Qt.point(520, 0), Qt.point(499, 96), Qt.point(0, 96), Qt.point(21, 0)]
                            }
                        }
                    }

                    RowLayout {
                        x: 30
                        width: 520 - 30 - 34
                        height: 96
                        spacing: 18

                        // Tipo
                        ColumnLayout {
                            Layout.preferredWidth: 84
                            spacing: 2
                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: kindT.implicitWidth + 20
                                implicitHeight: kindT.implicitHeight
                                Rectangle {
                                    id: kindBg
                                    anchors.fill: parent
                                    color: osdWin.chip
                                    antialiasing: true
                                    transform: Matrix4x4 {
                                        matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * kindBg.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                                    }
                                }
                                Text {
                                    id: kindT
                                    anchors.centerIn: parent
                                    text: osdWin.isVol ? "VOLUMEN" : "BRILLO"
                                    color: Theme.on(osdWin.chip)
                                    font.family: "Bebas Neue"
                                    font.pixelSize: 20
                                    font.letterSpacing: 2
                                }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: osdWin.isVol ? "PIPEWIRE" : "TODAS"
                                color: Qt.alpha(Theme.telemetry, 0.7)
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8
                                font.bold: true
                                font.letterSpacing: 1
                            }
                        }

                        // Segmentos
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Row {
                                id: segs
                                Layout.fillWidth: true
                                spacing: 3
                                readonly property int on: Math.round(osdWin.value * 20)
                                Repeater {
                                    model: 20
                                    delegate: Rectangle {
                                        id: seg
                                        required property int index
                                        width: (segs.width - 19 * 3) / 20
                                        height: 18
                                        antialiasing: true
                                        color: index < segs.on ? (osdWin.off ? Qt.alpha(Theme.paper, 0.25) : (osdWin.isVol && index >= 18 ? Theme.accent : Theme.paper)) : Qt.alpha(Theme.paper, 0.08)
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 120
                                            }
                                        }
                                        transform: Matrix4x4 {
                                            matrix: Qt.matrix4x4(1, -0.29, 0, 0.29 * seg.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                                        }
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: osdWin.isVol ? (root.sink?.description ?? "SIN SALIDA").toUpperCase() : (Brightness.monitors.length > 1 ? "PORTÁTIL + " + (Brightness.monitors.length - 1) + " EXTERNO(S)" : "PORTÁTIL")
                                color: Qt.alpha(Theme.telemetry, 0.7)
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 2
                            }
                        }

                        // Cifra
                        Text {
                            Layout.preferredWidth: 84
                            horizontalAlignment: Text.AlignRight
                            text: osdWin.off ? "—" : Math.round(osdWin.value * 100)
                            color: osdWin.off ? Qt.alpha(Theme.paper, 0.4) : Theme.paper
                            font.family: "Bebas Neue"
                            font.pixelSize: 58
                        }
                    }

                    // Sello SILENCIO
                    Item {
                        id: stamp
                        visible: osdWin.off
                        x: 180
                        y: 22
                        width: stampT.implicitWidth + 32
                        height: stampT.implicitHeight
                        rotation: -8
                        onVisibleChanged: if (visible)
                            stampIn.restart()
                        Rectangle {
                            x: 5
                            y: 5
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
                            text: "SILENCIO"
                            color: Theme.ink
                            font.family: "Bebas Neue"
                            font.pixelSize: 40
                            font.letterSpacing: 4
                        }
                        ParallelAnimation {
                            id: stampIn
                            NumberAnimation {
                                target: stamp
                                property: "scale"
                                from: 1.8
                                to: 1
                                duration: 250
                                easing.type: Easing.OutBack
                            }
                            NumberAnimation {
                                target: stamp
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 150
                            }
                        }
                    }
                }
            }

            // ═══ Tarjeta de pista (arriba a la derecha, bajo el reloj) ═══
            PanelWindow {
                id: trackWin
                screen: perScreen.modelData
                anchors {
                    top: true
                    right: true
                }
                margins {
                    top: 56
                    right: 28
                }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "velvet-track"
                color: "transparent"
                implicitWidth: 426
                implicitHeight: 98
                mask: Region {}

                property real p: root.trackShown && perScreen.here && root.player !== null ? 1 : 0
                Behavior on p {
                    enabled: Config.animations
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }
                visible: p > 0

                Item {
                    width: 426
                    height: 98
                    opacity: trackWin.p
                    transform: Translate {
                        x: (1 - trackWin.p) * 460
                    }

                    Shape {
                        x: 6
                        y: 6
                        width: 420
                        height: 92
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: Theme.accent
                            strokeColor: "transparent"
                            PathPolyline {
                                path: [Qt.point(21, 0), Qt.point(420, 0), Qt.point(420, 92), Qt.point(0, 92), Qt.point(21, 0)]
                            }
                        }
                    }
                    Shape {
                        width: 420
                        height: 92
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: Theme.paper
                            strokeColor: "transparent"
                            PathPolyline {
                                path: [Qt.point(21, 0), Qt.point(420, 0), Qt.point(420, 92), Qt.point(0, 92), Qt.point(21, 0)]
                            }
                        }
                    }

                    RowLayout {
                        x: 34
                        width: 420 - 34 - 18
                        height: 92
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 56
                            Layout.preferredHeight: 56
                            color: Theme.accent
                            rotation: -6
                            Text {
                                anchors.centerIn: parent
                                text: root.player?.isPlaying ? "♪" : "❚❚"
                                color: Theme.on(Theme.accent)
                                font.family: "Bebas Neue"
                                font.pixelSize: 30
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: root.trackTag
                                color: Theme.accent
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                font.weight: Font.ExtraBold
                                font.letterSpacing: 2
                            }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: root.player?.trackTitle || "Sin título"
                                color: Theme.ink
                                font.family: "Montserrat"
                                font.pixelSize: 16
                                font.weight: Font.Black
                                font.italic: true
                            }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: (root.player?.trackArtist ?? "").toUpperCase()
                                color: Theme.ink
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1
                            }
                        }
                    }
                }
            }
        }
    }
}
