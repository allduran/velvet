import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../config"
import "../services"

PanelWindow {
    id: win
    visible: Notifs.banner !== null && Hyprland.focusedMonitor?.name === screen?.name
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "velvet-banner"
    color: "transparent"
    mask: Region {}                          // no bloquea clics

    onVisibleChanged: if (visible) {
        if (Config.animations)
            sweep.restart();
        else
            tr.x = 0;
    }

    Item {
        id: band
        anchors.centerIn: parent
        width: parent.width * 1.3
        height: 220
        rotation: -8
        transform: Translate {
            id: tr
        }

        Rectangle {
            width: parent.width
            height: 10
            color: Theme.accent2
        }
        Rectangle {
            y: 22
            width: parent.width
            height: 160
            color: Theme.accent

            Row {
                anchors.centerIn: parent
                spacing: 40
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (Notifs.banner?.summary ?? "").toUpperCase()
                    color: Theme.paper
                    style: Text.Raised
                    styleColor: Theme.ink
                    font {
                        family: "Bebas Neue"
                        pixelSize: 120
                        letterSpacing: 8
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 360
                    wrapMode: Text.WordWrap
                    text: (Notifs.banner?.body ?? "").toUpperCase()
                    color: Theme.paper
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 14
                        weight: Font.ExtraBold
                        letterSpacing: 2
                    }
                }
            }
        }
        Rectangle {
            y: 194
            width: parent.width
            height: 10
            color: Theme.accent3
        }
    }

    // Entra, se queda y sale
    SequentialAnimation {
        id: sweep
        NumberAnimation {
            target: tr
            property: "x"
            from: -win.width * 1.3
            to: 0
            duration: 300
            easing.type: Easing.OutCubic
        }
        PauseAnimation {
            duration: 1100
        }
        NumberAnimation {
            target: tr
            property: "x"
            to: win.width * 1.3
            duration: 300
            easing.type: Easing.InCubic
        }
    }
}
