import QtQuick
import "root:/config"
import "root:/components"
import "root:/services"

// The shape every small bar module shares: an icon, an optional label, a hover
// highlight and the usual click/scroll plumbing. Sizing follows the bar's own
// icon and font settings so the metrics sliders reach every module.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property color fg: Colors.barOnSurface
    property real iconFill: 0
    property bool active: false
    property bool vertical: Appearance.barVertical

    signal clicked()
    signal rightClicked()
    signal wheel(int delta)

    implicitWidth: vertical ? Math.max(24, Appearance.barIconSize + Appearance.space.s)
                            : content.implicitWidth + Appearance.space.m
    implicitHeight: vertical ? content.implicitHeight + Appearance.space.s
                             : Math.max(20, Appearance.barIconSize + Appearance.space.xs)

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.full
        color: root.active ? Colors.primary : Colors.barOnSurface
        opacity: root.active ? 0.16
                 : ma.pressed ? Appearance.statePress
                 : ma.containsMouse ? Appearance.stateHover : 0
        Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: Appearance.space.xs

        MIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            name: root.icon
            size: Appearance.barIconSize
            fill: root.iconFill
            color: root.fg
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== "" && !root.vertical
            text: root.label
            color: root.fg
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.barFontSize
            font.weight: Appearance.font.weightMedium
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: w => root.wheel(w.angleDelta.y)
    }
}
