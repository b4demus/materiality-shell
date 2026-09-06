import QtQuick
import "root:/config"

// M3 state layer: a tinted overlay that reacts to hover / press, plus the
// pointer plumbing. Put it as the last child of a clipped rounded container.
MouseArea {
    id: root

    property color tint: Colors.on.surface
    property real radius: Appearance.radius.full
    property bool enableRipple: true

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        opacity: !root.enabled ? 0
                 : root.pressed ? Appearance.statePress
                 : root.containsMouse ? Appearance.stateHover
                 : 0
        Behavior on opacity {
            NumberAnimation { duration: Motion.durShort; easing.type: Motion.easeStandard }
        }
    }
}
