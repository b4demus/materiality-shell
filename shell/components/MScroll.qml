import QtQuick
import "root:/config"

// Flickable with an M3 scrollbar that only appears while it is useful.
Flickable {
    id: root

    property bool showBar: true

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 6000
    maximumFlickVelocity: 3500
    contentWidth: width

    Rectangle {
        id: bar
        anchors.right: parent.right
        anchors.rightMargin: 3
        width: 6
        radius: 3
        color: Colors.outline

        readonly property real ratio: root.contentHeight > 0
                                      ? Math.min(1, root.height / root.contentHeight) : 1
        visible: root.showBar && ratio < 1
        height: Math.max(40, root.height * ratio)
        y: root.contentHeight > root.height
           ? (root.contentY / (root.contentHeight - root.height)) * (root.height - height)
           : 0

        opacity: root.moving ? 0.55 : 0.22
        Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }
    }
}
