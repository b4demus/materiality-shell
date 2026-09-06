pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"

// ---------------------------------------------------------------------------
// ProfileManager — named bundles of settings, plus the rules that pick one.
//
// A profile is a flat patch: { "settings path": value }. Applying one is a
// single Settings.patch(), which means every manager that listens for changes
// (niri, night light, bar, idle) reacts exactly as if the user had flipped each
// switch by hand. Profiles can also spawn commands on activation.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    readonly property var list: Settings.val("profiles", [])
    readonly property string activeId: Settings.val("activeProfile", "")
    readonly property bool automationOn: Settings.val("automation.enabled", false)
    readonly property var rules: Settings.val("automation.rules", [])

    // The settings a profile is allowed to carry, grouped for the editor UI.
    readonly property var fields: [
        { path: "appearance.mode",           label: "Theme",              kind: "choice",
          choices: ["dark", "light", "system"] },
        { path: "bar.floating",              label: "Floating bar",       kind: "bool" },
        { path: "bar.height",                label: "Bar height",         kind: "int", min: 20, max: 64 },
        { path: "bar.position",              label: "Bar position",       kind: "choice",
          choices: ["top", "bottom", "left", "right"] },
        { path: "notifications.dnd",         label: "Do not disturb",     kind: "bool" },
        { path: "appearance.animations",     label: "Animations",         kind: "bool" },
        { path: "appearance.blur",           label: "Blur",               kind: "bool" },
        { path: "niri.gapsInner",            label: "Window gaps",        kind: "int", min: 0, max: 48 },
        { path: "niri.animationsEnabled",    label: "niri animations",    kind: "bool" },
        { path: "nightLight.enabled",        label: "Night light",        kind: "bool" },
        { path: "power.profile",             label: "Power profile",      kind: "choice",
          choices: ["power-saver", "balanced", "performance"] },
        { path: "power.screenTimeoutSec",    label: "Blank screen after", kind: "int", min: 0, max: 3600 },
        { path: "wallpaper.slideshow.enabled", label: "Wallpaper slideshow", kind: "bool" }
    ]

    readonly property var conditionTypes: [
        { value: "app",      label: "An app is running",       icon: "apps",
          hint: "Matched against the app id of any open window" },
        { value: "output",   label: "A display is connected",  icon: "desktop_windows",
          hint: "Matched against the output name, e.g. HDMI-A-1" },
        { value: "power",    label: "Running on battery",      icon: "battery_5_bar",
          hint: "Triggers when the AC adapter is unplugged" },
        { value: "battery",  label: "Battery below",           icon: "battery_alert",
          hint: "Percentage threshold" },
        { value: "time",     label: "Between times",           icon: "schedule",
          hint: "Start and end as HH:MM–HH:MM" },
        { value: "bluetooth", label: "A Bluetooth device is connected", icon: "bluetooth_connected",
          hint: "Matched against the device name" }
    ]

    readonly property var icons: [
        "sports_esports", "work", "co_present", "laptop_mac", "filter_drama",
        "bedtime", "flight", "school", "movie", "terminal"
    ]

    function fieldFor(path) {
        for (const f of fields) if (f.path === path) return f
        return null
    }

    function byId(id) {
        for (const p of list) if (p.id === id) return p
        return null
    }

    function newId() { return "p" + Date.now().toString(36) }

    function create(name, icon) {
        const next = list.slice()
        const p = { id: newId(), name: name || "New profile", icon: icon || "tune",
                    patch: {}, commands: [] }
        next.push(p)
        Settings.set("profiles", next)
        return p.id
    }

    function update(id, changes) {
        const next = list.slice()
        for (let i = 0; i < next.length; i++)
            if (next[i].id === id) next[i] = Object.assign({}, next[i], changes)
        Settings.set("profiles", next)
    }

    function remove(id) {
        Settings.set("profiles", list.filter(p => p.id !== id))
        if (activeId === id) Settings.set("activeProfile", "")
    }

    // Fold the profile's patch into the store, then run its commands.
    function apply(id) {
        const p = byId(id)
        if (!p) return
        if (p.patch && Object.keys(p.patch).length > 0) Settings.patch(p.patch)
        Settings.set("activeProfile", id)
        for (const c of (p.commands || [])) {
            if (!c) continue
            cmdProc.command = ["sh", "-c", c]
            cmdProc.running = true
        }
        root.applied(id)
    }

    function clearActive() { Settings.set("activeProfile", "") }

    // Capture the live values of a profile's fields — "save the desktop as it
    // looks right now", which is how people actually build profiles.
    function captureCurrent(id) {
        const patch = {}
        for (const f of fields) patch[f.path] = Settings.val(f.path, null)
        update(id, { patch: patch })
    }

    signal applied(string id)

    Process { id: cmdProc }

    // ---- automation ------------------------------------------------------
    function ruleMatches(rule) {
        if (!rule || !rule.enabled) return false
        const w = rule.when || {}
        switch (w.type) {
        case "app": {
            const needle = String(w.value || "").toLowerCase()
            if (!needle) return false
            for (const id in Niri._windows) {
                const win = Niri._windows[id]
                if (win && String(win.app_id || "").toLowerCase().indexOf(needle) >= 0)
                    return true
            }
            return false
        }
        case "output": {
            const needle = String(w.value || "").toLowerCase()
            for (const o of Displays.outputs)
                if (String(o.name).toLowerCase().indexOf(needle) >= 0) return true
            return false
        }
        case "power":
            return Power.onBattery
        case "battery":
            return Power.hasBattery && Power.percent <= (parseFloat(w.value) || 20)
        case "bluetooth": {
            const needle = String(w.value || "").toLowerCase()
            for (const d of Bt.connectedDevices)
                if (String(d.name).toLowerCase().indexOf(needle) >= 0) return true
            return false
        }
        case "time": {
            const parts = String(w.value || "").split("-")
            if (parts.length !== 2) return false
            const now = new Date()
            const mins = now.getHours() * 60 + now.getMinutes()
            const toMin = s => {
                const hm = String(s).trim().split(":")
                return (parseInt(hm[0]) || 0) * 60 + (parseInt(hm[1]) || 0)
            }
            const a = toMin(parts[0]), b = toMin(parts[1])
            return a <= b ? (mins >= a && mins < b) : (mins >= a || mins < b)
        }
        }
        return false
    }

    function evaluate() {
        if (!automationOn) return
        for (const r of rules) {
            if (!ruleMatches(r)) continue
            if (r.profile && r.profile !== activeId) apply(r.profile)
            return
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.automationOn
        triggeredOnStart: true
        onTriggered: root.evaluate()
    }
}
