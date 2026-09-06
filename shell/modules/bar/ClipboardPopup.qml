import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/components"
import "root:/services"

// Last 15 clipboard entries (text + images), opened from the bar clipboard chip.
// Click an entry to put it back on the clipboard.
PanelWindow {
    id: root
    visible: Bus.clipboardOpen
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "expressive-clipboard"
    WlrLayershell.keyboardFocus: Bus.clipboardOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    Item {
        anchors.fill: parent
        focus: Bus.clipboardOpen
        Keys.onEscapePressed: Bus.clipboardOpen = false

        MouseArea { anchors.fill: parent; onClicked: Bus.clipboardOpen = false }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Bus.clipboardOpen
                ? Appearance.barInsetTop
                : -(height + 24)
            width: 360
            // Bounded by entry count (mixed row heights ~ 52 px), capped to the
            // screen. Not derived from list.contentHeight — the list is anchored
            // to fill the card, which would make that a binding loop.
            readonly property int rows: Math.min(Clipboard.entries.length, 15)
            height: Math.min(
                parent.height - 120,
                rows === 0 ? 150
                           : 52 + rows * 56 + Appearance.space.m)
            radius: Appearance.radius.xl
            color: Colors.surfaceContainerHigh
            clip: true

            opacity: Bus.clipboardOpen ? 1 : 0
            Behavior on anchors.topMargin {
                SpringAnimation {
                    spring: Motion.spatial.spring; damping: Motion.spatial.damping
                    mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
                }
            }
            Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

            MouseArea { anchors.fill: parent } // swallow

            // header
            Item {
                id: head
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Appearance.space.l
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clipboard"
                    color: Colors.on.surface
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.titleMedium
                    font.weight: Appearance.font.weightMedium
                }
                MButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Clipboard.entries.length > 0
                    icon: "delete_sweep"
                    label: "Clear"
                    iconSize: 16
                    vpad: 4
                    fg: Colors.on.surfaceVariant
                    onClicked: Clipboard.clear()
                }
            }

            Text {
                anchors.top: head.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Appearance.space.l
                anchors.topMargin: Appearance.space.s
                visible: Clipboard.entries.length === 0
                text: "Nothing copied yet.\nCopy some text, an image, or press Win+Shift+S."
                wrapMode: Text.Wrap
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelMedium
            }

            ListView {
                id: list
                anchors.top: head.bottom
                anchors.topMargin: Appearance.space.s
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: Appearance.space.m
                anchors.rightMargin: Appearance.space.m
                anchors.bottomMargin: Appearance.space.m
                clip: true
                spacing: Appearance.space.xs
                model: Clipboard.entries
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: modelData.kind === "image" ? 64 : 44
                    radius: Appearance.radius.m
                    color: Colors.surfaceContainerHighest

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.space.m
                        anchors.rightMargin: Appearance.space.m
                        spacing: Appearance.space.m

                        // thumbnail for images
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.modelData.kind === "image"
                            width: 84; height: 48
                            radius: Appearance.radius.s
                            color: Colors.surfaceContainerLow
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: row.modelData.kind === "image"
                                    ? "file://" + row.modelData.path : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                smooth: true
                                sourceSize.width: 200
                            }
                        }

                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.modelData.kind !== "image"
                            name: "notes"
                            size: 18
                            color: Colors.on.surfaceVariant
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - (row.modelData.kind === "image" ? 84 : 18)
                                   - Appearance.space.m
                            text: row.modelData.kind === "image"
                                ? "Image"
                                : row.modelData.preview
                            color: Colors.on.surface
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.labelMedium
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Colors.on.surface
                        opacity: rma.pressed ? Appearance.statePress
                                 : rma.containsMouse ? Appearance.stateHover : 0
                        Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
                    }

                    MouseArea {
                        id: rma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Clipboard.copy(row.modelData.id)
                            Bus.clipboardOpen = false
                        }
                    }
                }
            }
        }
    }
}
