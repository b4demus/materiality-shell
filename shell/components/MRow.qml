import QtQuick
import "root:/config"

// One setting: leading icon, title, supporting text, and a trailing control
// slot. This is the workhorse of every settings page, so it owns the alignment
// rules rather than each page reinventing them.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool enabledRow: true
    property bool clickable: false
    // Badge shown when a setting can't take effect until niri/the shell reloads.
    property string badge: ""
    property real minHeight: 56

    default property alias trailing: trailingSlot.data

    signal clicked()

    implicitWidth: 400
    implicitHeight: Math.max(minHeight,
                             Math.max(textCol.implicitHeight, trailingSlot.implicitHeight)
                             + Appearance.space.m * 2)

    opacity: enabledRow ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -Appearance.space.s
        anchors.rightMargin: -Appearance.space.s
        radius: Appearance.radius.s
        color: Colors.on.surface
        visible: root.clickable
        opacity: !root.clickable || !root.enabledRow ? 0
                 : ma.pressed ? Appearance.statePress
                 : ma.containsMouse ? Appearance.stateHover : 0
        Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
    }

    MIcon {
        id: iconItem
        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 22
        color: Colors.on.surfaceVariant
    }

    Column {
        id: textCol
        anchors.left: iconItem.visible ? iconItem.right : parent.left
        anchors.leftMargin: iconItem.visible ? Appearance.space.l : 0
        anchors.right: trailingSlot.left
        anchors.rightMargin: Appearance.space.l
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Row {
            spacing: Appearance.space.s
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                color: Colors.on.surface
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodyLarge
                font.weight: Appearance.font.weightMedium
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.badge !== ""
                height: 20
                width: badgeText.implicitWidth + Appearance.space.m
                radius: Appearance.radius.xs
                color: Colors.tertiaryContainer
                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.badge
                    color: Colors.on.tertiaryContainer
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.labelSmall
                    font.weight: Appearance.font.weightMedium
                }
            }
        }

        Text {
            visible: root.subtitle !== ""
            width: textCol.width
            text: root.subtitle
            wrapMode: Text.WordWrap
            color: Colors.on.surfaceVariant
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.bodySmall
        }
    }

    // Sized from whatever control the caller drops in.
    Item {
        id: trailingSlot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        width: childrenRect.width
        height: childrenRect.height
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: root.clickable && root.enabledRow
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
