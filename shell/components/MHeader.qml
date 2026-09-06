import QtQuick
import "root:/config"

// Page header: big expressive title, supporting line, and a trailing slot for
// page-level actions.
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string icon: ""

    default property alias actions: actionSlot.data

    implicitWidth: 600
    implicitHeight: Math.max(col.implicitHeight, actionSlot.implicitHeight)

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: actionSlot.left
        anchors.rightMargin: Appearance.space.l
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            text: root.title
            color: Colors.on.surface
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.headlineMedium
            font.weight: Appearance.font.weightMedium
        }
        Text {
            visible: root.subtitle !== ""
            width: col.width
            text: root.subtitle
            wrapMode: Text.WordWrap
            color: Colors.on.surfaceVariant
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.bodyMedium
        }
    }

    // Row sizes itself from its children, so the header can measure the
    // actions without the caller declaring a width.
    Row {
        id: actionSlot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.space.s
    }
}
