pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Telemetría del sistema leída de /proc y /sys.
// El histórico de CPU se muestrea siempre (muy barato); el resto solo con el panel abierto.
Singleton {
    id: root

    readonly property bool active: Ui.perfScreen !== ""

    // ── CPU ──
    property real cpu: 0            // 0–1
    property var cores: []          // 0–1 por hilo
    property var history: []        // últimos 60 s, 0–1
    property real freqGHz: 0
    property real temp: 0           // °C
    // ── Memoria (bytes) ──
    property real memTotal: 0
    property real memUsed: 0
    property real swapUsed: 0
    property real cached: 0
    // ── iGPU ──
    property int gpuMhz: 0
    property int gpuMaxMhz: 0
    // ── Discos ──
    property var disks: []          // [{ label, size, used }]
    property real diskRead: 0       // MB/s
    property real diskWrite: 0
    // ── Red ──
    property string iface: ""
    property real netDown: 0        // MB/s
    property real netUp: 0
    property int ping: -1           // ms
    // ── Otros ──
    property real uptime: 0         // s
    property var procs: []          // [{ name, cpu }]

    property var _prevCpu: []
    property var _prevDisk: null
    property var _prevNet: null

    // ═══ Muestreo ═══
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fStat.reload();
            if (!root.active)
                return;
            fMem.reload();
            fInfo.reload();
            fDisk.reload();
            fNet.reload();
            fUp.reload();
            if (fTemp.path !== "")
                fTemp.reload();
            if (fGpu.path !== "")
                fGpu.reload();
        }
    }
    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!pTop.running)
            pTop.running = true
    }
    Timer {
        interval: 10000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!pPing.running)
            pPing.running = true
    }
    Timer {
        interval: 30000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!pDf.running)
            pDf.running = true
    }

    // ═══ /proc ═══
    FileView {
        id: fStat
        path: "/proc/stat"
        onLoaded: {
            const now = text().split("\n").filter(l => l.startsWith("cpu")).map(l => {
                const n = l.trim().split(/\s+/).slice(1).map(Number);
                return [n[3] + (n[4] || 0), n.reduce((a, b) => a + b, 0)];
            });
            const prev = root._prevCpu;
            if (prev.length === now.length) {
                const u = now.map((c, i) => {
                    const dt = c[1] - prev[i][1];
                    return dt > 0 ? Math.max(0, Math.min(1, 1 - (c[0] - prev[i][0]) / dt)) : 0;
                });
                root.cpu = u[0];
                root.cores = u.slice(1);
                const h = root.history.slice(-59);
                h.push(u[0]);
                root.history = h;
            }
            root._prevCpu = now;
        }
    }

    FileView {
        id: fMem
        path: "/proc/meminfo"
        onLoaded: {
            const m = {};
            for (const l of text().split("\n")) {
                const p = l.split(/:\s+/);
                if (p.length === 2)
                    m[p[0]] = parseInt(p[1]) * 1024;
            }
            root.memTotal = m.MemTotal;
            root.memUsed = m.MemTotal - m.MemAvailable;
            root.swapUsed = m.SwapTotal - m.SwapFree;
            root.cached = m.Cached;
        }
    }

    FileView {
        id: fInfo
        path: "/proc/cpuinfo"
        onLoaded: {
            const f = (text().match(/cpu MHz\s*:\s*[\d.]+/g) || []).map(s => parseFloat(s.split(":")[1]));
            if (f.length)
                root.freqGHz = f.reduce((a, b) => a + b, 0) / f.length / 1000;
        }
    }

    FileView {
        id: fDisk
        path: "/proc/diskstats"
        onLoaded: {
            let r = 0, w = 0;
            for (const l of text().split("\n")) {
                const f = l.trim().split(/\s+/);
                if (f.length < 10 || !/^(nvme\d+n\d+|sd[a-z]+|vd[a-z]+|mmcblk\d+)$/.test(f[2]))
                    continue;
                r += Number(f[5]) * 512;
                w += Number(f[9]) * 512;
            }
            const t = Date.now();
            const p = root._prevDisk;
            if (p) {
                const s = (t - p.t) / 1000;
                root.diskRead = (r - p.r) / s / 1048576;
                root.diskWrite = (w - p.w) / s / 1048576;
            }
            root._prevDisk = {
                r: r,
                w: w,
                t: t
            };
        }
    }

    FileView {
        id: fNet
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0, best = "", bestRx = -1;
            for (const l of text().split("\n").slice(2)) {
                const parts = l.split(":");
                if (parts.length < 2)
                    continue;
                const name = parts[0].trim();
                if (name === "lo")
                    continue;
                const f = parts[1].trim().split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
                if (f[0] > bestRx) {
                    bestRx = f[0];
                    best = name;
                }
            }
            const t = Date.now();
            const p = root._prevNet;
            if (p) {
                const s = (t - p.t) / 1000;
                root.netDown = Math.max(0, (rx - p.rx) / s / 1048576);
                root.netUp = Math.max(0, (tx - p.tx) / s / 1048576);
            }
            root._prevNet = {
                rx: rx,
                tx: tx,
                t: t
            };
            root.iface = best;
        }
    }

    FileView {
        id: fUp
        path: "/proc/uptime"
        onLoaded: root.uptime = parseFloat(text().split(" ")[0])
    }

    // ═══ /sys (rutas descubiertas al arrancar) ═══
    FileView {
        id: fTemp
        path: ""
        onLoaded: root.temp = parseInt(text()) / 1000
    }
    FileView {
        id: fGpu
        path: ""
        onLoaded: root.gpuMhz = parseInt(text())
    }
    FileView {
        id: fGpuMax
        path: ""
        onLoaded: root.gpuMaxMhz = parseInt(text())
    }

    Process {
        running: true
        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && echo \"T $z/temp\" && break; done; " + "for c in /sys/class/drm/card*; do [ -f $c/gt_cur_freq_mhz ] && echo \"G $c\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const l of text.split("\n")) {
                    if (l.startsWith("T "))
                        fTemp.path = l.slice(2);
                    if (l.startsWith("G ")) {
                        fGpu.path = l.slice(2) + "/gt_cur_freq_mhz";
                        fGpuMax.path = l.slice(2) + "/gt_max_freq_mhz";
                    }
                }
            }
        }
    }

    // ═══ Procesos externos ═══
    Process {
        id: pTop
        command: ["sh", "-c", "LC_ALL=C top -b -n2 -d0.5 -o %CPU | awk '/^ *PID/{b++; next} b==2 && NF>=12 {print $9, $12}' | head -5"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.procs = text.trim().split("\n").filter(l => l).map(l => {
                    const i = l.indexOf(" ");
                    return {
                        cpu: parseFloat(l.slice(0, i)),
                        name: l.slice(i + 1)
                    };
                });
            }
        }
    }

    Process {
        id: pPing
        command: ["ping", "-c1", "-W1", "1.1.1.1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/time=([\d.]+)/);
                root.ping = m ? Math.round(parseFloat(m[1])) : -1;
            }
        }
    }

    Process {
        id: pDf
        command: ["df", "-B1", "--output=target,size,used", "/", "/mnt/data"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.disks = text.trim().split("\n").slice(1).map(l => {
                    const f = l.trim().split(/\s+/);
                    return {
                        label: f[0] === "/" ? "/" : f[0].split("/").pop().toUpperCase(),
                        size: Number(f[1]),
                        used: Number(f[2])
                    };
                });
            }
        }
    }
}
