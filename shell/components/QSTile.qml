import QtQuick
import "root:/config"

// Material 3 Expressive quick-settings tile: big rounded target, fills with
// primary when active, springy press.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string sub: ""
    property bool active: false
    property bool enabledTile: true

    signal clicked()
    signal longClicked()

    implicitHeight: 64

    scale: ma.pressed ? 0.96 : 1
    Behavior on scale {
        SpringAnimation {
            spring: Motion.spatialFast.spring; damping: Motion.spatialFast.damping
            mass: Motion.spatialFast.mass; epsilon: Motion.spatialFast.epsilon
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.l
        color: root.active ? Colors.primary : Colors.surfaceContainerHighest
        opacity: root.enabledTile ? 1 : 0.4
        Behavior on color { ColorAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Appearance.space.l
            anchors.rightMargin: Appearance.space.l
            spacing: Appearance.space.m

            MIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.icon
                size: 22
                fill: root.active ? 1 : 0
                color: root.active ? Colors.on.primary : Colors.on.surfaceVariant
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 22 - Appearance.space.m
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.label
                    color: root.active ? Colors.on.primary : Colors.on.surface
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.labelLarge
                    font.weight: Appearance.font.weightMedium
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    visible: root.sub !== ""
                    text: root.sub
                    color: root.active ? Colors.alpha(Colors.on.primary, 0.8) : Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.labelSmall
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.active ? Colors.on.primary : Colors.on.surface
            opacity: ma.pressed ? Appearance.statePress : ma.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: root.enabledTile
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onPressAndHold: root.longClicked()
    }
}
