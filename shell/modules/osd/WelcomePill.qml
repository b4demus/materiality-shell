import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/components"
import "root:/services"

// One-shot greeting: a pill that slides down from the top just below the bar a
// beat after the shell starts, then tucks away. Same shape and motion as the
// mic badge — kaomoji + "Welcome, <user>".
PanelWindow {
    id: root
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "expressive-welcome"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; left: true; right: true }
    implicitHeight: 130
    mask: Region {}          // click-through

    readonly property string user: {
        const u = Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""
        return u.length ? u.charAt(0).toUpperCase() + u.slice(1) : "there"
    }
    readonly property var faces: [
        "(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧", "( ˶ˆ ᗜ ˆ˵ )", "(๑˃ᴗ˂)ﻭ", "ヽ(´▽`)/", "(*ﾉ´∀`*)",
        "ᕕ( ᐛ )ᕗ", "( ᐛ )و", "(◕‿◕)♡", "＼(＾▽＾)／"
    ]
    readonly property string face: faces[Math.floor(Math.random() * faces.length)]

    property bool shown: false
    // let the bar settle first, then greet and linger a few seconds
    Timer { id: appear;  interval: 1500; running: true; onTriggered: root.shown = true }
    Timer { id: dismiss; interval: 5000; onTriggered: root.shown = false }
    onShownChanged: if (shown) dismiss.restart()

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
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

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.face
                color: Colors.primary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelLarge
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Welcome, " + root.user
                color: Colors.on.surface
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelLarge
                font.weight: Appearance.font.weightMedium
            }
        }
    }
}
