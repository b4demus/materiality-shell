import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/components"
import "root:/services"

// Transient volume / brightness OSD, bottom-centre, spring slide-in.
PanelWindow {
    id: root
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "expressive-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 140
    mask: Region {}          // click-through

    property string mode: "volume"     // "volume" | "brightness"
    property real level: 0
    property bool muted: false
    property bool shown: false
    property bool armed: false

    Timer { id: arm; interval: 900; running: true; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1600; onTriggered: root.shown = false }

    function pop(m) {
        if (!armed) return
        mode = m
        shown = true
        hide.restart()
    }

    Connections {
        target: Audio
        function onVolumeChanged() { root.level = Audio.volume; root.muted = Audio.muted; root.pop("volume") }
        function onMutedChanged()  { root.level = Audio.volume; root.muted = Audio.muted; root.pop("volume") }
    }
    Connections {
        target: Brightness
        enabled: Brightness.available
        function onValueChanged() { root.level = Brightness.value; root.pop("brightness") }
    }
    Connections {
        target: Bus
        function onOsdTest() { root.armed = true; root.level = Audio.volume; root.pop("volume") }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.shown ? Appearance.space.xl : -height - 20
            width: 340
            height: 64
            radius: Appearance.radius.xl
            color: Colors.surfaceContainerHigh
            opacity: root.shown ? 1 : 0

            Behavior on anchors.bottomMargin {
                SpringAnimation {
                    spring: Motion.spatial.spring; damping: Motion.spatial.damping
                    mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
                }
            }
            Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

            Row {
                anchors.fill: parent
                anchors.margins: Appearance.space.l
                spacing: Appearance.space.l

                MIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 24
                    fill: 1
                    color: Colors.on.surface
                    name: {
                        if (root.mode === "brightness")
                            return root.level > 0.66 ? "brightness_high"
                                 : root.level > 0.33 ? "brightness_medium" : "brightness_low"
                        if (root.muted || root.level <= 0) return "volume_off"
                        return root.level < 0.5 ? "volume_down" : "volume_up"
                    }
                }

                MSlider {
                    id: bar
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24 - 44 - Appearance.space.l * 2
                    interactive: false
                    value: root.muted && root.mode === "volume" ? 0 : root.level
                    activeColor: root.mode === "brightness" ? Colors.tertiary : Colors.primary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    text: Math.round((root.muted && root.mode === "volume" ? 0 : root.level) * 100) + "%"
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.monoFamily
                    font.pixelSize: Appearance.font.labelLarge
                }
            }
        }
    }
}
