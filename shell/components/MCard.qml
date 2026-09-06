import QtQuick
import "root:/config"

// M3 surface container. The default is a plain tonal card; set `interactive`
// to get a state layer and a subtle lift on hover, which is how the settings
// pages signal "this whole card does something".
Rectangle {
    id: root

    property real radius_: Appearance.radius.xl
    property real padding: Appearance.space.l
    property color tone: Colors.surfaceContainer
    property bool interactive: false
    property bool selected: false
    property bool outlined: false
    property real gap: Appearance.space.m

    default property alias content: inner.data

    signal clicked()

    radius: radius_
    color: root.selected ? Colors.secondaryContainer : root.tone
    border.width: root.outlined ? 1 : 0
    border.color: root.selected ? Colors.primary : Colors.outlineVariant

    implicitWidth: inner.implicitWidth + padding * 2
    implicitHeight: inner.implicitHeight + padding * 2

    Behavior on color { ColorAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }

    // Hover raises the card by one tonal step rather than by a shadow: cheaper,
    // and it reads correctly on both light and dark palettes.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        visible: root.interactive
        color: root.selected ? Colors.on.secondaryContainer : Colors.on.surface
        opacity: !root.interactive ? 0
                 : ma.pressed ? Appearance.statePress
                 : ma.containsMouse ? Appearance.stateHover : 0
        Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
    }

    Column {
        id: inner
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.padding
        spacing: root.gap
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
