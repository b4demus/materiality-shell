import QtQuick
import "root:/config"
import "root:/components"
import "root:/services"

// One bar module drawn at preview scale. Each module gets a distinct silhouette
// so the layout stays legible when it is only a few pixels tall.
Item {
    id: root

    property string moduleId: ""
    property var scaleRef: null
    property bool vertical: false

    readonly property real s: scaleRef ? scaleRef.s : 0.2
    function px(v) { return Math.max(1, v * s) }

    readonly property real dotSize: px(Settings.val("bar.iconSize", 18))
    readonly property real wsGap: px(Settings.val("bar.workspaceSpacing", 6))

    implicitWidth: vertical ? dotSize : content.implicitWidth
    implicitHeight: vertical ? content.implicitHeight : dotSize
    anchors.verticalCenter: vertical ? undefined : (parent ? parent.verticalCenter : undefined)

    // Workspaces: the pill row, with the focused one stretched.
    Component {
        id: workspacesC
        Row {
            spacing: root.wsGap
            Repeater {
                model: 4
                delegate: Rectangle {
                    required property int index
                    width: index === 1 ? root.dotSize * 2.1 : root.dotSize * 0.7
                    height: root.dotSize * 0.7
                    radius: height / 2
                    color: index === 1 ? Colors.primary : Colors.on.surfaceVariant
                    opacity: index === 1 ? 1 : 0.4
                    Behavior on width { NumberAnimation { duration: Motion.durMedium } }
                }
            }
        }
    }

    // A text-ish module: a rounded bar standing in for a label.
    Component {
        id: labelC
        Rectangle {
            width: root.dotSize * (root.moduleId === "windowTitle" ? 4.2
                                   : root.moduleId === "clock" ? 2.4 : 1.8)
            height: root.dotSize * 0.6
            radius: height / 2
            color: Colors.on.surface
            opacity: root.moduleId === "windowTitle" ? 0.55 : 0.8
        }
    }

    // An icon module: a filled dot.
    Component {
        id: iconC
        Rectangle {
            width: root.dotSize * 0.72
            height: width
            radius: width / 2
            color: Colors.on.surfaceVariant
            opacity: 0.75
        }
    }

    // A group of icons (tray, status island).
    Component {
        id: groupC
        Row {
            spacing: root.px(6)
            Repeater {
                model: root.moduleId === "statusIsland" ? 3 : 2
                delegate: Rectangle {
                    width: root.dotSize * 0.72
                    height: width
                    radius: width / 2
                    color: Colors.on.surfaceVariant
                    opacity: 0.7
                }
            }
        }
    }

    Loader {
        id: content
        anchors.centerIn: parent
        sourceComponent: {
            switch (root.moduleId) {
            case "workspaces": return workspacesC
            case "windowTitle":
            case "clock":
            case "date":
            case "media":
            case "weather": return labelC
            case "tray":
            case "statusIsland": return groupC
            default: return iconC
            }
        }
    }
}
