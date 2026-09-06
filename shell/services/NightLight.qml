pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"

// ---------------------------------------------------------------------------
// NightLightManager — real display colour temperature, not a UI overlay.
//
// Drives `expressive-night`, which owns a gammastep/wlsunset process speaking
// wlr-gamma-control to niri. If no backend is installed, `available` stays
// false and the page says exactly what to install rather than pretending.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    property bool available: false
    property string backend: ""
    property bool running: false
    property string installHint: "sudo dnf install gammastep"

    readonly property bool enabled: Settings.val("nightLight.enabled", false)
    readonly property int temperature: Settings.val("nightLight.temperature", 4000)
    readonly property string schedule: Settings.val("nightLight.schedule", "manual")

    readonly property var schedules: [
        { value: "off",     label: "Off",              hint: "Never tint the display" },
        { value: "manual",  label: "Always on",        hint: "Hold the warm temperature all day" },
        { value: "sunset",  label: "Sunset to sunrise", hint: "Follow your location's daylight" },
        { value: "custom",  label: "Custom hours",     hint: "Turn on and off at set times" }
    ]

    // A warm-white approximation of a black body at `k` kelvin, used to render
    // the temperature slider and the preview tint.
    function kelvinToColor(k) {
        const t = Math.max(1000, Math.min(12000, k)) / 100
        let r, g, b
        if (t <= 66) {
            r = 255
            g = 99.4708025861 * Math.log(t) - 161.1195681661
        } else {
            r = 329.698727446 * Math.pow(t - 60, -0.1332047592)
            g = 288.1221695283 * Math.pow(t - 60, -0.0755148492)
        }
        if (t >= 66) b = 255
        else if (t <= 19) b = 0
        else b = 138.5177312231 * Math.log(t - 10) - 305.0447927307
        const c = v => Math.max(0, Math.min(255, v)) / 255
        return Qt.rgba(c(r), c(g), c(b), 1)
    }

    // The multiply-tint a given temperature imposes, relative to 6500 K white.
    function tintFor(k) {
        const c = kelvinToColor(k)
        const w = kelvinToColor(6500)
        return Qt.rgba(c.r / w.r, c.g / w.g, c.b / w.b, 1)
    }

    function label() {
        if (!enabled || schedule === "off") return "Off"
        if (schedule === "manual") return `${temperature} K`
        if (schedule === "sunset") return "Sunset to sunrise"
        return `${Settings.val("nightLight.start", "20:00")} – ${Settings.val("nightLight.end", "07:00")}`
    }

    function toggle() { Settings.set("nightLight.enabled", !enabled) }

    function apply() {
        if (!root.available) return
        applyProc.command = [Files.bin("expressive-night"), "apply",
                             JSON.stringify(Settings.val("nightLight", {}))]
        applyProc.running = true
    }

    function refresh() { statusProc.running = true }

    Component.onCompleted: refresh()

    Process {
        id: statusProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text)
                    root.available = !!s.available
                    root.backend = s.backend || ""
                    root.running = !!s.running
                    if (s.installHint) root.installHint = s.installHint
                } catch (e) { root.available = false }
            }
        }
        Component.onCompleted: command = [Files.bin("expressive-night"), "status"]
    }

    Process {
        id: applyProc
        onExited: statusTimer.restart()
    }
    Timer { id: statusTimer; interval: 300; onTriggered: root.refresh() }

    // Debounced so dragging the temperature slider doesn't respawn gammastep
    // on every pixel.
    Timer { id: applyTimer; interval: 250; onTriggered: root.apply() }

    Connections {
        target: Settings
        function onChanged(path, value) {
            if (path === "*" || String(path).startsWith("nightLight"))
                applyTimer.restart()
        }
    }
}
