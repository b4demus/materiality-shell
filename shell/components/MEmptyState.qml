import QtQuick
import "root:/config"

// What a page shows when there is genuinely nothing to show — or when a
// feature needs something installed. `actionLabel` turns it into a call to
// action; `code` renders a copyable command.
Item {
    id: root

    property string icon: "info"
    property string title: ""
    property string message: ""
    property string code: ""
    property string actionLabel: ""

    signal actionClicked()

    implicitHeight: col.implicitHeight + Appearance.space.xxl * 2
    implicitWidth: 400

    Column {
        id: col
        anchors.centerIn: parent
        width: Math.min(parent.width - Appearance.space.xl * 2, 460)
        spacing: Appearance.space.m

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 72; height: 72
            radius: Appearance.radius.xl
            color: Colors.surfaceContainerHighest

            MIcon {
                anchors.centerIn: parent
                name: root.icon
                size: 34
                color: Colors.on.surfaceVariant
            }
        }

        Text {
            width: parent.width
            visible: root.title !== ""
            text: root.title
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Colors.on.surface
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.titleMedium
            font.weight: Appearance.font.weightMedium
        }

        Text {
            width: parent.width
            visible: root.message !== ""
            text: root.message
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Colors.on.surfaceVariant
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.bodyMedium
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.code !== ""
            width: codeText.implicitWidth + Appearance.space.xl
            height: 40
            radius: Appearance.radius.s
            color: Colors.surfaceContainerHighest

            Text {
                id: codeText
                anchors.centerIn: parent
                text: root.code
                color: Colors.tertiary
                font.family: Appearance.monoFamily
                font.pixelSize: Appearance.font.bodyMedium
            }
        }

        MButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.actionLabel !== ""
            label: root.actionLabel
            bg: Colors.primaryContainer
            fg: Colors.on.primaryContainer
            hpad: Appearance.space.xl
            onClicked: root.actionClicked()
        }
    }
}
