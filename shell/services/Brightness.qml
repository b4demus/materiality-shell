pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight brightness. Best-effort: on this VM there is usually no
// /sys/class/backlight device, in which case `available` stays false and the
// OSD simply never shows a brightness bar.
Singleton {
    id: root

    property bool available: false
    property string device: ""
    property int max: 1
    property int raw: 0
    readonly property real value: max > 0 ? raw / max : 0
    property bool hasBrightnessctl: false

    function setValue(v) {
        if (!available) return
        const pct = Math.round(Math.max(0.01, Math.min(1.0, v)) * 100)
        if (hasBrightnessctl)
            writeProc.exec(["brightnessctl", "-d", device, "set", pct + "%"])
        else
            writeProc.exec(["sh", "-c", `printf '%s' ${Math.round(v * max)} > /sys/class/backlight/${device}/brightness`])
        raw = Math.round(v * max)
    }
    function change(delta) { setValue(value + delta) }

    Process { id: writeProc; function exec(c) { command = c; running = true } }

    Process {
        id: probe
        running: true
        command: ["sh", "-c",
            "d=$(ls -1 /sys/class/backlight 2>/dev/null | head -n1); " +
            "[ -n \"$d\" ] || exit 0; " +
            "printf '%s\\n%s\\n%s\\n' \"$d\" \"$(cat /sys/class/backlight/$d/max_brightness)\" \"$(cat /sys/class/backlight/$d/brightness)\"; " +
            "command -v brightnessctl >/dev/null && echo bctl || echo nobctl"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length >= 3 && lines[0]) {
                    root.device = lines[0]
                    root.max = parseInt(lines[1]) || 1
                    root.raw = parseInt(lines[2]) || 0
                    root.hasBrightnessctl = (lines[3] === "bctl")
                    root.available = true
                }
            }
        }
    }

    // Poll for external changes when a device exists.
    Timer {
        interval: 2000
        repeat: true
        running: root.available
        onTriggered: readProc.exec(["cat", `/sys/class/backlight/${root.device}/brightness`])
    }
    Process {
        id: readProc
        function exec(c) { command = c; running = true }
        stdout: StdioCollector {
            onStreamFinished: { const n = parseInt(text.trim()); if (!isNaN(n)) root.raw = n }
        }
    }
}
