import QtQuick
import "../config"
import "../clip"

// Grupo de chips inclinados: uno activo a la vez.
// options: [{ label, value }]
Row {
    id: root
    property var options: []
    property var value
    property color tone: Theme.accent
    signal picked(var value)
    spacing: 10

    Repeater {
        model: root.options
        SkewChip {
            required property var modelData
            readonly property bool on: modelData.value === root.value
            label: modelData.label
            fill: on ? root.tone : "transparent"
            fg: on ? Theme.on(root.tone) : Theme.paper
            border: on ? root.tone : Qt.alpha(Theme.paper, 0.35)
            size: 21
            padding: 16
            height: 36
            onClicked: root.picked(modelData.value)
        }
    }
}
