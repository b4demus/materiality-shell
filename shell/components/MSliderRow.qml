import QtQuick
import "root:/config"

// A labelled slider with a live readout — the shape most numeric settings take.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property string suffix: ""
    property int decimals: 0
    property bool enabledRow: true
    property color accent: Colors.primary
    // Optional custom readout, e.g. "Comfortable" instead of "2".
    property string valueText: ""

    signal moved(real value)
    signal released(real value)

    implicitWidth: 400
    implicitHeight: head.implicitHeight + slider.implicitHeight + Appearance.space.m * 2 + Appearance.space.s

    opacity: enabledRow ? 1 : 0.45

    readonly property real norm: to > from ? (value - from) / (to - from) : 0

    function snap(v) {
        let out = root.from + v * (root.to - root.from)
        if (root.stepSize > 0) out = Math.round(out / root.stepSize) * root.stepSize
        return Math.max(root.from, Math.min(root.to, out))
    }

    Item {
        id: head
        anchors.top: parent.top
        anchors.topMargin: Appearance.space.m
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: Math.max(20, titleCol.implicitHeight)

        MIcon {
            id: ic
            visible: root.icon !== ""
            anchors.left: parent.left
            anchors.top: parent.top
            name: root.icon
            size: 22
            color: Colors.on.surfaceVariant
        }

        Column {
            id: titleCol
            anchors.left: ic.visible ? ic.right : parent.left
            anchors.leftMargin: ic.visible ? Appearance.space.l : 0
            anchors.right: readout.left
            anchors.rightMargin: Appearance.space.m
            spacing: 2

            Text {
                text: root.title
                color: Colors.on.surface
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodyLarge
                font.weight: Appearance.font.weightMedium
            }
            Text {
                visible: root.subtitle !== ""
                width: titleCol.width
                text: root.subtitle
                wrapMode: Text.WordWrap
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodySmall
            }
        }

        Rectangle {
            id: readout
            anchors.right: parent.right
            anchors.top: parent.top
            height: 26
            width: readoutText.implicitWidth + Appearance.space.l
            radius: Appearance.radius.xs
            color: Colors.surfaceContainerHighest

            Text {
                id: readoutText
                anchors.centerIn: parent
                text: root.valueText !== "" ? root.valueText
                      : root.value.toFixed(root.decimals) + root.suffix
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelMedium
                font.weight: Appearance.font.weightMedium
            }
        }
    }

    MSlider {
        id: slider
        anchors.top: head.bottom
        anchors.topMargin: Appearance.space.s
        anchors.left: parent.left
        anchors.leftMargin: root.icon !== "" ? 22 + Appearance.space.l : 0
        anchors.right: parent.right
        interactive: root.enabledRow
        activeColor: root.accent
        value: root.norm
        onMoved: v => {
            const out = root.snap(v)
            root.value = out
            root.moved(out)
        }
    }
}
