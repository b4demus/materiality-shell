import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "root:/config"
import "root:/components"
import "root:/services"

Item {
    id: root
    property var notif

    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    implicitHeight: card.height
    clip: false

    // spring slide-in from the right
    x: shown ? 0 : width + 40
    opacity: shown ? 1 : 0
    property bool shown: false
    Component.onCompleted: shown = true
    Behavior on x {
        SpringAnimation {
            spring: Motion.spatial.spring; damping: Motion.spatial.damping
            mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
        }
    }
    Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

    // The sender's own timeout wins when it asked for one; otherwise the card
    // lives for however long the Notifications page says.
    Timer {
        id: life
        interval: root.notif && root.notif.expireTimeout > 0
                  ? root.notif.expireTimeout
                  : Settings.val("notifications.durationSec", 6) * 1000
        running: !root.critical && !hover.hovered
        onTriggered: if (root.notif) root.notif.dismiss()
    }

    Elevation { target: card; level: 3 }

    Rectangle {
        id: card
        width: parent.width
        height: layout.implicitHeight + Appearance.space.l * 2
        radius: Appearance.radius.l
        color: root.critical ? Colors.errorContainer : Colors.surfaceContainerHigh

        HoverHandler { id: hover }

        Column {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.space.l
            spacing: Appearance.space.s

            // header
            Item {
                width: parent.width
                height: 24

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.space.s

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 18
                        source: root.notif && root.notif.appIcon
                                ? Quickshell.iconPath(root.notif.appIcon, "dialog-information")
                                : ""
                        visible: source != ""
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.notif ? (root.notif.appName || "Notification") : ""
                        color: root.critical ? Colors.on.errorContainer : Colors.on.surfaceVariant
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.labelMedium
                        font.weight: Appearance.font.weightMedium
                    }
                }

                MButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "close"
                    iconSize: 16
                    fg: root.critical ? Colors.on.errorContainer : Colors.on.surfaceVariant
                    onClicked: if (root.notif) root.notif.dismiss()
                }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.notif ? root.notif.summary : ""
                color: root.critical ? Colors.on.errorContainer : Colors.on.surface
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodyLarge
                font.weight: Appearance.font.weightMedium
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.notif ? root.notif.body : ""
                color: root.critical ? Colors.on.errorContainer : Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodyMedium
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 5
            }

            // actions
            Flow {
                width: parent.width
                spacing: Appearance.space.s
                visible: root.notif && root.notif.actions && root.notif.actions.length > 0

                Repeater {
                    model: root.notif ? root.notif.actions : []
                    delegate: MButton {
                        required property var modelData
                        label: modelData.text || modelData.identifier
                        bg: Colors.secondaryContainer
                        fg: Colors.on.secondaryContainer
                        onClicked: modelData.invoke()
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton
            onClicked: if (root.notif) root.notif.dismiss()
        }
    }
}
