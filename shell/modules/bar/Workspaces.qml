import QtQuick
import "root:/config"
import "root:/components"
import "root:/services"

// niri workspaces. Three indicator styles, all driven from the Workspaces page:
//   pill    stretch dots — inactive dot, active pill, focused primary pill
//   dots    fixed dots, focused one filled
//   numbers the workspace index (or its configured name/icon) in a chip
Item {
    id: root
    property string outputName: ""

    readonly property var list: Niri.workspacesFor(outputName)
    readonly property string style: Settings.val("workspaces.indicatorStyle", "pill")
    readonly property bool showLabels: Settings.val("workspaces.showLabels", false)
    readonly property bool showIcons: Settings.val("workspaces.showIcons", true)
    readonly property var named: Settings.val("workspaces.named", [])
    readonly property bool vertical: Appearance.barVertical

    function meta(idx) {
        for (const e of named) if (e.idx === idx) return e
        return null
    }
    function colorFor(ws, fallback) {
        const m = meta(ws.idx)
        return (m && m.color) ? m.color : fallback
    }
    function labelFor(ws) {
        const m = meta(ws.idx)
        if (m && m.name) return m.name
        return ws.name || String(ws.idx)
    }
    function iconFor(ws) {
        const m = meta(ws.idx)
        return (m && m.icon) ? m.icon : ""
    }

    implicitWidth: vertical ? Math.max(16, Appearance.barIconSize) : layout.implicitWidth
    implicitHeight: vertical ? layout.implicitHeight : Math.max(16, Appearance.barIconSize)

    MouseArea {
        anchors.fill: parent
        onWheel: wheelEvent => {
            const items = root.list
            if (!items.length) return
            let i = items.findIndex(w => w.is_focused)
            if (i < 0) i = 0
            const next = wheelEvent.angleDelta.y < 0 ? Math.min(items.length - 1, i + 1)
                                                     : Math.max(0, i - 1)
            Niri.focusWorkspace(items[next].idx)
        }
    }

    Grid {
        id: layout
        anchors.centerIn: parent
        rows: root.vertical ? 0 : 1
        columns: root.vertical ? 1 : 0
        rowSpacing: Appearance.barWorkspaceGap
        columnSpacing: Appearance.barWorkspaceGap
        flow: root.vertical ? Grid.LeftToRight : Grid.LeftToRight

        Repeater {
            model: root.list

            delegate: Item {
                id: ws
                required property var modelData

                readonly property bool focused: modelData.is_focused
                readonly property bool active: modelData.is_active
                readonly property bool urgent: modelData.is_urgent
                readonly property string label: root.labelFor(modelData)
                readonly property string glyph: root.showIcons ? root.iconFor(modelData) : ""
                readonly property color tint: ws.urgent ? Colors.error
                    : ws.focused ? root.colorFor(modelData, Colors.primary)
                    : ws.active ? Colors.barOnSurface
                    : Colors.alpha(Colors.barOnSurfaceVariant, 0.45)

                readonly property bool chip: root.style === "numbers"
                                             || ws.glyph !== ""
                                             || (root.showLabels && ws.focused)

                implicitWidth: chip ? Math.max(18, chipRow.implicitWidth + Appearance.space.s)
                               : (root.style === "dots" ? 8
                                  : (ws.focused ? 26 : ws.active ? 12 : 7))
                implicitHeight: chip ? Math.max(18, Appearance.barIconSize + 2)
                                : (root.style === "dots" ? 8 : 7)

                Behavior on implicitWidth {
                    SpringAnimation {
                        spring: Motion.spatial.spring; damping: Motion.spatial.damping
                        mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: ws.chip
                           ? (ws.focused ? ws.tint : Colors.alpha(ws.tint, 0.16))
                           : ws.tint
                    Behavior on color {
                        ColorAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard }
                    }
                }

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    visible: ws.chip
                    spacing: 3

                    MIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: ws.glyph !== ""
                        name: ws.glyph
                        size: Math.max(12, Appearance.barIconSize - 4)
                        fill: ws.focused ? 1 : 0
                        color: ws.focused ? Colors.on.primary : ws.tint
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: ws.glyph === "" || (root.showLabels && ws.focused)
                        text: ws.label
                        color: ws.focused ? Colors.on.primary : ws.tint
                        font.family: Appearance.fontFamily
                        font.pixelSize: Math.max(9, Appearance.barFontSize - 2)
                        font.weight: Appearance.font.weightMedium
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Niri.focusWorkspace(ws.modelData.idx)
                }
            }
        }
    }
}
