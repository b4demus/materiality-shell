pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"

// ---------------------------------------------------------------------------
// DisplayManager — connected outputs, their modes, and layout.
//
// Two-step application, which is what makes the Displays page safe to play with:
//   1. `niri msg output …` applies the change *temporarily* and instantly.
//   2. once the user keeps it, the same values are written to config.kdl
//      through NiriConf.pushOutputs() so they survive a restart.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    // [{ name, make, model, modes, currentMode, logical{x,y,width,height,scale,transform},
    //    vrrSupported, vrrEnabled }]
    property var outputs: []
    property bool loaded: false
    property string selected: ""

    readonly property var transforms: [
        { value: "normal",      label: "Landscape" },
        { value: "90",          label: "Portrait right" },
        { value: "180",         label: "Landscape (flipped)" },
        { value: "270",         label: "Portrait left" },
        { value: "flipped",     label: "Mirrored" },
        { value: "flipped-90",  label: "Mirrored portrait right" },
        { value: "flipped-180", label: "Mirrored (flipped)" },
        { value: "flipped-270", label: "Mirrored portrait left" }
    ]

    function find(name) {
        for (const o of outputs) if (o.name === name) return o
        return null
    }

    function modeString(m) {
        return `${m.width}x${m.height}@${(m.refresh_rate / 1000).toFixed(3)}`
    }

    function modeLabel(m) {
        return `${m.width} × ${m.height}  ·  ${(m.refresh_rate / 1000).toFixed(2)} Hz`
            + (m.is_preferred ? "  (preferred)" : "")
    }

    // Distinct resolutions, highest refresh first — a raw niri mode list is
    // dozens of near-duplicates and unusable as a menu.
    function resolutions(o) {
        if (!o || !o.modes) return []
        const seen = {}
        for (const m of o.modes) {
            const k = `${m.width}x${m.height}`
            if (!seen[k] || m.refresh_rate > seen[k].refresh_rate) seen[k] = m
        }
        return Object.keys(seen)
            .map(k => seen[k])
            .sort((a, b) => (b.width * b.height) - (a.width * a.height))
    }

    function refreshRatesFor(o, width, height) {
        if (!o || !o.modes) return []
        return o.modes
            .filter(m => m.width === width && m.height === height)
            .sort((a, b) => b.refresh_rate - a.refresh_rate)
    }

    function refresh() { listProc.running = true }

    // ---- live (temporary) application ------------------------------------
    function applyMode(name, modeStr) { _out(name, ["mode", modeStr]) }
    function applyScale(name, scale)  { _out(name, ["scale", String(scale)]) }
    function applyTransform(name, t)  { _out(name, ["transform", t]) }
    function applyPosition(name, x, y) { _out(name, ["position", "x", String(Math.round(x)), "y", String(Math.round(y))]) }
    function applyEnabled(name, on)   { _out(name, [on ? "on" : "off"]) }
    function applyVrr(name, on)       { _out(name, ["vrr", on ? "on" : "off"]) }

    function _out(name, args) {
        outProc.command = ["niri", "msg", "output", name].concat(args)
        outProc.running = true
    }

    // ---- persistence ------------------------------------------------------
    // Snapshot every output's current state into the settings store, then let
    // NiriConf render it into the managed `output` blocks in config.kdl.
    function persist() {
        const map = {}
        for (const o of root.outputs) {
            const m = o.modes && o.modes[o.currentMode]
            map[o.name] = {
                enabled: true,
                mode: m ? root.modeString(m) : null,
                scale: o.logical ? o.logical.scale : 1,
                transform: o.logical ? String(o.logical.transform).toLowerCase() : "normal",
                x: o.logical ? o.logical.x : 0,
                y: o.logical ? o.logical.y : 0,
                vrr: o.vrrEnabled
            }
        }
        Settings.set("displays.outputs", map)
        NiriConf.pushOutputs(map)
    }

    Component.onCompleted: refresh()

    Process {
        id: outProc
        onExited: reprobe.restart()
    }

    // niri needs a beat to settle a mode switch before it reports the new state.
    Timer { id: reprobe; interval: 400; onTriggered: root.refresh() }

    Process {
        id: listProc
        command: ["niri", "msg", "--json", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed
                try { parsed = JSON.parse(text) } catch (e) { return }
                const list = []
                for (const key in parsed) {
                    const o = parsed[key]
                    list.push({
                        name: o.name,
                        make: o.make || "",
                        model: o.model || "",
                        serial: o.serial || "",
                        modes: o.modes || [],
                        currentMode: o.current_mode === null || o.current_mode === undefined
                                     ? -1 : o.current_mode,
                        logical: o.logical || { x: 0, y: 0, width: 1920, height: 1080,
                                                scale: 1, transform: "Normal" },
                        vrrSupported: !!o.vrr_supported,
                        vrrEnabled: !!o.vrr_enabled,
                        physical: o.physical_size
                    })
                }
                list.sort((a, b) => (a.logical.x - b.logical.x) || a.name.localeCompare(b.name))
                root.outputs = list
                root.loaded = true
                if (!root.selected && list.length > 0) root.selected = list[0].name
            }
        }
    }

    // Outputs come and go (hotplug); niri reports it on the event stream.
    Connections {
        target: Niri
        function onWorkspacesChanged() { reprobe.restart() }
    }
}
