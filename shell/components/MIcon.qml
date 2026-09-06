import QtQuick
import "root:/config"

// A single Material Symbols Rounded glyph, addressed by ligature name
// (e.g. "wifi", "volume_up", "bluetooth_connected").
Text {
    id: root

    property string name: ""
    property real size: 20
    property real fill: 0            // 0..1
    property int weight: Appearance.iconWeight
    property int grade: Appearance.iconGrade
    // Optical size must track the rendered pixel size or the strokes read too
    // heavy / too thin. Clamp to the font's opsz axis range (20..48).
    property int opticalSize: Math.max(20, Math.min(48, Math.round(size)))

    text: name
    color: Colors.on.surface
    font.family: Appearance.iconFamily
    font.pixelSize: Math.round(size)
    font.variableAxes: ({
        "FILL": fill,
        "wght": weight,
        "GRAD": grade,
        "opsz": opticalSize
    })
    // Ensure ligature substitution is on so names render as icons.
    font.features: ({ "liga": 1, "calt": 1, "dlig": 1 })
    // Native rasterisation (re-rendered per size) is far crisper for small icon
    // glyphs than the default distance-field path, which softens/artefacts them.
    renderType: Text.NativeRendering
    font.hintingPreference: Font.PreferNoHinting
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    Behavior on color {
        ColorAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard }
    }
    Behavior on fill {
        NumberAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard }
    }
}
