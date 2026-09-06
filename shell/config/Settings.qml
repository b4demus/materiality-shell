pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// ---------------------------------------------------------------------------
// SettingsStore — the single source of truth for every shell-side preference.
//
// Backed by ~/.local/state/expressive/settings.json. The whole document lives
// in `d` as a plain JS object; reads go through val("a.b.c", fallback) and
// writes through set("a.b.c", v). Because both touch root.d, any QML binding
// that calls val() re-evaluates whenever anything is written — that is what
// makes the live desktop preview and the shell itself update instantly.
//
// Writes are debounced (120 ms) so dragging a slider doesn't hammer the disk.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateDir: `${home}/.local/state/expressive`
    readonly property string filePath: `${stateDir}/settings.json`

    property bool loaded: false
    // Suppresses the save-on-change loop while we are ingesting from disk.
    property bool _ingesting: false

    // ---- defaults --------------------------------------------------------
    readonly property var defaults: ({
        "appearance": {
            "mode": "dark",                 // dark | light | system
            "dynamicColors": true,
            "accent": "#D0BCFF",
            "density": 1,                   // 0 compact | 1 regular | 2 comfortable
            "radiusScale": 1.0,             // 0.4 .. 1.6
            "transparency": 0.0,            // 0 .. 0.6 of shell surfaces
            "blur": false,
            "shadows": true,
            "animations": true,
            "animationScale": 1.0,          // 0.5 .. 2.0
            "fontFamily": "Roboto",
            "fontScale": 1.0,               // 0.85 .. 1.3
            "cursorTheme": "Adwaita",
            "cursorSize": 24,
            "iconTheme": "Adwaita"
        },
        "wallpaper": {
            "mode": "same",                 // same | per-output
            "perOutput": {},                // { "Virtual-1": "/path.png" }
            "scaling": "fill",              // fill | fit | center | stretch | tile
            "transitionMs": 420,
            "favorites": [],
            "recent": [],
            "collections": {},              // { "Nature": ["/a.png", ...] }
            "slideshow": {
                "enabled": false,
                "intervalSec": 900,
                "random": true,
                "collection": ""            // "" = whole catalog
            }
        },
        "bar": {
            "position": "top",              // top | bottom | left | right
            "floating": true,
            "height": 32,
            "margin": 6,
            "padding": 14,
            "radius": 16,
            "transparency": 0.0,
            "blur": false,
            "shadow": true,
            "iconSize": 18,
            "fontSize": 13,
            "moduleSpacing": 14,
            "workspaceSpacing": 6,
            "modules": {
                "left":   ["workspaces", "windowTitle"],
                "center": ["media", "clipboard", "clock", "kaomoji"],
                "right":  ["tray", "statusIsland"]
            }
        },
        "niri": {
            "gapsInner": 8,
            "gapsOuter": 0,
            "borderWidth": 2,
            "borderEnabled": false,
            "focusRingWidth": 3,
            "focusRingEnabled": true,
            "cornerRadius": 14,
            "focusFollowsMouse": false,
            "focusFollowsMousePercent": 0,
            "centerFocusedColumn": "never", // never | always | on-overflow
            "defaultColumnWidth": 0.5,
            "presetColumnWidths": [0.33333, 0.5, 0.66667],
            "animationsEnabled": true,
            "animationSlowdown": 1.0
        },
        "windows": {
            "openMaximized": false,
            "defaultFloatWidth": 800,
            "defaultFloatHeight": 600,
            "clipToGeometry": true,
            "backdropBlur": false,
            "rules": []                     // [{ appId, title, floating, workspace, opacity }]
        },
        "workspaces": {
            "showLabels": false,
            "showIcons": true,
            "named": [],                    // [{ idx, name, icon, color, output }]
            "indicatorStyle": "pill"        // pill | dots | numbers
        },
        "displays": {
            "outputs": {}                   // { name: { mode, scale, transform, x, y, vrr, enabled } }
        },
        "nightLight": {
            "enabled": false,
            "temperature": 4000,            // 1700 .. 6500 K
            "dayTemperature": 6500,
            "schedule": "manual",           // off | manual | sunset | custom
            "start": "20:00",
            "end": "07:00",
            "latitude": 55.75,
            "longitude": 37.62,
            "gamma": 1.0
        },
        "notifications": {
            "enabled": true,
            "dnd": false,
            "position": "top-right",        // top-right | top-left | top-center | bottom-*
            "durationSec": 6,
            "sound": false,
            "grouping": true,
            "historyLimit": 100,
            "showOnLockscreen": false,
            "perApp": {}                    // { "firefox": false }
        },
        "power": {
            "profile": "balanced",          // power-saver | balanced | performance
            "screenTimeoutSec": 600,
            "lockTimeoutSec": 900,
            "suspendTimeoutSec": 1800,
            "lidClose": "suspend",          // suspend | lock | nothing
            "powerButton": "menu",          // menu | suspend | poweroff | nothing
            "lowBatteryPercent": 15,
            "lowBatteryAction": "notify",   // notify | powersave | suspend
            "dimBeforeSleep": true
        },
        "apps": {
            "browser": "",
            "terminal": "alacritty",
            "fileManager": "nautilus",
            "editor": "",
            "launcher": "expressive",
            "screenshot": "niri",
            "mediaPlayer": ""
        },
        "autostart": [],                    // [{ name, exec, enabled }]
        "quickSettings": {
            "tiles": ["wifi", "bluetooth", "nightlight", "dnd", "mute", "theme", "powerprofile", "vpn"],
            "showBrightness": true,
            "showVolume": true,
            "showMedia": true
        },
        "profiles": [],                     // [{ id, name, icon, patch: {path: value} }]
        "activeProfile": "",
        "automation": {
            "enabled": false,
            "rules": []                     // [{ id, enabled, when: {type, value}, profile }]
        },
        "input": {
            "keyboard": {
                "layouts": "us",
                "variants": "",
                "options": "",
                "switchKey": "alt_shift_toggle",
                "repeatDelay": 600,
                "repeatRate": 25,
                "numlockOnBoot": false
            },
            "mouse": {
                "speed": 0.0,               // -1 .. 1
                "accelProfile": "adaptive", // adaptive | flat
                "naturalScroll": false,
                "scrollFactor": 1.0,
                "middleEmulation": false
            },
            "touchpad": {
                "enabled": true,
                "speed": 0.0,
                "accelProfile": "adaptive",
                "naturalScroll": true,
                "tap": true,
                "dwt": true,                // disable while typing
                "scrollMethod": "two-finger",
                "clickMethod": "clickfinger",
                "scrollFactor": 1.0
            }
        },
        "privacy": {
            "camera": true,                 // false = /dev/video* made inaccessible to every app
            "microphone": true              // false = default PipeWire source muted (apps capture silence)
        }
    })

    // ---- live document ---------------------------------------------------
    property var d: deepMerge(clone(defaults), {})

    // ---- helpers ---------------------------------------------------------
    function clone(o) { return JSON.parse(JSON.stringify(o)) }

    function isPlain(o) {
        return o !== null && typeof o === "object" && !Array.isArray(o)
    }

    // Recursively overlay `src` onto `dst`; arrays are replaced wholesale so a
    // user-emptied list stays empty instead of resurrecting the defaults.
    function deepMerge(dst, src) {
        if (!isPlain(src)) return dst
        for (const k in src) {
            const sv = src[k]
            if (isPlain(sv) && isPlain(dst[k])) deepMerge(dst[k], sv)
            else dst[k] = isPlain(sv) || Array.isArray(sv) ? clone(sv) : sv
        }
        return dst
    }

    // Read a dotted path. Any binding that calls this depends on `d`.
    function val(path, fallback) {
        let cur = root.d
        for (const key of String(path).split(".")) {
            if (cur === null || cur === undefined || typeof cur !== "object") return fallback
            cur = cur[key]
        }
        return cur === undefined || cur === null ? fallback : cur
    }

    // Write a dotted path. Reassigns `d` so every dependent binding refreshes.
    function set(path, value) {
        const parts = String(path).split(".")
        const next = clone(root.d)
        let cur = next
        for (let i = 0; i < parts.length - 1; i++) {
            if (!isPlain(cur[parts[i]])) cur[parts[i]] = {}
            cur = cur[parts[i]]
        }
        const leaf = parts[parts.length - 1]
        if (JSON.stringify(cur[leaf]) === JSON.stringify(value)) return
        cur[leaf] = value
        root.d = next
        root.changed(path, value)
        if (!root._ingesting) saveTimer.restart()
    }

    // Apply many paths at once (profiles use this) with a single write.
    function patch(map) {
        const next = clone(root.d)
        let touched = []
        for (const path in map) {
            const parts = path.split(".")
            let cur = next
            for (let i = 0; i < parts.length - 1; i++) {
                if (!isPlain(cur[parts[i]])) cur[parts[i]] = {}
                cur = cur[parts[i]]
            }
            cur[parts[parts.length - 1]] = map[path]
            touched.push(path)
        }
        root.d = next
        for (const p of touched) root.changed(p, val(p, null))
        if (!root._ingesting) saveTimer.restart()
    }

    function reset(section) {
        if (!section) {
            root.d = clone(defaults)
        } else {
            const next = clone(root.d)
            next[section] = clone(defaults[section])
            root.d = next
        }
        root.changed(section || "*", null)
        saveTimer.restart()
    }

    function toggle(path) { set(path, !val(path, false)) }

    // Emitted after every write. Managers listen to this to push changes out to
    // niri / gammastep / NetworkManager instead of polling the store.
    signal changed(string path, var value)

    // ---- persistence -----------------------------------------------------
    function save() { saveTimer.stop(); file.setText(JSON.stringify(root.d, null, 2) + "\n") }

    function exportTo(path) {
        exportProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && cp -f "$2" "$1"',
                              "sh", path, root.filePath]
        exportProc.running = true
    }
    function importFrom(path) {
        importProc.command = ["cat", path]
        importProc.running = true
    }

    Timer {
        id: saveTimer
        interval: 120
        onTriggered: root.save()
    }

    Process { id: exportProc }
    Process {
        id: importProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text)
                    if (root.isPlain(parsed)) {
                        root.d = root.deepMerge(root.clone(root.defaults), parsed)
                        root.save()
                        root.changed("*", null)
                    }
                } catch (e) { console.warn("settings import failed:", e) }
            }
        }
    }

    FileView {
        id: file
        path: root.filePath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root._ingesting = true
            try {
                const parsed = JSON.parse(file.text())
                if (root.isPlain(parsed))
                    root.d = root.deepMerge(root.clone(root.defaults), parsed)
            } catch (e) {
                root.d = root.clone(root.defaults)
            }
            root._ingesting = false
            root.loaded = true
            root.changed("*", null)
        }
        onLoadFailed: {
            root.d = root.clone(root.defaults)
            root.loaded = true
            root.save()          // materialise the file on first run
        }
    }
}
