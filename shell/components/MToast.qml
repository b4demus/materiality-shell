import QtQuick
import "root:/config"

// Transient confirmation ("Applied", "Copied"), anchored at the bottom of the
// settings window. Kept deliberately quiet — most changes are self-evident.
Rectangle {
    id: root

    property string text_: ""
    property string icon: "check_circle"
    property bool error: false
    property int duration: 2600

    function show(msg, isError, glyph) {
        root.text_ = msg
        root.error = isError === true
        root.icon = glyph || (isError ? "error" : "check_circle")
        shown = true
        hideTimer.restart()
    }

    property bool shown: false

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: shown ? Appearance.space.xl : -height
    z: 9800

    width: row.implicitWidth + Appearance.space.xl * 2
    height: 48
    radius: Appearance.radius.m
    color: root.error ? Colors.errorContainer : Colors.inverseSurface
    opacity: shown ? 1 : 0
    visible: opacity > 0.01

    Behavior on anchors.bottomMargin {
        SpringAnimation {
            spring: Motion.spatial.spring; damping: Motion.spatial.damping
            mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
        }
    }
    Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Appearance.space.m

        MIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 20
            color: root.error ? Colors.on.errorContainer : Colors.inverseOnSurface
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text_
            color: root.error ? Colors.on.errorContainer : Colors.inverseOnSurface
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.bodyMedium
        }
    }

    Timer {
        id: hideTimer
        interval: root.duration
        onTriggered: root.shown = false
    }
}
