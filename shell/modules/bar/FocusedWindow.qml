import QtQuick
import "root:/config"
import "root:/components"
import "root:/services"

// App id + title of the focused window. Plain inline text on the solid bar.
Row {
    id: root
    property real maxWidth: 240
    spacing: Appearance.space.s

    visible: Niri.focusedTitle !== "" || Niri.focusedAppId !== ""
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

    MIcon {
        anchors.verticalCenter: parent.verticalCenter
        name: "widgets"
        size: 15
        color: Colors.primary
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, root.maxWidth)
        elide: Text.ElideRight
        text: {
            const a = Niri.focusedAppId
            const t = Niri.focusedTitle
            if (a && t) return a + "  ·  " + t
            return a || t
        }
        color: Colors.barOnSurfaceVariant
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.font.labelMedium
        font.weight: Appearance.font.weightMedium
    }
}
