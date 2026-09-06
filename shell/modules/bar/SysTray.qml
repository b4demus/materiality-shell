import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "root:/config"
import "root:/components"

// Inline tray icons on the solid bar. Left-click activates; right-click (or
// left-click for menu-only items) opens the app's own menu, rendered as a
// Material You popup so you can Quit / whatever the app offers.
Grid {
    id: root
    property var bar

    // Runs along the bar's axis so tray icons stack in a vertical bar.
    readonly property bool vertical: Appearance.barVertical

    rows: vertical ? 0 : 1
    columns: vertical ? 1 : 0
    rowSpacing: Appearance.space.s
    columnSpacing: Appearance.space.s
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: entry
            required property SystemTrayItem modelData
            implicitWidth: 22
            implicitHeight: 22

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: entry.modelData.icon
            }

            Rectangle {
                anchors.fill: parent
                radius: Appearance.radius.s
                color: Colors.barOnSurface
                opacity: menu.visible ? Appearance.statePress
                         : ma.pressed ? Appearance.statePress
                         : ma.containsMouse ? Appearance.stateHover : 0
                Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
            }

            function openMenu() {
                if (!entry.modelData.hasMenu)
                    return
                menu.stack = []
                menu.visible = true
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        if (entry.modelData.onlyMenu) entry.openMenu()
                        else entry.modelData.activate()
                    } else if (mouse.button === Qt.RightButton) {
                        if (entry.modelData.hasMenu) entry.openMenu()
                        else entry.modelData.secondaryActivate()
                    } else {
                        entry.modelData.secondaryActivate()
                    }
                }
                onWheel: w => entry.modelData.scroll(w.angleDelta.x, w.angleDelta.y, false)
            }

            // ---- Material You context menu -------------------------------
            PopupWindow {
                id: menu
                visible: false
                grabFocus: true
                color: "transparent"

                anchor.item: entry
                anchor.rect.x: entry.width / 2
                anchor.rect.y: entry.height + Appearance.space.xs
                anchor.gravity: Edges.Bottom | Edges.Left
                anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.FlipY

                implicitWidth: card.width
                implicitHeight: card.height

                // submenu navigation stack (QsMenuHandles); empty = root menu
                property var stack: []
                readonly property var currentHandle: stack.length > 0
                    ? stack[stack.length - 1]
                    : entry.modelData.menu

                onVisibleChanged: if (!visible) stack = []

                function strip(t) {
                    return ("" + t).replace(/&(.)/g, "$1").replace(/&$/, "")
                }

                QsMenuOpener {
                    id: opener
                    menu: menu.visible ? menu.currentHandle : null
                }

                Rectangle {
                    id: card
                    width: Math.max(184, col.implicitWidth + Appearance.space.s * 2)
                    height: col.implicitHeight + Appearance.space.s * 2
                    radius: Appearance.radius.m
                    color: Colors.surfaceContainerHigh
                    border.width: 1
                    border.color: Colors.outlineVariant

                    focus: true
                    Keys.onEscapePressed: menu.visible = false

                    Column {
                        id: col
                        anchors.centerIn: parent
                        width: parent.width - Appearance.space.s * 2
                        spacing: 0

                        // "back" row while inside a submenu
                        Rectangle {
                            width: parent.width
                            height: visible ? 34 : 0
                            visible: menu.stack.length > 0
                            radius: Appearance.radius.s
                            color: backMa.containsMouse ? Colors.surfaceContainerHighest : "transparent"
                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: Appearance.space.s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Appearance.space.xs
                                MIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "chevron_left"; size: 18
                                    color: Colors.on.surfaceVariant
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Back"
                                    color: Colors.on.surfaceVariant
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.font.labelMedium
                                }
                            }
                            MouseArea {
                                id: backMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: menu.stack = menu.stack.slice(0, -1)
                            }
                        }

                        Repeater {
                            model: opener.children

                            delegate: Loader {
                                id: rowLoader
                                required property QsMenuEntry modelData
                                width: col.width
                                sourceComponent: modelData.isSeparator ? sepC : itemC

                                Component {
                                    id: sepC
                                    Item {
                                        width: col.width
                                        height: 9
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.margins: Appearance.space.xs
                                            height: 1
                                            color: Colors.outlineVariant
                                        }
                                    }
                                }

                                Component {
                                    id: itemC
                                    Rectangle {
                                        width: col.width
                                        height: 34
                                        radius: Appearance.radius.s
                                        color: rowMa.containsMouse && rowLoader.modelData.enabled
                                            ? Colors.surfaceContainerHighest : "transparent"

                                        Row {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.leftMargin: Appearance.space.s
                                            anchors.rightMargin: Appearance.space.l
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Appearance.space.s

                                            MIcon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: rowLoader.modelData.buttonType !== QsMenuButtonType.None
                                                name: rowLoader.modelData.buttonType === QsMenuButtonType.RadioButton
                                                    ? (rowLoader.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked")
                                                    : (rowLoader.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank")
                                                size: 16
                                                color: rowLoader.modelData.checkState === Qt.Checked
                                                    ? Colors.primary : Colors.on.surfaceVariant
                                            }

                                            IconImage {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: rowLoader.modelData.icon !== ""
                                                implicitSize: 16
                                                source: rowLoader.modelData.icon
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width - x
                                                elide: Text.ElideRight
                                                text: menu.strip(rowLoader.modelData.text)
                                                color: rowLoader.modelData.enabled
                                                    ? Colors.on.surface : Colors.on.surfaceVariant
                                                opacity: rowLoader.modelData.enabled ? 1 : 0.5
                                                font.family: Appearance.fontFamily
                                                font.pixelSize: Appearance.font.labelMedium
                                            }
                                        }

                                        MIcon {
                                            anchors.right: parent.right
                                            anchors.rightMargin: Appearance.space.xs
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: rowLoader.modelData.hasChildren
                                            name: "chevron_right"
                                            size: 18
                                            color: Colors.on.surfaceVariant
                                        }

                                        MouseArea {
                                            id: rowMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            enabled: rowLoader.modelData.enabled
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (rowLoader.modelData.hasChildren) {
                                                    rowLoader.modelData.opened()
                                                    menu.stack = menu.stack.concat([rowLoader.modelData])
                                                } else {
                                                    rowLoader.modelData.triggered()
                                                    menu.visible = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
