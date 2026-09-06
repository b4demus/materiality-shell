import QtQuick
import "root:/config"
import "root:/components"
import "root:/services"

// Base for every settings page: a scrolling column with the standard header,
// gutters and max content width, so all pages line up with each other.
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property real maxWidth: 880
    property alias headerActions: header.actions
    // A page can opt out of the shared header (Wallpaper does its own thing).
    property bool showHeader: true

    default property alias content: col.data

    anchors.fill: parent

    MScroll {
        id: scroll
        anchors.fill: parent
        contentHeight: wrapper.implicitHeight

        Item {
            id: wrapper
            width: scroll.width
            implicitHeight: col.implicitHeight + Appearance.space.xxl * 2

            Column {
                id: col
                x: Math.max(Appearance.space.xl, (wrapper.width - root.maxWidth) / 2)
                y: Appearance.space.xxl
                width: Math.min(root.maxWidth, wrapper.width - Appearance.space.xl * 2)
                spacing: Appearance.space.xl

                MHeader {
                    id: header
                    width: parent.width
                    visible: root.showHeader
                    title: root.title
                    subtitle: root.subtitle
                }
            }
        }
    }
}
