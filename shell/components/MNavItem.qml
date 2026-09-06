import QtQuick
import "root:/config"

// One destination in the settings navigation. In `rail` mode it collapses to
// an icon with the M3 pill indicator; expanded it shows the label too.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool selected: false
    property bool expanded: true
    property string badge: ""

    signal clicked()

    implicitHeight: 44
    implicitWidth: expanded ? 220 : 56

    Rectangle {
        id: pill
        anchors.fill: parent
        anchors.rightMargin: root.expanded ? Appearance.space.m : 0
        radius: Appearance.radius.full
        color: root.selected ? Colors.secondaryContainer : "transparent"
        clip: true

        Behavior on color { ColorAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.selected ? Colors.on.secondaryContainer : Colors.on.surface
            opacity: ma.pressed ? Appearance.statePress
                     : ma.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        }
    }

    MIcon {
        id: ic
        x: root.expanded ? Appearance.space.l : (root.width - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 21
        fill: root.selected ? 1 : 0
        color: root.selected ? Colors.on.secondaryContainer : Colors.on.surfaceVariant
        Behavior on x { NumberAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }
    }

    Text {
        anchors.left: ic.right
        anchors.leftMargin: Appearance.space.l
        anchors.right: parent.right
        anchors.rightMargin: Appearance.space.xl
        anchors.verticalCenter: parent.verticalCenter
        visible: root.expanded
        opacity: root.expanded ? 1 : 0
        text: root.label
        elide: Text.ElideRight
        color: root.selected ? Colors.on.secondaryContainer : Colors.on.surfaceVariant
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.font.labelLarge
        font.weight: root.selected ? Appearance.font.weightMedium : Appearance.font.weightRegular
        Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: root.expanded ? Appearance.space.xl : 6
        anchors.top: parent.top
        anchors.topMargin: root.expanded ? 0 : 6
        anchors.verticalCenter: root.expanded ? parent.verticalCenter : undefined
        visible: root.badge !== ""
        width: Math.max(18, badgeText.implicitWidth + 10)
        height: 18
        radius: 9
        color: Colors.error

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.badge
            color: Colors.on.error
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.labelSmall
            font.weight: Appearance.font.weightMedium
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
