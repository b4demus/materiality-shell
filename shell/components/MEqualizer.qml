import QtQuick
import "root:/config"

// Tiny faux-equalizer: a handful of rounded bars that bob while `active`, and
// ease down to a flat resting state when not. Decorative — not audio-reactive.
Row {
    id: root

    property bool active: true
    property color barColor: Colors.primary
    property int bars: 4
    property real barWidth: 3
    property real gap: 2
    property real maxHeight: 13
    property real minHeight: 3

    spacing: gap
    height: maxHeight

    Repeater {
        model: root.bars

        Rectangle {
            id: bar
            required property int index

            width: root.barWidth
            radius: root.barWidth / 2
            color: root.barColor
            anchors.verticalCenter: parent.verticalCenter

            height: root.active ? level : root.minHeight
            property real level: root.minHeight

            Behavior on height {
                NumberAnimation {
                    duration: 220 + (bar.index % 3) * 60
                    easing.type: Easing.InOutSine
                }
            }
            Behavior on color {
                ColorAnimation { duration: Motion.durMedium }
            }

            Timer {
                running: root.active
                repeat: true
                triggeredOnStart: true
                interval: 170 + bar.index * 50 + (bar.index % 2) * 40
                onTriggered: bar.level = root.minHeight
                    + Math.random() * (root.maxHeight - root.minHeight)
            }
        }
    }
}
