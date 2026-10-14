import QtQuick
import "../config"
import "../clip"

// − valor +
Row {
    id: root
    property int value
    property int from: 1
    property int to: 60
    property string unit: ""
    signal stepped(int value)
    spacing: 10

    SkewChip {
        anchors.verticalCenter: parent.verticalCenter
        label: "−"
        fill: Theme.ink
        border: Theme.paper
        size: 24
        padding: 14
        height: 40
        onClicked: if (root.value > root.from) root.stepped(root.value - 1)
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 96
        horizontalAlignment: Text.AlignHCenter
        text: root.value + " " + root.unit
        color: Theme.paper
        font {
            family: "Bebas Neue"
            pixelSize: 34
            letterSpacing: 1
        }
    }
    SkewChip {
        anchors.verticalCenter: parent.verticalCenter
        label: "+"
        fill: Theme.ink
        border: Theme.paper
        size: 24
        padding: 14
        height: 40
        onClicked: if (root.value < root.to) root.stepped(root.value + 1)
    }
}
