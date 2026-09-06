import QtQuick
import "root:/config"

// A rounded surface container laying its children out in a row.
// The basic building block of the bar and panels.
//
//   MPill { ...row children... ; overlay: [ MouseArea { anchors.fill: parent } ] }
//
Rectangle {
    id: root

    property real radius_: Appearance.radius.full
    property real padding: Appearance.barPad
    property real gap: Appearance.space.s
    default property alias content: inner.data
    property alias overlay: overlayItem.data

    radius: radius_
    color: Colors.surfaceContainer
    implicitWidth: inner.implicitWidth + padding * 2
    implicitHeight: inner.implicitHeight + padding * 2
    clip: true

    Behavior on color {
        ColorAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard }
    }

    Row {
        id: inner
        anchors.centerIn: parent
        spacing: root.gap
    }

    Item {
        id: overlayItem
        anchors.fill: parent
    }
}
