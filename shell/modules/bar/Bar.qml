import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/components"
import "root:/services"

// ---------------------------------------------------------------------------
// The bar. Its edge, thickness, shape and contents all come from the settings
// store, so the Bar page in the settings app is not a mock-up of the bar — it
// is the bar's only configuration.
//
// A horizontal bar lays its three module groups out left / centre / right; a
// vertical one uses top / middle / bottom with the same three lists.
// ---------------------------------------------------------------------------
PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    readonly property string outputName: screen ? screen.name : ""

    readonly property string pos: Appearance.barPosition
    readonly property bool vertical: Appearance.barVertical
    readonly property int thickness: Appearance.barHeight
    readonly property int margin: Appearance.barMargin

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "expressive-bar"
    color: "transparent"

    // Anchor to the chosen edge, spanning the perpendicular axis.
    anchors {
        top: root.pos !== "bottom"
        bottom: root.pos !== "top"
        left: root.pos !== "right"
        right: root.pos !== "left"
    }

    // Only the dimension across the bar matters; the other is pinned by the
    // anchors above.
    implicitHeight: thickness + margin * 2
    implicitWidth: thickness + margin * 2

    // Reserve the strip so niri lays windows out beside the bar instead of
    // under it. This has to be ExclusionMode.Normal: the default Auto derives
    // the zone itself and ignores exclusiveZone.
    exclusionMode: ExclusionMode.Normal
    // The whole surface, both margins included, so a window can never tuck
    // under the floating bar's outer margin.
    exclusiveZone: thickness + margin * 2

    Rectangle {
        id: slab
        anchors.fill: parent
        anchors.margins: root.margin
        radius: Appearance.barRadius
        color: Colors.alpha(Colors.barSurface, 1.0 - Appearance.barTransparency)

        // A module that turns out wider than the bar must be cut off at the
        // bar's edge, never painted over the windows next to it.
        clip: true

        // Get out of the way the instant a window goes fullscreen — slide off
        // the near edge and fade, faster than niri's window grow so the bar is
        // gone before the window covers it.
        readonly property real _hideShift: root.thickness + root.margin * 2 + 6
        opacity: Niri.focusedFullscreen ? 0 : 1
        transform: Translate {
            x: !Niri.focusedFullscreen ? 0
               : root.pos === "left"  ? -slab._hideShift
               : root.pos === "right" ?  slab._hideShift : 0
            y: !Niri.focusedFullscreen ? 0
               : root.pos === "bottom" ?  slab._hideShift
               : root.pos === "top" || !root.vertical ? -slab._hideShift : 0
            Behavior on x { NumberAnimation { duration: 110; easing.type: Easing.InCubic } }
            Behavior on y { NumberAnimation { duration: 110; easing.type: Easing.InCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 90 } }

        Behavior on color { ColorAnimation { duration: Motion.durMedium } }
        Behavior on radius { NumberAnimation { duration: Motion.durMedium } }

        // ---- horizontal layout -------------------------------------------
        Item {
            id: hStrip
            anchors.fill: parent
            anchors.leftMargin: Appearance.barPad
            anchors.rightMargin: Appearance.barPad
            visible: !root.vertical

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Appearance.barGap

                Repeater {
                    model: Settings.val("bar.modules.left", [])
                    delegate: BarModule {
                        required property string modelData
                        moduleId: modelData
                        bar: root
                        outputName: root.outputName
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Appearance.barGap

                Repeater {
                    model: Settings.val("bar.modules.center", [])
                    delegate: BarModule {
                        required property string modelData
                        moduleId: modelData
                        bar: root
                        outputName: root.outputName
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Appearance.barGap

                Repeater {
                    model: Settings.val("bar.modules.right", [])
                    delegate: BarModule {
                        required property string modelData
                        moduleId: modelData
                        bar: root
                        outputName: root.outputName
                    }
                }
            }
        }

        // ---- vertical layout ---------------------------------------------
        Item {
            id: vStrip
            anchors.fill: parent
            anchors.topMargin: Appearance.barPad
            anchors.bottomMargin: Appearance.barPad
            visible: root.vertical

            Column {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                spacing: Appearance.barGap

                Repeater {
                    model: Settings.val("bar.modules.left", [])
                    delegate: BarModule {
                        required property string modelData
                        moduleId: modelData
                        bar: root
                        outputName: root.outputName
                        inColumn: true
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                spacing: Appearance.barGap

                Repeater {
                    model: Settings.val("bar.modules.center", [])
                    delegate: BarModule {
                        required property string modelData
                        moduleId: modelData
                        bar: root
                        outputName: root.outputName
                        inColumn: true
                    }
                }
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                spacing: Appearance.barGap

                Repeater {
                    model: Settings.val("bar.modules.right", [])
                    delegate: BarModule {
                        required property string modelData
                        moduleId: modelData
                        bar: root
                        outputName: root.outputName
                        inColumn: true
                    }
                }
            }
        }
    }
}
