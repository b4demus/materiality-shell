import QtQuick
import "root:/config"

// A selectable colour dot for accent / workspace colour pickers.
Item {
    id: root

    property color swatch: "#6750a4"
    property bool selected: false
    property real size_: 40

    signal clicked()

    implicitWidth: size_
    implicitHeight: size_

    scale: ma.pressed ? 0.9 : 1
    Behavior on scale {
        SpringAnimation {
            spring: Motion.spatialFast.spring; damping: Motion.spatialFast.damping
            mass: Motion.spatialFast.mass; epsilon: Motion.spatialFast.epsilon
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: root.selected ? 2 : 0
        border.color: Colors.primary
        Behavior on border.width { NumberAnimation { duration: Motion.durShort } }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - (root.selected ? 10 : 4)
        height: width
        radius: width / 2
        color: root.swatch
        Behavior on width { NumberAnimation { duration: Motion.durShort; easing.type: Motion.easeStandard } }

        MIcon {
            anchors.centerIn: parent
            visible: root.selected
            name: "check"
            size: 16
            weight: 700
            // Pick the legible ink for this swatch rather than assuming white.
            color: (0.299 * root.swatch.r + 0.587 * root.swatch.g + 0.114 * root.swatch.b) > 0.6
                   ? "#000000" : "#FFFFFF"
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
