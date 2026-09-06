pragma Singleton

import QtQuick
import Quickshell

// ---------------------------------------------------------------------------
// Material 3 Expressive is spring-first motion.
// These presets feed SpringAnimation {} / Behavior { SpringAnimation {} }.
//
// `enabled` and `scale` come from the settings store: turning animations off
// collapses every duration to 0 and stiffens the springs so the UI snaps.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    readonly property bool enabled: Settings.val("appearance.animations", true)
    // 0.5 (snappy) .. 2.0 (languid). Inverted for spring stiffness.
    readonly property real scale: enabled ? Settings.val("appearance.animationScale", 1.0) : 0.0
    // When animations are off we want springs to snap, but SpringAnimation's
    // integrator diverges (the property rockets to 1e40+) once `spring` climbs
    // past ~48 with these masses — the old `40` multiplier pushed every preset
    // to 100-220 and quietly blew up handles, popups and dialogs. `7` keeps the
    // stiffest preset (5.5) near 38: settles within a frame or two, never unstable.
    readonly property real springScale: root.scale <= 0 ? 7 : 1.0 / Math.max(0.25, root.scale)

    // Spatial: things that move / resize. Visible, playful overshoot.
    readonly property QtObject spatial: QtObject {
        readonly property real spring: 3.4 * root.springScale
        readonly property real damping: root.enabled ? 0.32 : 1.0
        readonly property real mass: 0.9
        readonly property real epsilon: 0.001
    }

    // Spatial (fast): small quick reactions, a touch of bounce.
    readonly property QtObject spatialFast: QtObject {
        readonly property real spring: 5.0 * root.springScale
        readonly property real damping: root.enabled ? 0.5 : 1.0
        readonly property real mass: 0.7
        readonly property real epsilon: 0.001
    }

    // Expressive: the big, characterful overshoot used for page/panel entries.
    readonly property QtObject expressive: QtObject {
        readonly property real spring: 2.6 * root.springScale
        readonly property real damping: root.enabled ? 0.26 : 1.0
        readonly property real mass: 1.0
        readonly property real epsilon: 0.001
    }

    // Effects: opacity / colour. Critically damped, no overshoot.
    readonly property QtObject effects: QtObject {
        readonly property real spring: 5.5 * root.springScale
        readonly property real damping: 1.0
        readonly property real mass: 1.0
        readonly property real epsilon: 0.002
    }

    // Non-spring fallbacks for properties SpringAnimation can't drive well.
    readonly property int durShort: Math.round(140 * scale)
    readonly property int durMedium: Math.round(240 * scale)
    readonly property int durLong: Math.round(400 * scale)
    readonly property int durXLong: Math.round(600 * scale)
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeEmphasized: Easing.OutBack
    readonly property int easeDecel: Easing.OutQuint
}
