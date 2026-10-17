import QtQuick
import "../config"
import "../services"
import "../clip"
import "../settings"

// Crear / editar un modo (página "edit" de ModeSelect), en coordenadas del escenario 1600×900.
// Los de serie solo cambian sus ajustes; nombre y estilo son fijos.
Item {
    id: root
    anchors.fill: parent

    property string modeId: ""                 // "" = nuevo
    readonly property bool isBuiltin: Modes.get(modeId)?.builtin ?? false
    property var favs: []                      // nombres de favoritas para la vista previa (los pone ModeSelect)

    // Formulario
    property string fName: ""
    property string fStyle: "general"
    property var fLook: ({})                   // { gaps, anim, blur, vrr }
    property var fSet: ({})                    // { profile, lock, dpms, dnd, night, gamemode, … }

    readonly property var pal: Theme.palettes[fStyle]
    readonly property color tone: pal.trio[0]

    signal done(string id)
    signal cancel
    signal say(string text)

    // Carga el modo (o valores del estilo si es nuevo) y pone el foco en el nombre
    function load(id) {
        modeId = id;
        const m = Modes.get(id);
        if (m) {
            fName = m.name;
            fStyle = m.style;
            fLook = Modes.look(id);
            fSet = JSON.parse(JSON.stringify(Config.forMode(id)));
        } else {
            fName = "";
            fStyle = "general";
            fLook = Object.assign({}, Modes.lookDefaults.general);
            fSet = Object.assign(JSON.parse(JSON.stringify(Config.defaults.general)), {
                apps: []
            });
        }
        nameIn.text = fName;
        if (!isBuiltin)
            nameIn.forceActiveFocus();
    }

    function setS(k, v) {
        const o = Object.assign({}, fSet);
        o[k] = v;
        fSet = o;
    }
    function setL(k, v) {
        const o = Object.assign({}, fLook);
        o[k] = v;
        fLook = o;
    }
    // "Partir de": copia ajustes, apps al entrar y look de otro modo (no el nombre ni el estilo)
    function copyFrom(id) {
        fSet = JSON.parse(JSON.stringify(Config.forMode(id)));
        fLook = Modes.look(id);
        say("AJUSTES DE " + Modes.nameOf(id) + " COPIADOS");
    }

    function save() {
        const r = Modes.save(modeId, {
            name: fName,
            style: fStyle,
            look: fLook,
            settings: fSet
        });
        if (r.error) {
            say(r.error);
            return;
        }
        done(r.id);
        say(Modes.nameOf(r.id) + " GUARDADO");
    }

    // Minutos en chips: los de siempre + el valor actual si es otro
    function minutes(list, cur) {
        const vals = list.includes(cur) ? list : list.concat([cur]);
        return vals.filter(v => v !== 0).sort((a, b) => a - b).concat([0]).map(v => ({
                    label: v === 0 ? "NUNCA" : v + " MIN",
                    value: v
                }));
    }
    readonly property var yesNo: [
        {
            label: "SÍ",
            value: true
        },
        {
            label: "NO",
            value: false
        }
    ]

    // Fila del formulario: texto a la izquierda, control a la derecha de la columna 250
    component FormRow: Item {
        id: fr
        property string label
        property string desc
        default property alias control: slot.data
        width: 1000
        height: 48
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Text {
                text: fr.label
                color: Theme.paper
                font {
                    family: "Montserrat"
                    pixelSize: 15
                    weight: Font.Black
                    letterSpacing: 0.5
                }
            }
            Text {
                text: fr.desc
                color: "#C3C5D9"
                font {
                    family: "JetBrains Mono"
                    pixelSize: 9
                    bold: true
                    letterSpacing: 1.5
                }
            }
        }
        Item {
            id: slot
            x: 250
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Qt.alpha(Theme.paper, 0.12)
        }
    }

    // ── Formulario ──
    Column {
        x: 56
        y: 180
        width: 1000

        // Nombre
        FormRow {
            height: 60
            label: "NOMBRE"
            desc: root.isBuiltin ? "DE SERIE: NOMBRE Y ESTILO FIJOS" : "HASTA 10 LETRAS"
            Item {
                width: 300
                height: 42
                Rectangle {
                    id: nameBg
                    anchors.fill: parent
                    color: root.isBuiltin ? "transparent" : Theme.paper
                    border.width: root.isBuiltin ? 2 : 0
                    border.color: Qt.alpha(Theme.paper, 0.35)
                    antialiasing: true
                    transform: Matrix4x4 {
                        matrix: Qt.matrix4x4(1, -0.14, 0, 0.14 * 21, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                    }
                }
                TextInput {
                    id: nameIn
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    readOnly: root.isBuiltin
                    maximumLength: 10
                    color: root.isBuiltin ? Theme.paper : Theme.ink
                    font.family: "Bebas Neue"
                    font.pixelSize: 28
                    font.letterSpacing: 2
                    font.capitalization: Font.AllUppercase
                    onTextEdited: root.fName = text.toUpperCase()
                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Escape)
                            root.cancel();
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || (e.key === Qt.Key_S && (e.modifiers & Qt.ControlModifier)))
                            root.save();
                        else
                            return;
                        e.accepted = true;
                    }
                    Text {
                        visible: nameIn.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ESTUDIO"
                        color: Qt.alpha(Theme.ink, 0.35)
                        font: nameIn.font
                    }
                }
            }
        }

        // Estilo
        FormRow {
            height: 74
            label: "ESTILO"
            desc: "COLORES · FONDOS · TERMINAL"
            Row {
                spacing: 12
                Repeater {
                    model: Modes.styles
                    Item {
                        id: st
                        required property var modelData
                        readonly property bool on: root.fStyle === modelData.id
                        readonly property var trio: Theme.palettes[modelData.id].trio
                        visible: !root.isBuiltin || on
                        width: stChip.width
                        height: 46
                        SkewChip {
                            id: stChip
                            height: 46
                            label: "        " + st.modelData.label     // hueco para la tríada
                            fill: st.on ? Theme.paper : "transparent"
                            fg: st.on ? Theme.ink : Theme.paper
                            border: st.on ? Theme.paper : Qt.alpha(Theme.paper, 0.35)
                            shadow: st.on ? st.trio[0] : "transparent"
                            size: 22
                            padding: 16
                            onClicked: if (!root.isBuiltin)
                                root.fStyle = st.modelData.id
                        }
                        Row {
                            x: 18
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Repeater {
                                model: st.trio
                                Rectangle {
                                    required property var modelData
                                    width: 10
                                    height: 22
                                    color: modelData
                                    border.width: 2
                                    border.color: Theme.ink
                                    antialiasing: true
                                    transform: Matrix4x4 {
                                        matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * 11, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        FormRow {
            label: "PARTIR DE"
            desc: "COPIA AJUSTES, APPS Y LOOK DE OTRO MODO"
            Choice {
                tone: root.tone
                options: Modes.all.filter(m => m.id !== root.modeId).slice(0, 6).map(m => ({
                            label: m.name,
                            value: m.id
                        }))
                value: null
                onPicked: v => root.copyFrom(v)
            }
        }
        FormRow {
            label: "PERFIL DE ENERGÍA"
            desc: "POWER-PROFILES-DAEMON"
            Choice {
                tone: root.tone
                options: [
                    {
                        label: "AHORRO",
                        value: "power-saver"
                    },
                    {
                        label: "EQUILIBRADO",
                        value: "balanced"
                    },
                    {
                        label: "RENDIMIENTO",
                        value: "performance"
                    }
                ]
                value: root.fSet.profile ?? "balanced"
                onPicked: v => root.setS("profile", v)
            }
        }
        FormRow {
            label: "BLOQUEAR TRAS"
            desc: "HYPRIDLE · SIN USO"
            Choice {
                tone: root.tone
                options: root.minutes([5, 10, 20], root.fSet.lock ?? 5)
                value: root.fSet.lock ?? 5
                onPicked: v => root.setS("lock", v)
            }
        }
        FormRow {
            label: "APAGAR PANTALLA TRAS"
            desc: "HYPRIDLE · DPMS"
            Choice {
                tone: root.tone
                options: root.minutes([10, 20, 30], root.fSet.dpms ?? 10)
                value: root.fSet.dpms ?? 10
                onPicked: v => root.setS("dpms", v)
            }
        }
        FormRow {
            label: "NO MOLESTAR"
            desc: "SOLO PASAN LAS CRÍTICAS"
            Choice {
                tone: root.tone
                options: root.yesNo
                value: root.fSet.dnd ?? false
                onPicked: v => root.setS("dnd", v)
            }
        }
        FormRow {
            label: "LUZ NOCTURNA"
            desc: "HYPRSUNSET"
            Choice {
                tone: root.tone
                options: root.yesNo
                value: root.fSet.night ?? true
                onPicked: v => root.setS("night", v)
            }
        }
        FormRow {
            label: "GAMEMODE"
            desc: "CPU Y GPU A TOPE"
            Choice {
                tone: root.tone
                options: root.yesNo
                value: root.fSet.gamemode ?? false
                onPicked: v => root.setS("gamemode", v)
            }
        }
        FormRow {
            label: "HUECOS ENTRE VENTANAS"
            desc: "HYPRLAND"
            Choice {
                tone: root.tone
                options: [
                    {
                        label: "NORMAL",
                        value: "normal"
                    },
                    {
                        label: "COMPACTO",
                        value: "compact"
                    },
                    {
                        label: "NINGUNO",
                        value: "none"
                    }
                ]
                value: root.fLook.gaps ?? "normal"
                onPicked: v => root.setL("gaps", v)
            }
        }
        FormRow {
            label: "ANIMACIONES · BLUR"
            desc: "HYPRLAND · PULSA PARA ACTIVAR / QUITAR"
            Row {
                spacing: 10
                Repeater {
                    model: [
                        {
                            k: "anim",
                            t: "ANIMACIONES"
                        },
                        {
                            k: "blur",
                            t: "BLUR"
                        }
                    ]
                    SkewChip {
                        required property var modelData
                        readonly property bool on: root.fLook[modelData.k] ?? true
                        height: 36
                        label: (on ? "✓ " : "") + modelData.t
                        fill: on ? root.tone : "transparent"
                        fg: on ? Theme.on(root.tone) : Theme.paper
                        border: on ? root.tone : Qt.alpha(Theme.paper, 0.35)
                        size: 21
                        padding: 16
                        onClicked: root.setL(modelData.k, !on)
                    }
                }
            }
        }
        FormRow {
            label: "VRR"
            desc: "FRECUENCIA VARIABLE"
            Choice {
                tone: root.tone
                options: [
                    {
                        label: "NO",
                        value: 0
                    },
                    {
                        label: "SIEMPRE",
                        value: 1
                    },
                    {
                        label: "PANT. COMPLETA",
                        value: 2
                    }
                ]
                value: root.fLook.vrr ?? 0
                onPicked: v => root.setL("vrr", v)
            }
        }
        Text {
            topPadding: 12
            text: "FAVORITAS DEL LANZADOR, FONDO Y APPS AL ENTRAR → AJUSTES, CON ESTE MODO ACTIVO"
            color: root.pal.telemetry
            font {
                family: "JetBrains Mono"
                pixelSize: 9
                bold: true
                letterSpacing: 1.5
            }
        }
    }

    // ── Vista previa: la carta tal como saldrá en el selector ──
    Text {
        x: 1130
        y: 180
        text: "VISTA PREVIA // ASÍ SALE EN EL SELECTOR"
        color: root.pal.telemetry
        font {
            family: "JetBrains Mono"
            pixelSize: 9
            weight: Font.ExtraBold
            letterSpacing: 2
        }
    }
    ModeCard {
        x: 1150
        y: 210
        transformOrigin: Item.TopLeft
        scale: 0.76
        rotation: -2
        enabled: false
        n: root.modeId ? Math.max(1, Modes.shown.findIndex(m => m.id === root.modeId) + 1) : Modes.shown.length + 1
        name: root.fName || "NUEVO"
        persona: Modes.styleLabel(root.fStyle)
        tag: root.isBuiltin ? (Modes.get(root.modeId)?.tag ?? "") : "MODO PROPIO · " + Modes.styleLabel(root.fStyle)
        trio: root.pal.trio
        tele: root.pal.telemetry
        wallpaper: root.modeId && Modes.styleOf(root.modeId) === root.fStyle ? Wallpapers.currentFor(root.modeId) : (Wallpapers.forMode(root.fStyle, "all")[0]?.path ?? "")
        favs: root.favs
        active: true
    }

    Row {
        x: 1150
        y: 210 + 520 * 0.76 + 44
        spacing: 14
        SkewChip {
            height: 52
            label: "GUARDAR MODO ▶"
            fill: Theme.paper
            fg: Theme.ink
            shadow: root.tone
            size: 28
            padding: 26
            onClicked: root.save()
        }
        SkewChip {
            height: 52
            label: "CANCELAR"
            fill: "transparent"
            fg: Theme.paper
            border: Qt.alpha(Theme.paper, 0.5)
            size: 24
            padding: 20
            onClicked: root.cancel()
        }
    }
}
