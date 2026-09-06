pragma Singleton

import QtQuick
import Quickshell

// ---------------------------------------------------------------------------
// Material 3 Expressive design tokens.
//
// Every value here is derived from the central SettingsStore, so density,
// corner radius, font family and font scale propagate to the whole shell (bar,
// popups, settings app, live preview) the instant they are written.
// Nothing in the UI should hardcode a spacing, radius or type size.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    // ---- user-driven scales ------------------------------------------------
    // density: 0 compact · 1 regular · 2 comfortable
    readonly property int density: Settings.val("appearance.density", 1)
    readonly property real densityScale: density === 0 ? 0.78 : density === 2 ? 1.22 : 1.0
    readonly property real radiusScale: Settings.val("appearance.radiusScale", 1.0)
    readonly property real fontScale: Settings.val("appearance.fontScale", 1.0)

    // ---- Type ----------------------------------------------------------------
    readonly property string fontFamily: Settings.val("appearance.fontFamily", "Roboto")
    readonly property string monoFamily: "Roboto Mono"
    readonly property string iconFamily: "Material Symbols Rounded"
    // Dedicated face for the bar clock / countdowns / calendar numerals.
    readonly property string clockFamily: "JetBrains Mono"

    function fs(px) { return Math.round(px * root.fontScale) }

    // M3 type roles we actually use (px / weight)
    readonly property QtObject font: QtObject {
        readonly property int labelSmall: root.fs(11)
        readonly property int labelMedium: root.fs(12)
        readonly property int labelLarge: root.fs(14)
        readonly property int bodySmall: root.fs(12)
        readonly property int bodyMedium: root.fs(14)
        readonly property int bodyLarge: root.fs(16)
        readonly property int titleSmall: root.fs(14)
        readonly property int titleMedium: root.fs(16)
        readonly property int titleLarge: root.fs(20)
        readonly property int headlineSmall: root.fs(24)
        readonly property int headlineMedium: root.fs(28)
        readonly property int headlineLarge: root.fs(32)
        readonly property int displaySmall: root.fs(34)
        readonly property int displayMedium: root.fs(44)

        readonly property int weightRegular: 400
        readonly property int weightMedium: 500
        readonly property int weightBold: 700
    }

    // ---- Shape (corner radius) --------------------------------------------
    function rs(px) { return Math.round(px * root.radiusScale) }

    readonly property QtObject radius: QtObject {
        readonly property int none: 0
        readonly property int xs: root.rs(8)
        readonly property int s: root.rs(12)
        readonly property int m: root.rs(16)
        readonly property int l: root.rs(20)
        readonly property int xl: root.rs(28)
        readonly property int xxl: root.rs(36)
        readonly property int full: 999
    }

    // ---- Spacing scale (4dp grid, density-scaled) -------------------------
    function sp(px) { return Math.round(px * root.densityScale) }

    readonly property QtObject space: QtObject {
        readonly property int xs: root.sp(4)
        readonly property int s: root.sp(8)
        readonly property int m: root.sp(12)
        readonly property int l: root.sp(16)
        readonly property int xl: root.sp(24)
        readonly property int xxl: root.sp(32)
        readonly property int xxxl: root.sp(48)
    }

    // ---- Bar geometry (live from settings) ---------------------------------
    readonly property string barPosition: Settings.val("bar.position", "top")
    readonly property bool barVertical: barPosition === "left" || barPosition === "right"
    readonly property bool barFloating: Settings.val("bar.floating", true)
    readonly property int barHeight: Settings.val("bar.height", 32)
    readonly property int barMargin: barFloating ? Settings.val("bar.margin", 6) : 0
    readonly property int barRadius: barFloating ? Settings.val("bar.radius", 16)
                                                 : Math.min(Settings.val("bar.radius", 16), 0)
    readonly property int barGap: Settings.val("bar.moduleSpacing", 14)
    readonly property int barPad: Settings.val("bar.padding", 14)
    readonly property int barIconSize: Settings.val("bar.iconSize", 18)
    readonly property int barFontSize: Settings.val("bar.fontSize", 13)
    readonly property int barWorkspaceGap: Settings.val("bar.workspaceSpacing", 6)
    readonly property real barTransparency: Settings.val("bar.transparency", 0.0)

    // How much room the bar occupies, and the resulting inset on each screen
    // edge. Popups that hang off the bar use these instead of assuming it is
    // along the top.
    readonly property int barSpace: barHeight + barMargin * 2
    readonly property int barInsetTop: barPosition === "top" ? barSpace + space.s : space.l
    readonly property int barInsetBottom: barPosition === "bottom" ? barSpace + space.s : space.l
    readonly property int barInsetLeft: barPosition === "left" ? barSpace + space.s : space.l
    readonly property int barInsetRight: barPosition === "right" ? barSpace + space.s : space.l

    // ---- Surface effects ---------------------------------------------------
    readonly property real surfaceOpacity: 1.0 - Settings.val("appearance.transparency", 0.0)
    readonly property bool blurEnabled: Settings.val("appearance.blur", false)
    readonly property bool shadowsEnabled: Settings.val("appearance.shadows", true)

    // ---- Elevation ----------------------------------------------------------
    readonly property color shadowColor: Qt.rgba(0, 0, 0, shadowsEnabled ? 0.35 : 0)
    readonly property int shadowBlur: 24
    readonly property int shadowY: 4

    // ---- State layer opacities (M3) ---------------------------------------
    readonly property real stateHover: 0.08
    readonly property real statePress: 0.12
    readonly property real stateDrag: 0.16

    // ---- Icon variable-font axis defaults --------------------------------
    readonly property int iconWeight: 400
    readonly property int iconGrade: 0
    readonly property int iconOpticalSize: 24
}
