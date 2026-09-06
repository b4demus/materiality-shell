pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"

// ---------------------------------------------------------------------------
// ShortcutManager — niri keybinds, edited as data.
//
// Binds are read out of config.kdl by `expressive-niri` and written back one
// line at a time, so the surrounding comments and grouping in the user's config
// survive editing. niri reloads on write, so a new bind works immediately.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    // [{ line, key, action, title, props }]
    property var binds: []
    property bool loaded: false
    property bool busy: false

    // Human grouping for the list; matched against the raw action text.
    readonly property var groups: [
        { id: "apps",       label: "Applications", icon: "apps",
          match: ["spawn", "spawn-sh"] },
        { id: "window",     label: "Windows",      icon: "select_window",
          match: ["close-window", "fullscreen", "floating", "window", "column", "consume", "expel", "center", "width", "height", "maximize"] },
        { id: "workspace",  label: "Workspaces",   icon: "grid_view",
          match: ["workspace", "monitor", "overview"] },
        { id: "session",    label: "Session",      icon: "power_settings_new",
          match: ["quit", "screenshot", "hotkey", "power", "suspend", "lock"] }
    ]

    function groupOf(action) {
        const a = String(action || "")
        for (const g of groups)
            for (const m of g.match)
                if (a.indexOf(m) >= 0) return g.id
        return "window"
    }

    // "Mod+Shift+Slash" -> ["Super", "Shift", "/"] for chip rendering.
    function keyChips(key) {
        const pretty = {
            "Mod": "Super", "Super": "Super", "Ctrl": "Ctrl", "Control": "Ctrl",
            "Alt": "Alt", "Shift": "Shift",
            "Slash": "/", "Return": "Enter", "Space": "Space", "Comma": ",",
            "Period": ".", "Minus": "−", "Equal": "=", "Escape": "Esc",
            "Print": "PrtSc", "BracketLeft": "[", "BracketRight": "]",
            "Semicolon": ";", "Apostrophe": "'", "Grave": "`", "Backslash": "\\",
            "Tab": "Tab", "BackSpace": "Backspace", "Delete": "Del",
            "Page_Up": "PgUp", "Page_Down": "PgDn"
        }
        return String(key).split("+").map(p => {
            if (pretty[p]) return pretty[p]
            if (p.startsWith("XF86")) return p.substring(4).replace(/([a-z])([A-Z])/g, "$1 $2")
            if (p.startsWith("WheelScroll")) return p.replace("WheelScroll", "Wheel ")
            return p
        })
    }

    // A readable summary of what a bind does.
    function describe(b) {
        if (b.title) return b.title
        const a = String(b.action || "")
        const m = a.match(/^spawn-sh\s+"(.*)"$/)
        if (m) return m[1]
        if (a.startsWith("spawn ")) {
            const parts = a.match(/"([^"]*)"/g) || []
            return parts.map(p => p.replace(/"/g, "")).join(" ")
        }
        return a.replace(/-/g, " ").replace(/^./, c => c.toUpperCase())
    }

    function find(key) {
        for (const b of binds) if (String(b.key).toLowerCase() === String(key).toLowerCase()) return b
        return null
    }

    function conflicts(key, exceptKey) {
        const b = find(key)
        return b && String(b.key).toLowerCase() !== String(exceptKey || "").toLowerCase() ? b : null
    }

    function refresh() { listProc.running = true }

    function save(key, action, title, props) {
        if (busy || !key || !action) return
        busy = true
        setProc.command = [Files.bin("expressive-niri"), "bind-set",
                           JSON.stringify({ key: key, action: action,
                                            title: title || "", props: props || "" })]
        setProc.running = true
    }

    function rebind(oldKey, newKey, action, title, props) {
        if (oldKey && oldKey !== newKey) remove(oldKey, () => save(newKey, action, title, props))
        else save(newKey, action, title, props)
    }

    property var _afterDelete: null

    function remove(key, then) {
        if (busy) return
        busy = true
        root._afterDelete = then || null
        delProc.command = [Files.bin("expressive-niri"), "bind-del", key]
        delProc.running = true
    }

    Component.onCompleted: refresh()

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.binds = JSON.parse(text) } catch (e) { root.binds = [] }
                root.loaded = true
            }
        }
        Component.onCompleted: command = [Files.bin("expressive-niri"), "binds"]
    }

    Process {
        id: setProc
        onExited: { root.busy = false; root.refresh() }
    }
    Process {
        id: delProc
        onExited: {
            root.busy = false
            const then = root._afterDelete
            root._afterDelete = null
            root.refresh()
            if (then) then()
        }
    }
}
