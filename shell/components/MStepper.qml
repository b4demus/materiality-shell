import QtQuick
import "root:/config"

// Compact numeric stepper for values a slider would be clumsy for
// (pixel sizes, counts, timeouts).
Row {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property int decimals: 0
    property string suffix: ""
    property bool enabledStepper: true

    signal changed(real value)

    spacing: Appearance.space.xs

    function bump(delta) {
        const next = Math.max(root.from, Math.min(root.to, root.value + delta * root.stepSize))
        if (next !== root.value) {
            root.value = next
            root.changed(next)
        }
    }

    opacity: enabledStepper ? 1 : 0.45

    MButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "remove"
        iconSize: 18
        minSize: 32
        bg: Colors.surfaceContainerHighest
        fg: Colors.on.surfaceVariant
        enabled: root.enabledStepper && root.value > root.from
        opacity: root.value > root.from ? 1 : 0.4
        onClicked: root.bump(-1)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(56, valueText.implicitWidth + Appearance.space.l)
        height: 32
        radius: Appearance.radius.xs
        color: "transparent"

        Text {
            id: valueText
            anchors.centerIn: parent
            text: root.value.toFixed(root.decimals) + root.suffix
            color: Colors.on.surface
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.bodyMedium
            font.weight: Appearance.font.weightMedium
        }
    }

    MButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "add"
        iconSize: 18
        minSize: 32
        bg: Colors.surfaceContainerHighest
        fg: Colors.on.surfaceVariant
        enabled: root.enabledStepper && root.value < root.to
        opacity: root.value < root.to ? 1 : 0.4
        onClicked: root.bump(1)
    }
}
