import QtQuick
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"

// Fondo de escritorio por monitor, con fundido al cambiar.
// Además mide el brillo de la franja superior para que la barra adapte su color.
PanelWindow {
    id: win

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "velvet-wallpaper"
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Theme.canvas

    property Image front: a
    property string sampleUrl: ""

    function apply() {
        const p = Wallpapers.current;
        if (!p)
            return;
        const url = "file://" + p;
        if (front.source.toString() === url)
            return;
        const back = front === a ? b : a;
        back.opacity = 0;
        back.z = 1;
        front.z = 0;
        back.source = url;
        sample(url);
    }

    function ready(img) {
        if (img.status === Image.Ready && img.z === 1) {
            img.opacity = 1;
            win.front = img;
        }
    }

    function sample(url) {
        if (sampleUrl && sampleUrl !== url)
            sampler.unloadImage(sampleUrl);
        sampleUrl = url;
        sampler.loadImage(url);
        if (sampler.isImageLoaded(url))
            sampler.requestPaint();
    }

    // Muestreador: dibuja el fondo en miniatura (proporción 16:9) y lee la franja de arriba.
    // Queda tapado por las imágenes (z -1).
    Canvas {
        id: sampler
        z: -1
        width: 128
        height: 72
        onImageLoaded: requestPaint()
        onPaint: {
            if (!win.sampleUrl || !isImageLoaded(win.sampleUrl))
                return;
            const g = getContext("2d");
            g.clearRect(0, 0, width, height);
            g.drawImage(win.sampleUrl, 0, 0, width, height);

            const rows = 3;   // ≈ alto de la barra
            const d = g.getImageData(0, 0, width, rows).data;
            const ranges = {
                left: [0, 0.35],
                center: [0.35, 0.65],
                right: [0.65, 1]
            };
            const out = {};
            for (const k in ranges) {
                const x0 = Math.floor(ranges[k][0] * width), x1 = Math.floor(ranges[k][1] * width);
                let sum = 0, sq = 0, n = 0;
                for (let y = 0; y < rows; y++)
                    for (let x = x0; x < x1; x++) {
                        const i = (y * width + x) * 4;
                        const l = (0.2126 * d[i] + 0.7152 * d[i + 1] + 0.0722 * d[i + 2]) / 255;
                        sum += l;
                        sq += l * l;
                        n++;
                    }
                const mean = sum / n;
                out[k] = {
                    mean: mean,
                    dev: Math.sqrt(Math.max(0, sq / n - mean * mean))
                };
            }
            Contrast.set(win.screen.name, out);
        }
    }

    Image {
        id: a
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(win.screen.width, win.screen.height)
        opacity: 0
        Behavior on opacity {
            NumberAnimation {
                duration: 450
                easing.type: Easing.OutCubic
            }
        }
        onStatusChanged: win.ready(a)
    }
    Image {
        id: b
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(win.screen.width, win.screen.height)
        opacity: 0
        Behavior on opacity {
            NumberAnimation {
                duration: 450
                easing.type: Easing.OutCubic
            }
        }
        onStatusChanged: win.ready(b)
    }

    Connections {
        target: Wallpapers
        function onCurrentChanged() {
            win.apply();
        }
    }
    Component.onCompleted: apply()
}
