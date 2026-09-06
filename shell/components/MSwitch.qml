import QtQuick
import "root:/config"

// Material 3 (2024) switch: the handle grows when on, shrinks under the press,
// and carries a check/cross glyph. Spring-driven, so it feels physical.
Item {
    id: root

    property bool checked: false
    property bool enabledSwitch: true
    property bool showIcon: true

    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 32

    opacity: enabledSwitch ? 1 : 0.38

    // A single spring-animated 0..1 progress that BOTH the handle's travel and
    // its size derive from. Previously `x` and `size` each had their own
    // `Behavior`, and `x` was computed from the (also animating) `size` — so the
    // two springs kept retargeting each other every frame and the handle stalled
    // mid-track. One source of truth fixes that.
    property real _prog: checked ? 1 : 0
    Behavior on _prog {
        SpringAnimation {
            spring: Motion.spatialFast.spring; damping: Motion.spatialFast.damping
            mass: Motion.spatialFast.mass; epsilon: Motion.spatialFast.epsilon
        }
    }

    // Press bump, tweened independently so it never feeds back into travel.
    property real _press: ma.pressed && enabledSwitch ? 1 : 0
    Behavior on _press { NumberAnimation { duration: Motion.durShort } }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Colors.primary : Colors.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Colors.outline

        Behavior on color { ColorAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }

        Rectangle {
            id: handle
            // Off 16px, on 24px, pressed up to 28px — the M3 "expressive" handle.
            readonly property real size: Math.max(16 + 8 * root._prog, 28 * root._press)
            // Centre travels from the left inset to the right inset.
            readonly property real centreX: parent.height / 2
                                            + root._prog * (parent.width - parent.height)
            width: size
            height: size
            radius: size / 2
            anchors.verticalCenter: parent.verticalCenter
            x: centreX - size / 2
            color: root.checked ? Colors.on.primary
                                : (ma.containsMouse ? Colors.on.surfaceVariant : Colors.outline)

            Behavior on color { ColorAnimation { duration: Motion.durMedium } }

            MIcon {
                anchors.centerIn: parent
                visible: root.showIcon && root.checked
                name: "check"
                size: 14
                weight: 700
                color: Colors.primary
                opacity: root.checked ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
            }
        }

        // Hover halo around the handle.
        Rectangle {
            width: 40; height: 40; radius: 20
            x: handle.x + handle.width / 2 - 20
            anchors.verticalCenter: parent.verticalCenter
            color: root.checked ? Colors.primary : Colors.on.surface
            opacity: !root.enabledSwitch ? 0
                     : ma.pressed ? Appearance.statePress
                     : ma.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.margins: -6
        enabled: root.enabledSwitch
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
