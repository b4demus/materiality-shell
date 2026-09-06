pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Material You colour roles.
// Source of truth is ~/.local/state/expressive/colors.json (written by matugen via
// the `expressive-wall` script). Until that exists we fall back to a purple-forward
// M3 Expressive baseline so the shell always looks right on first run.
Singleton {
    id: root

    // Light/dark follows the settings store. "system" defers to the desktop-wide
    // GTK preference (org.gnome.desktop.interface color-scheme), which the
    // palette engine also writes — so GTK apps and the shell never disagree.
    property string systemPref: "dark"
    readonly property string mode: Settings.val("appearance.mode", "dark")
    readonly property bool dark: mode === "system" ? systemPref === "dark" : mode !== "light"

    function setMode(m) { Settings.set("appearance.mode", m) }
    function toggleMode() { setMode(dark ? "light" : "dark") }

    Process {
        id: sysPrefProc
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.systemPref = text.indexOf("prefer-light") >= 0 ? "light" : "dark"
            }
        }
    }
    Timer {
        interval: 4000
        repeat: true
        running: root.mode === "system"
        triggeredOnStart: true
        onTriggered: sysPrefProc.running = true
    }

    readonly property var fallback: ({
        "dark": {
            "background": "#141218", "onBackground": "#E6E0E9",
            "surface": "#141218", "surfaceDim": "#141218", "surfaceBright": "#3B383E",
            "surfaceContainerLowest": "#0F0D13", "surfaceContainerLow": "#1D1B20",
            "surfaceContainer": "#211F26", "surfaceContainerHigh": "#2B2930",
            "surfaceContainerHighest": "#36343B",
            "surfaceVariant": "#49454F", "onSurface": "#E6E0E9", "onSurfaceVariant": "#CAC4D0",
            "outline": "#948F99", "outlineVariant": "#49454F",
            "primary": "#D0BCFF", "onPrimary": "#381E72",
            "primaryContainer": "#4F378B", "onPrimaryContainer": "#EADDFF",
            "secondary": "#CCC2DC", "onSecondary": "#332D41",
            "secondaryContainer": "#4A4458", "onSecondaryContainer": "#E8DEF8",
            "tertiary": "#EFB8C8", "onTertiary": "#492532",
            "tertiaryContainer": "#633B48", "onTertiaryContainer": "#FFD8E4",
            "error": "#F2B8B5", "onError": "#601410",
            "errorContainer": "#8C1D18", "onErrorContainer": "#F9DEDC",
            "shadow": "#000000", "scrim": "#000000",
            "inverseSurface": "#E6E0E9", "inverseOnSurface": "#322F35", "inversePrimary": "#6750A4"
        },
        "light": {
            "background": "#FEF7FF", "onBackground": "#1D1B20",
            "surface": "#FEF7FF", "surfaceDim": "#DED8E1", "surfaceBright": "#FEF7FF",
            "surfaceContainerLowest": "#FFFFFF", "surfaceContainerLow": "#F7F2FA",
            "surfaceContainer": "#F3EDF7", "surfaceContainerHigh": "#ECE6F0",
            "surfaceContainerHighest": "#E6E0E9",
            "surfaceVariant": "#E7E0EC", "onSurface": "#1D1B20", "onSurfaceVariant": "#49454F",
            "outline": "#79747E", "outlineVariant": "#CAC4D0",
            "primary": "#6750A4", "onPrimary": "#FFFFFF",
            "primaryContainer": "#EADDFF", "onPrimaryContainer": "#21005D",
            "secondary": "#625B71", "onSecondary": "#FFFFFF",
            "secondaryContainer": "#E8DEF8", "onSecondaryContainer": "#1D192B",
            "tertiary": "#7D5260", "onTertiary": "#FFFFFF",
            "tertiaryContainer": "#FFD8E4", "onTertiaryContainer": "#31111D",
            "error": "#B3261E", "onError": "#FFFFFF",
            "errorContainer": "#F9DEDC", "onErrorContainer": "#410E0B",
            "shadow": "#000000", "scrim": "#000000",
            "inverseSurface": "#322F35", "inverseOnSurface": "#F5EFF7", "inversePrimary": "#D0BCFF"
        }
    })

    // Whole-map parsed from disk (or the fallback). Kept as a plain object.
    property var data: fallback

    // Active scheme map — guarded so the bindings below can NEVER throw on first
    // evaluation (a throwing colour binding silently sticks at #000000 forever).
    readonly property var scheme: {
        const src = (data && typeof data === "object") ? data : fallback
        const mode = dark ? "dark" : "light"
        const m = src && src[mode]
        return (m && typeof m === "object") ? m : fallback[mode]
    }
    readonly property var fb: dark ? fallback.dark : fallback.light

    function v(key) {
        const s = scheme
        return (s && s[key] !== undefined && s[key] !== null) ? s[key] : fb[key]
    }

    readonly property color background: v("background")
    readonly property color surface: v("surface")
    readonly property color surfaceDim: v("surfaceDim")
    readonly property color surfaceBright: v("surfaceBright")
    readonly property color surfaceContainerLowest: v("surfaceContainerLowest")
    readonly property color surfaceContainerLow: v("surfaceContainerLow")
    readonly property color surfaceContainer: v("surfaceContainer")
    readonly property color surfaceContainerHigh: v("surfaceContainerHigh")
    readonly property color surfaceContainerHighest: v("surfaceContainerHighest")
    readonly property color surfaceVariant: v("surfaceVariant")
    readonly property color outline: v("outline")
    readonly property color outlineVariant: v("outlineVariant")
    readonly property color primary: v("primary")
    readonly property color primaryContainer: v("primaryContainer")
    readonly property color secondary: v("secondary")
    readonly property color secondaryContainer: v("secondaryContainer")
    readonly property color tertiary: v("tertiary")
    readonly property color tertiaryContainer: v("tertiaryContainer")
    readonly property color error: v("error")
    readonly property color errorContainer: v("errorContainer")
    readonly property color shadow: v("shadow")
    readonly property color scrim: v("scrim")
    readonly property color inverseSurface: v("inverseSurface")
    readonly property color inverseOnSurface: v("inverseOnSurface")
    readonly property color inversePrimary: v("inversePrimary")

    // "on-*" roles. QML parses a property literally named `onXxx` as a signal
    // handler, so these live under a nested object: Colors.on.surface, etc.
    readonly property QtObject on: QtObject {
        readonly property color background: root.v("onBackground")
        readonly property color surface: root.v("onSurface")
        readonly property color surfaceVariant: root.v("onSurfaceVariant")
        readonly property color primary: root.v("onPrimary")
        readonly property color primaryContainer: root.v("onPrimaryContainer")
        readonly property color secondary: root.v("onSecondary")
        readonly property color secondaryContainer: root.v("onSecondaryContainer")
        readonly property color tertiary: root.v("onTertiary")
        readonly property color tertiaryContainer: root.v("onTertiaryContainer")
        readonly property color error: root.v("onError")
        readonly property color errorContainer: root.v("onErrorContainer")
    }

    // Bar chrome. Follows the active scheme's surface so the whole shell reads as
    // one palette (Gruvbox looks like Gruvbox on the bar too). Guarded via v() so
    // it can never throw on first evaluation.
    readonly property color barSurface: v("surface")
    readonly property color barOnSurface: v("onSurface")
    readonly property color barOnSurfaceVariant: v("onSurfaceVariant")

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    function ingest(txt) {
        try {
            const parsed = JSON.parse(txt)
            if (parsed && parsed.dark && parsed.light)
                root.data = parsed
        } catch (e) {
            root.data = root.fallback
        }
    }

    FileView {
        id: file
        path: `${Quickshell.env("HOME")}/.local/state/expressive/colors.json`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.ingest(file.text())
        onLoadFailed: root.data = root.fallback
    }
}
