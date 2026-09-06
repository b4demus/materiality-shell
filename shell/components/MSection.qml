import QtQuick
import "root:/config"

// A titled group of settings inside a page: heading + optional description +
// a card holding the rows, with hairlines drawn between them automatically.
Item {
    id: root

    property string title: ""
    property string description: ""
    property string icon: ""
    property real spacing_: Appearance.space.xs
    property bool dividers: true
    property color tone: Colors.surfaceContainerLow

    default property alias content: card.content

    implicitWidth: 600
    implicitHeight: col.implicitHeight

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Appearance.space.m

        Row {
            visible: root.title !== ""
            spacing: Appearance.space.s
            leftPadding: Appearance.space.xs

            MIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.icon !== ""
                name: root.icon
                size: 18
                color: Colors.primary
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                color: Colors.primary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.titleSmall
                font.weight: Appearance.font.weightMedium
            }
        }

        Text {
            visible: root.description !== ""
            width: parent.width - Appearance.space.s
            leftPadding: Appearance.space.xs
            text: root.description
            wrapMode: Text.WordWrap
            color: Colors.on.surfaceVariant
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.bodySmall
        }

        MCard {
            id: card
            width: parent.width
            tone: root.tone
            gap: root.spacing_
            padding: Appearance.space.l
        }
    }
}
