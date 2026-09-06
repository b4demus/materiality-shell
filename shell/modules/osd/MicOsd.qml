import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/components"
import "root:/services"

// Tiny transient badge, top-centre, that slides in whenever the microphone is
// muted or unmuted (bar chip, Super+Shift+M, the mic-mute key, the Privacy page
// — anything that flips the PipeWire source).
PanelWindow {
    id: root
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "expressive-mic-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; left: true; right: true }
    implicitHeight: 130
    mask: Region {}          // click-through

    property bool micOn: Audio.micReady && !Audio.micMuted
    property bool shown: false
    property bool armed: false

    Timer { id: arm; interval: 1200; running: true; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1500; onTriggered: root.shown = false }

    onMicOnChanged: {
        if (!armed) return
        shown = true
        hide.restart()
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // clear the floating top bar
        anchors.topMargin: root.shown ? (Appearance.barHeight + Appearance.space.l)
                                      : -height - 12
        height: 40
        width: row.implicitWidth + Appearance.space.l * 2
        radius: height / 2
        color: Colors.surfaceContainerHigh
        opacity: root.shown ? 1 : 0

        Behavior on anchors.topMargin {
            SpringAnimation {
                spring: Motion.spatial.spring; damping: Motion.spatial.damping
                mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
            }
        }
        Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Appearance.space.s

            MIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 20
                fill: 1
                name: root.micOn ? "mic" : "mic_off"
                color: root.micOn ? Colors.primary : Colors.error
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.micOn ? "Mic on" : "Mic off"
                color: Colors.on.surface
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelLarge
                font.weight: Appearance.font.weightMedium
            }
        }
    }
}
