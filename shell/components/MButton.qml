import QtQuick
import "root:/config"

// Icon (+ optional label) button with an M3 state layer and a springy press.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property real iconSize: 20
    property real iconFill: 0
    property color fg: Colors.on.surfaceVariant
    property color bg: "transparent"
    property real radius_: Appearance.radius.full
    property real hpad: label ? Appearance.space.m : Appearance.space.s
    // Vertical breathing room around the glyph. Lower it on the slim bar so a
    // larger icon still fits inside the 32 px bar height.
    property real vpad: Appearance.space.s
    property real minSize: 32
    property bool active: false

    signal clicked()
    signal rightClicked()
    signal wheel(int delta)

    implicitWidth: bgRect.implicitWidth
    implicitHeight: Math.max(minSize, iconSize + vpad * 2)

    scale: press.pressed ? 0.92 : 1.0
    Behavior on scale {
        SpringAnimation {
            spring: Motion.spatialFast.spring; damping: Motion.spatialFast.damping
            mass: Motion.spatialFast.mass; epsilon: Motion.spatialFast.epsilon
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: root.radius_
        color: root.active ? Colors.secondaryContainer : root.bg
        implicitWidth: rowLay.implicitWidth + root.hpad * 2
        clip: true

        Behavior on color {
            ColorAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard }
        }

        Row {
            id: rowLay
            anchors.centerIn: parent
            spacing: Appearance.space.s

            MIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.icon !== ""
                name: root.icon
                size: root.iconSize
                fill: root.active ? 1 : root.iconFill
                color: root.active ? Colors.on.secondaryContainer : root.fg
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.label !== ""
                text: root.label
                color: root.active ? Colors.on.secondaryContainer : root.fg
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelLarge
                font.weight: Appearance.font.weightMedium
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.active ? Colors.on.secondaryContainer : root.fg
            opacity: press.pressed ? Appearance.statePress
                     : press.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        }
    }

    MouseArea {
        id: press
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: wheelEvent => root.wheel(wheelEvent.angleDelta.y)
    }
}
