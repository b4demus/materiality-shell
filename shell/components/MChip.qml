import QtQuick
import "root:/config"

// M3 chip — assist / filter / input. Selected chips fill with the secondary
// container and grow a leading check.
Item {
    id: root

    property string label: ""
    property string icon: ""
    property bool selected: false
    property bool enabledChip: true
    property bool showCheck: true
    property color accent: Colors.secondaryContainer
    property color onAccent: Colors.on.secondaryContainer
    property real hpad: Appearance.space.l

    signal clicked()

    implicitHeight: 34
    implicitWidth: row.implicitWidth + hpad * 2

    opacity: enabledChip ? 1 : 0.45
    scale: ma.pressed ? 0.96 : 1
    Behavior on scale {
        SpringAnimation {
            spring: Motion.spatialFast.spring; damping: Motion.spatialFast.damping
            mass: Motion.spatialFast.mass; epsilon: Motion.spatialFast.epsilon
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.s
        color: root.selected ? root.accent : "transparent"
        border.width: root.selected ? 0 : 1
        border.color: Colors.outlineVariant
        clip: true

        Behavior on color { ColorAnimation { duration: Motion.durShort } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.selected ? root.onAccent : Colors.on.surface
            opacity: !root.enabledChip ? 0
                     : ma.pressed ? Appearance.statePress
                     : ma.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Appearance.space.s

        MIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== "" || (root.selected && root.showCheck)
            name: (root.selected && root.showCheck && root.icon === "") ? "check" : root.icon
            size: 18
            fill: root.selected ? 1 : 0
            color: root.selected ? root.onAccent : Colors.on.surfaceVariant
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: root.selected ? root.onAccent : Colors.on.surfaceVariant
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.labelLarge
            font.weight: Appearance.font.weightMedium
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: root.enabledChip
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
