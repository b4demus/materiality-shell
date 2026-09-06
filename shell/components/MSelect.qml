import QtQuick
import "root:/config"

// M3 dropdown menu. `model` is [{ value, label, icon, hint }].
//
// The menu is reparented to the window's root item so it draws over cards and
// escapes any clipping ScrollView, and it flips above the field when there
// isn't room below.
Item {
    id: root

    property var model: []
    property var value: null
    property string placeholder: "Select…"
    property string leadingIcon: ""
    property bool enabledSelect: true
    property int maxVisible: 8

    signal picked(var value)

    implicitHeight: 44
    implicitWidth: 200

    readonly property var selectedItem: {
        for (const m of model) if (m.value === value) return m
        return null
    }
    readonly property string displayText: selectedItem ? selectedItem.label : placeholder

    property bool open: false

    function rootItem() {
        let p = root
        while (p.parent) p = p.parent
        return p
    }

    onEnabledSelectChanged: if (!enabledSelect) open = false

    Rectangle {
        id: field
        anchors.fill: parent
        radius: Appearance.radius.s
        color: Colors.surfaceContainerHighest
        border.width: root.open ? 2 : 1
        border.color: root.open ? Colors.primary : Colors.outlineVariant
        opacity: root.enabledSelect ? 1 : 0.5
        clip: true

        Behavior on border.color { ColorAnimation { duration: Motion.durShort } }

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Appearance.space.m
            anchors.rightMargin: Appearance.space.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.space.s

            MIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.leadingIcon !== ""
                         || !!(root.selectedItem && root.selectedItem.icon)
                name: (root.selectedItem && root.selectedItem.icon) || root.leadingIcon
                size: 18
                color: Colors.on.surfaceVariant
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - (arrow.width + Appearance.space.s * 2)
                       - ((root.leadingIcon !== ""
                           || !!(root.selectedItem && root.selectedItem.icon))
                          ? 18 + Appearance.space.s : 0)
                text: root.displayText
                elide: Text.ElideRight
                color: root.selectedItem ? Colors.on.surface : Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodyMedium
            }
        }

        MIcon {
            id: arrow
            anchors.right: parent.right
            anchors.rightMargin: Appearance.space.m
            anchors.verticalCenter: parent.verticalCenter
            name: "expand_more"
            size: 20
            color: Colors.on.surfaceVariant
            rotation: root.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Colors.on.surface
            opacity: ma.pressed ? Appearance.statePress : ma.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: root.enabledSelect
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }

    // ---- the menu, hoisted out of any clipping ancestor --------------------
    Loader {
        id: menuLoader
        active: root.open
        sourceComponent: menuComponent
    }

    Component {
        id: menuComponent

        Item {
            id: menuRoot
            // Parent declaratively (not in Loader.onLoaded) so `anchors.fill` and
            // the position maths below see the final ancestor from the first
            // layout pass instead of briefly resolving against the Loader.
            parent: root.rootItem()
            anchors.fill: parent
            z: 9000

            // `mapToItem` in a plain binding never re-runs when an ancestor
            // moves (e.g. the field scrolls into place, the window lays out),
            // which left the sheet pinned to the top-left corner. Recompute it
            // explicitly once the menu is up — the overlay MouseArea closes the
            // menu on wheel/click-away, so open-time is the only moment that
            // matters.
            property point origin: Qt.point(0, 0)
            function reposition() {
                if (menuRoot.width > 0)
                    origin = root.mapToItem(menuRoot, 0, 0)
            }
            Component.onCompleted: Qt.callLater(reposition)
            onWidthChanged: Qt.callLater(reposition)
            onHeightChanged: Qt.callLater(reposition)

            readonly property real rowH: 44
            readonly property real menuH: Math.min(root.maxVisible, root.model.length) * rowH
                                          + Appearance.space.s * 2
            readonly property bool above: origin.y + root.height + menuH > menuRoot.height - 8

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
                onWheel: root.open = false
            }

            Rectangle {
                id: sheet
                x: Math.max(8, Math.min(menuRoot.width - width - 8, menuRoot.origin.x))
                y: menuRoot.above ? menuRoot.origin.y - menuH - 6
                                  : menuRoot.origin.y + root.height + 6
                width: Math.max(root.width, 200)
                height: menuRoot.menuH
                radius: Appearance.radius.m
                color: Colors.surfaceContainerHigh
                border.width: 1
                border.color: Colors.outlineVariant
                clip: true

                opacity: 0
                scale: 0.94
                transformOrigin: menuRoot.above ? Item.Bottom : Item.Top
                Component.onCompleted: { opacity = 1; scale = 1 }
                Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
                Behavior on scale {
                    SpringAnimation {
                        spring: Motion.spatialFast.spring; damping: Motion.spatialFast.damping
                        mass: Motion.spatialFast.mass; epsilon: Motion.spatialFast.epsilon
                    }
                }

                MouseArea { anchors.fill: parent }   // swallow the dismiss click

                ListView {
                    anchors.fill: parent
                    anchors.topMargin: Appearance.space.s
                    anchors.bottomMargin: Appearance.space.s
                    clip: true
                    model: root.model
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: -1

                    delegate: Item {
                        id: opt
                        required property var modelData
                        width: ListView.view.width
                        height: menuRoot.rowH
                        readonly property bool sel: modelData.value === root.value

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Appearance.radius.s
                            color: opt.sel ? Colors.secondaryContainer : "transparent"
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: Colors.on.surface
                                opacity: optMa.pressed ? Appearance.statePress
                                         : optMa.containsMouse ? Appearance.stateHover : 0
                                Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
                            }
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Appearance.space.m
                            anchors.rightMargin: Appearance.space.m
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Appearance.space.m

                            MIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: opt.modelData.icon !== undefined && opt.modelData.icon !== ""
                                name: opt.modelData.icon || ""
                                size: 18
                                color: opt.sel ? Colors.on.secondaryContainer : Colors.on.surfaceVariant
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: opt.modelData.label || ""
                                    color: opt.sel ? Colors.on.secondaryContainer : Colors.on.surface
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.font.bodyMedium
                                    font.weight: opt.sel ? Appearance.font.weightMedium
                                                         : Appearance.font.weightRegular
                                }
                                Text {
                                    visible: opt.modelData.hint !== undefined && opt.modelData.hint !== ""
                                    text: opt.modelData.hint || ""
                                    color: Colors.on.surfaceVariant
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.font.labelSmall
                                }
                            }
                        }

                        MouseArea {
                            id: optMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.value = opt.modelData.value
                                root.picked(opt.modelData.value)
                                root.open = false
                            }
                        }
                    }
                }
            }
        }
    }
}
