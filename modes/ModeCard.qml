import QtQuick
import QtQuick.Shapes
import "../config"

// Carta de un modo: banda, nombre, trío, fondo y favoritas
Item {
    id: root
    property int n: 1
    property string name
    property string persona
    property string tag
    property var trio: ["#E60012", "#0055FF", "#FFE600"]
    property color tele: Theme.telemetry
    property string wallpaper: ""         // ruta del fondo del modo
    property var favs: []                 // nombres de las 4 favoritas
    property bool active: false
    property bool current: false
    signal picked
    signal confirmed

    width: 350
    height: 520

    readonly property real k: 21          // inclinación de los lados (6 %)
    function edge(y) {
        return k - k * y / height;        // x del lado izquierdo a la altura y
    }

    // Sombras duras
    Shape {
        visible: root.active
        x: 18
        y: 18
        width: root.width
        height: root.height
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.trio[2]
            strokeColor: "transparent"
            PathPolyline {
                path: [Qt.point(root.k, 0), Qt.point(root.width, 0), Qt.point(root.width - root.k, root.height), Qt.point(0, root.height), Qt.point(root.k, 0)]
            }
        }
    }
    Shape {
        x: 9
        y: 9
        width: root.width
        height: root.height
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.trio[1]
            strokeColor: "transparent"
            PathPolyline {
                path: [Qt.point(root.k, 0), Qt.point(root.width, 0), Qt.point(root.width - root.k, root.height), Qt.point(0, root.height), Qt.point(root.k, 0)]
            }
        }
    }

    // Cuerpo + banda superior
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: Theme.surface
            strokeColor: root.active ? Theme.paper : Qt.alpha(Theme.paper, 0.35)
            strokeWidth: 3
            PathPolyline {
                path: [Qt.point(root.k, 0), Qt.point(root.width, 0), Qt.point(root.width - root.k, root.height), Qt.point(0, root.height), Qt.point(root.k, 0)]
            }
        }
        ShapePath {
            fillColor: root.trio[0]
            strokeColor: "transparent"
            PathPolyline {
                path: [Qt.point(root.k + 2, 2), Qt.point(root.width - 2, 2), Qt.point(root.width - 2 - root.k * 40 / root.height, 40), Qt.point(root.edge(40) + 2, 40), Qt.point(root.k + 2, 2)]
            }
        }
    }

    Text {
        x: 34
        y: 13
        text: "MODE.0" + root.n
        color: Theme.on(root.trio[0])
        font {
            family: "JetBrains Mono"
            pixelSize: 11
            weight: Font.ExtraBold
            letterSpacing: 2
        }
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 30
        y: 13
        text: root.persona
        color: Theme.on(root.trio[0])
        font {
            family: "JetBrains Mono"
            pixelSize: 11
            weight: Font.ExtraBold
            letterSpacing: 2
        }
    }

    // Nombre + trío
    Text {
        id: nameT
        x: 30
        y: 52
        text: root.name
        color: Theme.paper
        font {
            family: "Bebas Neue"
            pixelSize: root.name.length > 5 ? 76 : 92
            letterSpacing: 3
        }
        lineHeight: 0.85
    }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 36
        y: nameT.y + nameT.height - 44
        spacing: 4
        Repeater {
            model: root.trio
            Rectangle {
                required property var modelData
                width: 20
                height: 34
                color: modelData
                border.width: 2
                border.color: Theme.ink
                antialiasing: true
                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * 17, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }
            }
        }
    }
    Text {
        x: 30
        y: nameT.y + nameT.height + 2
        text: root.tag
        color: root.tele
        font {
            family: "JetBrains Mono"
            pixelSize: 10
            bold: true
            letterSpacing: 1.5
        }
    }

    // Fondo del modo
    Item {
        id: wall
        x: 28
        y: 196
        width: root.width - 62
        height: 118
        Image {
            anchors.fill: parent
            visible: root.wallpaper !== ""
            source: root.wallpaper ? "file://" + root.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 600
            asynchronous: true
        }
        Text {
            visible: root.wallpaper === ""
            anchors.centerIn: parent
            text: "SIN FONDO PARA ESTE MODO"
            color: Qt.alpha(Theme.paper, 0.5)
            font {
                family: "JetBrains Mono"
                pixelSize: 10
                bold: true
                letterSpacing: 1.5
            }
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: Theme.paper
        }
        Rectangle {
            visible: root.wallpaper !== ""
            x: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            width: wn.implicitWidth + 12
            height: wn.implicitHeight + 4
            color: Theme.ink
            Text {
                id: wn
                anchors.centerIn: parent
                text: root.wallpaper.split("/").pop()
                color: Theme.paper
                font {
                    family: "JetBrains Mono"
                    pixelSize: 9
                    weight: Font.ExtraBold
                    letterSpacing: 1
                }
            }
        }
    }

    // Favoritas
    Text {
        x: 28
        y: wall.y + wall.height + 16
        text: "FAVORITAS // LANZADOR"
        color: root.tele
        font {
            family: "JetBrains Mono"
            pixelSize: 9
            weight: Font.ExtraBold
            letterSpacing: 2
        }
    }
    Column {
        x: 28
        y: wall.y + wall.height + 38
        spacing: 6
        Repeater {
            model: root.favs
            Row {
                id: fav
                required property var modelData
                required property int index
                spacing: 10
                Rectangle {
                    width: 22
                    height: 22
                    color: root.trio[fav.index % 3]
                    Text {
                        anchors.centerIn: parent
                        text: fav.index + 1
                        color: Theme.on(root.trio[fav.index % 3])
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 11
                            weight: Font.ExtraBold
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    elide: Text.ElideRight
                    text: fav.modelData
                    color: Theme.paper
                    font {
                        family: "Bebas Neue"
                        pixelSize: 21
                        letterSpacing: 1.5
                    }
                }
            }
        }
    }

    // Sello ACTUAL
    Rectangle {
        visible: root.current
        anchors.right: parent.right
        anchors.rightMargin: -6
        y: 52
        width: stT.implicitWidth + 20
        height: stT.implicitHeight + 10
        rotation: 8
        color: Theme.paper
        Rectangle {
            z: -1
            x: 4
            y: 4
            width: parent.width
            height: parent.height
            color: root.trio[0]
        }
        Text {
            id: stT
            anchors.centerIn: parent
            text: "● ACTUAL"
            color: Theme.ink
            font {
                family: "JetBrains Mono"
                pixelSize: 12
                weight: Font.ExtraBold
                letterSpacing: 2
            }
        }
    }

    // Tecla
    Rectangle {
        x: -14
        y: root.height - 32
        width: 46
        height: 46
        rotation: -8
        color: root.active ? Theme.paper : Theme.ink
        border.width: 3
        border.color: Theme.paper
        Text {
            anchors.centerIn: parent
            text: root.n
            color: root.active ? Theme.ink : Theme.paper
            font {
                family: "Bebas Neue"
                pixelSize: 30
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.active ? root.confirmed() : root.picked()
        onDoubleClicked: root.confirmed()
    }
}
