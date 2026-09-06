pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// ---------------------------------------------------------------------------
// Cheap system telemetry for the optional bar modules (CPU, memory, temperature,
// network throughput). One shell pass every couple of seconds — deliberately
// coarse, and only running while something is actually displaying it.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    // Bumped by each bar module that wants these numbers.
    property int subscribers: 0
    function subscribe() { subscribers++ }
    function unsubscribe() { subscribers = Math.max(0, subscribers - 1) }

    property real cpu: 0            // 0..1
    property real gpu: 0            // 0..1
    property bool gpuAvailable: false
    property real memory: 0         // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real temperature: 0    // °C, 0 when unknown
    property real rxRate: 0         // bytes/s
    property real txRate: 0

    // Previous samples, so rates are real deltas rather than totals.
    property var _cpuPrev: null
    property var _netPrev: null
    property real _lastSample: 0

    function humanRate(bytes) {
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + " MB/s"
        if (bytes >= 1024) return Math.round(bytes / 1024) + " kB/s"
        return Math.round(bytes) + " B/s"
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.subscribers > 0
        triggeredOnStart: true
        onTriggered: sample.running = true
    }

    Process {
        id: sample
        command: ["sh", "-c",
            'head -n1 /proc/stat; ' +
            'grep -E "^(MemTotal|MemAvailable):" /proc/meminfo; ' +
            'cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -n1; ' +
            'printf "GPU %s\\n" "$({ cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null; ' +
            'nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null; } ' +
            '| grep -m1 -oE "[0-9]+")"; ' +
            'awk \'NR>2 && $1 !~ /^lo:/ {rx+=$2; tx+=$10} END {print "NET", rx, tx}\' /proc/net/dev']
        stdout: StdioCollector {
            onStreamFinished: {
                const now = Date.now() / 1000
                const dt = root._lastSample > 0 ? now - root._lastSample : 0
                root._lastSample = now

                let memTotal = 0, memAvail = 0
                for (const line of text.split("\n")) {
                    if (line.indexOf("cpu ") === 0) {
                        const f = line.trim().split(/\s+/).slice(1).map(Number)
                        const idle = f[3] + (f[4] || 0)
                        const total = f.reduce((a, b) => a + b, 0)
                        if (root._cpuPrev) {
                            const dTotal = total - root._cpuPrev.total
                            const dIdle = idle - root._cpuPrev.idle
                            if (dTotal > 0) root.cpu = Math.max(0, Math.min(1, 1 - dIdle / dTotal))
                        }
                        root._cpuPrev = { total: total, idle: idle }
                    } else if (line.indexOf("MemTotal:") === 0) {
                        memTotal = parseInt(line.replace(/\D+/g, "")) || 0
                    } else if (line.indexOf("MemAvailable:") === 0) {
                        memAvail = parseInt(line.replace(/\D+/g, "")) || 0
                    } else if (line.indexOf("GPU") === 0) {
                        const v = line.trim().split(/\s+/)[1]
                        if (v && /^\d+$/.test(v)) {
                            root.gpu = Math.max(0, Math.min(1, parseInt(v) / 100))
                            root.gpuAvailable = true
                        } else {
                            root.gpuAvailable = false
                        }
                    } else if (line.indexOf("NET") === 0) {
                        const p = line.trim().split(/\s+/)
                        const rx = parseInt(p[1]) || 0
                        const tx = parseInt(p[2]) || 0
                        if (root._netPrev && dt > 0) {
                            root.rxRate = Math.max(0, (rx - root._netPrev.rx) / dt)
                            root.txRate = Math.max(0, (tx - root._netPrev.tx) / dt)
                        }
                        root._netPrev = { rx: rx, tx: tx }
                    } else if (/^\d+$/.test(line.trim()) && line.trim().length >= 4) {
                        root.temperature = parseInt(line.trim()) / 1000
                    }
                }
                if (memTotal > 0) {
                    root.memTotalGb = memTotal / 1048576
                    root.memUsedGb = (memTotal - memAvail) / 1048576
                    root.memory = (memTotal - memAvail) / memTotal
                }
            }
        }
    }
}
