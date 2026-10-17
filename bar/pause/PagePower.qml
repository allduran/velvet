import Quickshell
import QtQuick

Column {
    id: root
    spacing: 2
    signal done

    property string armed: ""
    onVisibleChanged: armed = ""

    readonly property var actions: [
        {
            label: "BLOQUEAR",
            meta: "",
            confirm: false,
            cmd: "qs -c velvet ipc call lock lock"
        },
        {
            label: "SUSPENDER",
            meta: "BLOQUEA ANTES",
            confirm: false,
            cmd: "qs -c velvet ipc call lock lock ; sleep 1 ; systemctl suspend"
        },
        {
            label: "CERRAR SESIÓN",
            meta: "",
            confirm: true,
            cmd: "hyprctl dispatch 'hl.dsp.exit()'"
        },
        {
            label: "REINICIAR",
            meta: "",
            confirm: true,
            cmd: "systemctl reboot"
        },
        {
            label: "APAGAR",
            meta: "",
            confirm: true,
            cmd: "systemctl poweroff"
        }
    ]

    Repeater {
        model: root.actions
        delegate: PauseRow {
            required property var modelData
            readonly property bool isArmed: root.armed === modelData.label
            label: modelData.label
            meta: isArmed ? "PULSA OTRA VEZ PARA CONFIRMAR" : modelData.meta
            danger: modelData.label === "APAGAR" || isArmed
            onClicked: {
                if (modelData.confirm && !isArmed) {
                    root.armed = modelData.label;
                    return;
                }
                root.done();
                Quickshell.execDetached(["sh", "-c", modelData.cmd]);
            }
        }
    }
}
