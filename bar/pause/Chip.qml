import QtQuick
import "../../config"
import "../../components"

Item {
    id: root
    property string label
    property bool active
    property int tone: 0
    signal clicked
    implicitWidth: t.implicitWidth + 20
    implicitHeight: 24

    Slant {
        anchors.fill: parent
        color: root.active ? Theme.at(root.tone) : area.containsMouse ? Qt.alpha(Theme.paper, 0.10) : "transparent"
        borderWidth: root.active ? 0 : 1
        borderColor: Qt.alpha(Theme.paper, 0.35)
    }
    Text {
        id: t
        anchors.centerIn: parent
        text: root.label
        color: root.active ? Theme.on(Theme.at(root.tone)) : Theme.paper
        font {
            family: "Bebas Neue"
            pixelSize: 14
            letterSpacing: 1
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
