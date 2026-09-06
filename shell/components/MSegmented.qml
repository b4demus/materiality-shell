import QtQuick
import "root:/config"

// M3 segmented button group. `model` is [{ value, label, icon }]; the selected
// segment fills with the secondary container and the indicator springs across.
Item {
    id: root

    property var model: []
    property var value: null
    property bool dense: false
    property bool equalWidths: true

    signal picked(var value)

    implicitHeight: dense ? 32 : 40
    implicitWidth: row.implicitWidth + 4

    function indexOfValue(v) {
        for (let i = 0; i < model.length; i++)
            if (model[i].value === v) return i
        return -1
    }
    readonly property int current: indexOfValue(value)

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.full
        color: "transparent"
        border.width: 1
        border.color: Colors.outlineVariant
    }

    // Sliding selection pill, drawn under the labels.
    Rectangle {
        id: indicator
        visible: root.current >= 0
        height: parent.height - 4
        width: root.equalWidths && root.model.length > 0
               ? (root.width - 4) / root.model.length
               : (root.current >= 0 && rep.itemAt(root.current) ? rep.itemAt(root.current).width : 0)
        x: root.equalWidths
           ? 2 + root.current * ((root.width - 4) / Math.max(1, root.model.length))
           : (root.current >= 0 && rep.itemAt(root.current) ? rep.itemAt(root.current).x + 2 : 2)
        y: 2
        radius: Appearance.radius.full
        color: Colors.secondaryContainer

        Behavior on x {
            SpringAnimation {
                spring: Motion.spatialFast.spring; damping: Motion.spatialFast.damping
                mass: Motion.spatialFast.mass; epsilon: Motion.spatialFast.epsilon
            }
        }
        Behavior on width { NumberAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }
        Behavior on color { ColorAnimation { duration: Motion.durMedium } }
    }

    Row {
        id: row
        anchors.fill: parent
        anchors.margins: 2

        Repeater {
            id: rep
            model: root.model

            delegate: Item {
                id: seg
                required property var modelData
                required property int index

                readonly property bool sel: root.current === seg.index
                width: root.equalWidths
                       ? (row.width / Math.max(1, root.model.length))
                       : segRow.implicitWidth + Appearance.space.xl
                height: row.height

                Row {
                    id: segRow
                    anchors.centerIn: parent
                    spacing: Appearance.space.xs

                    MIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: seg.modelData.icon !== undefined && seg.modelData.icon !== ""
                        name: seg.modelData.icon || ""
                        size: root.dense ? 15 : 17
                        fill: seg.sel ? 1 : 0
                        color: seg.sel ? Colors.on.secondaryContainer : Colors.on.surfaceVariant
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: seg.modelData.label !== undefined && seg.modelData.label !== ""
                        text: seg.modelData.label || ""
                        color: seg.sel ? Colors.on.secondaryContainer : Colors.on.surfaceVariant
                        font.family: Appearance.fontFamily
                        font.pixelSize: root.dense ? Appearance.font.labelMedium : Appearance.font.labelLarge
                        font.weight: Appearance.font.weightMedium
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Appearance.radius.full
                    color: seg.sel ? Colors.on.secondaryContainer : Colors.on.surface
                    opacity: segMa.pressed ? Appearance.statePress
                             : segMa.containsMouse ? Appearance.stateHover : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
                }

                MouseArea {
                    id: segMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.value = seg.modelData.value
                        root.picked(seg.modelData.value)
                    }
                }
            }
        }
    }
}
