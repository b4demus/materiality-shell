import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

// ---------------------------------------------------------------------------
// The wallpaper surface, one per output.
//
// Two stacked images cross-fade so changing wallpaper (or a slideshow tick)
// dissolves rather than snapping. Each output resolves its own image, so a
// per-monitor assignment paints only the monitor it belongs to.
// ---------------------------------------------------------------------------
PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    readonly property string outputName: screen ? screen.name : ""

    readonly property url wanted: Wallpaper.sourceFor(outputName)
    readonly property int fillMode: Wallpaper.fillModeFor()

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "expressive-bg"
    exclusionMode: ExclusionMode.Ignore
    color: Colors.background

    anchors { top: true; bottom: true; left: true; right: true }

    // Which of the two layers is currently on top.
    property bool useA: true
    property url sourceA: ""
    property url sourceB: ""

    onWantedChanged: {
        if (wanted === (useA ? sourceA : sourceB)) return
        if (useA) sourceB = wanted
        else sourceA = wanted
        useA = !useA
    }

    Component.onCompleted: { sourceA = wanted; useA = true }

    Image {
        id: imgA
        anchors.fill: parent
        source: root.sourceA
        visible: opacity > 0.01
        opacity: root.useA && status === Image.Ready ? 1 : 0
        fillMode: root.fillMode
        cache: false
        asynchronous: true
        sourceSize.width: root.screen ? root.screen.width : 1920
        sourceSize.height: root.screen ? root.screen.height : 1080

        Behavior on opacity {
            NumberAnimation {
                duration: Settings.val("wallpaper.transitionMs", 420)
                easing.type: Motion.easeStandard
            }
        }
    }

    Image {
        id: imgB
        anchors.fill: parent
        source: root.sourceB
        visible: opacity > 0.01
        opacity: !root.useA && status === Image.Ready ? 1 : 0
        fillMode: root.fillMode
        cache: false
        asynchronous: true
        sourceSize.width: root.screen ? root.screen.width : 1920
        sourceSize.height: root.screen ? root.screen.height : 1080

        Behavior on opacity {
            NumberAnimation {
                duration: Settings.val("wallpaper.transitionMs", 420)
                easing.type: Motion.easeStandard
            }
        }
    }

    // Subtle scrim so the bar and overlays keep contrast over bright wallpapers.
    // It follows the bar to whichever edge the bar is on.
    Rectangle {
        anchors.fill: parent
        visible: Wallpaper.hasWallpaper
        gradient: Gradient {
            orientation: Appearance.barVertical ? Gradient.Horizontal : Gradient.Vertical
            GradientStop {
                position: 0.0
                color: (Appearance.barPosition === "top" || Appearance.barPosition === "left")
                       ? Qt.rgba(0, 0, 0, 0.28) : Qt.rgba(0, 0, 0, 0)
            }
            GradientStop { position: 0.22; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 0.78; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop {
                position: 1.0
                color: (Appearance.barPosition === "bottom" || Appearance.barPosition === "right")
                       ? Qt.rgba(0, 0, 0, 0.28) : Qt.rgba(0, 0, 0, 0)
            }
        }
    }
}
