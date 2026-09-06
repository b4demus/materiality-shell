import QtQuick
import "root:/config"

// Material 3 (2024 "expressive") slider: thick rounded track, inset gap,
// vertical-bar handle, stop dot at the far end.
Item {
    id: root

    property real value: 0            // 0..1
    property bool interactive: true
    property color activeColor: Colors.primary
    property color trackColor: Colors.secondaryContainer
    property real trackHeight: 16
    property real handleWidth: 4
    // Symmetric breathing room between the handle and each track segment.
    property real handleGap: 6

    signal moved(real value)

    implicitHeight: trackHeight + 8
    implicitWidth: 200

    readonly property real _usable: width - handleWidth
    readonly property real _target: Math.max(0, Math.min(1, value)) * _usable

    // One spring-smoothed handle position that the fill, both gaps and the
    // handle all derive from — so they can never visually desync mid-drag
    // (the earlier per-item Behaviors let the right track jump while the left
    // fill lagged on its own spring).
    property real _x: _target
    Behavior on _x {
        SpringAnimation {
            spring: Motion.spatial.spring; damping: Motion.spatial.damping
            mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
        }
    }

    // Active (left) segment — stops `handleGap` short of the handle. No minimum
    // width: it just shrinks away as the value nears 0 instead of leaving a
    // rounded stub floating behind the handle.
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight
        width: Math.max(0, root._x - root.handleGap)
        radius: height / 2
        color: root.activeColor
    }

    // Inactive (right) segment — starts `handleGap` past the handle, mirroring
    // the active side so the handle sits centred in the gap
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        height: root.trackHeight
        width: Math.max(0, root.width - root._x - root.handleWidth - root.handleGap)
        radius: height / 2
        color: root.trackColor

        // stop indicator
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 6
            width: 4; height: 4; radius: 2
            color: root.activeColor
            visible: parent.width > 12
        }
    }

    // Handle
    Rectangle {
        id: handle
        x: root._x
        anchors.verticalCenter: parent.verticalCenter
        width: root.handleWidth
        height: root.trackHeight + 8
        radius: root.handleWidth / 2
        color: root.activeColor
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        onPressed: mouse => setFromX(mouse.x)
        onPositionChanged: mouse => pressed && setFromX(mouse.x)
        function setFromX(px) {
            const v = Math.max(0, Math.min(1, (px - root.handleWidth / 2) / root._usable))
            root.value = v
            root.moved(v)
        }
    }
}
