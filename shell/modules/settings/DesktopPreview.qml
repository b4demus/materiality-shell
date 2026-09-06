import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"

// ---------------------------------------------------------------------------
// A working miniature of the desktop, not a screenshot.
//
// It renders the same wallpaper, the same bar geometry and modules, niri's gaps
// and corner radius, the Material You palette and the night-light tint — all
// read from the same settings the real shell reads. Every value is multiplied
// by `s`, the ratio between this widget and the real output, so changing bar
// height by 2px moves the preview by 2 scaled pixels rather than by a guess.
// ---------------------------------------------------------------------------
Item {
    id: root

    // Which output we are portraying (drives aspect ratio + per-monitor paper).
    property string outputName: Displays.outputs.length > 0 ? Displays.outputs[0].name : ""
    property bool showQuickSettings: false
    property bool interactive: true

    readonly property var output: Displays.find(outputName)
    readonly property real refWidth: output && output.logical ? output.logical.width : 1920
    readonly property real refHeight: output && output.logical ? output.logical.height : 1080
    readonly property real aspect: refHeight > 0 ? refWidth / refHeight : 16 / 9

    // Scale factor from real logical pixels to preview pixels.
    readonly property real s: width / Math.max(1, refWidth)
    function px(v) { return Math.max(1, v * root.s) }

    implicitHeight: width / aspect

    // ---- geometry mirrored from the settings store -------------------------
    readonly property string barPos: Settings.val("bar.position", "top")
    readonly property bool barVertical: barPos === "left" || barPos === "right"
    readonly property bool barFloating: Settings.val("bar.floating", true)
    readonly property real barThickness: px(Settings.val("bar.height", 32))
    readonly property real barMargin: barFloating ? px(Settings.val("bar.margin", 6)) : 0
    readonly property real barRadius: barFloating ? px(Settings.val("bar.radius", 16)) : 0
    readonly property real barPadding: px(Settings.val("bar.padding", 14))
    readonly property real barGap: px(Settings.val("bar.moduleSpacing", 14))
    readonly property real gaps: px(Settings.val("niri.gapsInner", 8))
    readonly property real winRadius: px(Settings.val("niri.cornerRadius", 14))
    readonly property real ringWidth: px(Settings.val("niri.focusRingWidth", 3))
    readonly property bool ringOn: Settings.val("niri.focusRingEnabled", true)

    // The strip the bar occupies, so the window area can avoid it.
    readonly property real barSpace: barThickness + barMargin * 2

    clip: true

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.m
        color: Colors.background
        clip: true

        // ---- wallpaper -----------------------------------------------------
        Image {
            id: paper
            anchors.fill: parent
            source: Wallpaper.sourceFor(root.outputName)
            visible: status === Image.Ready
            fillMode: Wallpaper.fillModeFor()
            asynchronous: true
            cache: true
            sourceSize.width: 640

            opacity: 0
            onStatusChanged: if (status === Image.Ready) opacity = 1
            Behavior on opacity { NumberAnimation { duration: Motion.durLong } }
        }

        // Fallback ground when no wallpaper is set yet.
        Rectangle {
            anchors.fill: parent
            visible: !paper.visible
            gradient: Gradient {
                GradientStop { position: 0.0; color: Colors.surfaceContainerHigh }
                GradientStop { position: 1.0; color: Colors.surfaceContainerLowest }
            }
        }

        // ---- windows -------------------------------------------------------
        // Two columns laid out the way niri would, honouring gaps, the corner
        // radius and the focus ring.
        Item {
            id: windowArea
            anchors.fill: parent
            anchors.topMargin: root.barPos === "top" ? root.barSpace : root.gaps
            anchors.bottomMargin: root.barPos === "bottom" ? root.barSpace : root.gaps
            anchors.leftMargin: root.barPos === "left" ? root.barSpace : root.gaps
            anchors.rightMargin: root.barPos === "right" ? root.barSpace : root.gaps

            Row {
                anchors.fill: parent
                spacing: root.gaps

                // focused column
                Item {
                    width: (parent.width - root.gaps) * Settings.val("niri.defaultColumnWidth", 0.5)
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -root.ringWidth
                        visible: root.ringOn
                        radius: root.winRadius + root.ringWidth
                        color: Colors.primary
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: root.winRadius
                        color: Colors.surfaceContainerLowest
                        clip: true

                        // a hint of window chrome so it reads as a window
                        Column {
                            anchors.fill: parent
                            anchors.margins: root.px(14)
                            spacing: root.px(9)

                            Rectangle {
                                width: parent.width * 0.42; height: root.px(11)
                                radius: height / 2; color: Colors.primary
                            }
                            Repeater {
                                model: 5
                                delegate: Rectangle {
                                    required property int index
                                    width: parent.width * (index % 2 === 0 ? 0.9 : 0.66)
                                    height: root.px(6)
                                    radius: height / 2
                                    color: Colors.on.surfaceVariant
                                    opacity: 0.28
                                }
                            }
                        }
                    }
                }

                // second column
                Rectangle {
                    width: parent.width - (parent.width - root.gaps)
                           * Settings.val("niri.defaultColumnWidth", 0.5) - root.gaps
                    height: parent.height
                    radius: root.winRadius
                    color: Colors.surfaceContainerLow
                    clip: true

                    Column {
                        anchors.fill: parent
                        anchors.margins: root.px(14)
                        spacing: root.px(9)
                        Rectangle {
                            width: parent.width * 0.5; height: root.px(11)
                            radius: height / 2; color: Colors.tertiary; opacity: 0.8
                        }
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                required property int index
                                width: parent.width * (index % 2 === 0 ? 0.8 : 0.55)
                                height: root.px(6)
                                radius: height / 2
                                color: Colors.on.surfaceVariant
                                opacity: 0.22
                            }
                        }
                    }
                }
            }
        }

        // ---- the bar --------------------------------------------------------
        Rectangle {
            id: bar

            width: root.barVertical ? root.barThickness : parent.width - root.barMargin * 2
            height: root.barVertical ? parent.height - root.barMargin * 2 : root.barThickness
            radius: root.barRadius
            color: Colors.alpha(Colors.surface, 1.0 - Settings.val("bar.transparency", 0))

            x: root.barPos === "right" ? parent.width - width - root.barMargin : root.barMargin
            y: root.barPos === "bottom" ? parent.height - height - root.barMargin : root.barMargin

            Behavior on x {
                SpringAnimation {
                    spring: Motion.spatial.spring; damping: Motion.spatial.damping
                    mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
                }
            }
            Behavior on y {
                SpringAnimation {
                    spring: Motion.spatial.spring; damping: Motion.spatial.damping
                    mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
                }
            }
            Behavior on width { NumberAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }
            Behavior on height { NumberAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }
            Behavior on radius { NumberAnimation { duration: Motion.durMedium } }
            Behavior on color { ColorAnimation { duration: Motion.durMedium } }

            // Horizontal bar: three module groups, exactly as configured.
            Item {
                anchors.fill: parent
                anchors.leftMargin: root.barPadding
                anchors.rightMargin: root.barPadding
                visible: !root.barVertical

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.barGap
                    Repeater {
                        model: Settings.val("bar.modules.left", [])
                        delegate: PreviewModule { moduleId: modelData; scaleRef: root }
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.barGap
                    Repeater {
                        model: Settings.val("bar.modules.center", [])
                        delegate: PreviewModule { moduleId: modelData; scaleRef: root }
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.barGap
                    Repeater {
                        model: Settings.val("bar.modules.right", [])
                        delegate: PreviewModule { moduleId: modelData; scaleRef: root }
                    }
                }
            }

            // Vertical bar: the same groups stacked top / middle / bottom.
            Item {
                anchors.fill: parent
                anchors.topMargin: root.barPadding
                anchors.bottomMargin: root.barPadding
                visible: root.barVertical

                Column {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.barGap
                    Repeater {
                        model: Settings.val("bar.modules.left", [])
                        delegate: PreviewModule { moduleId: modelData; scaleRef: root; vertical: true }
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.barGap
                    Repeater {
                        model: Settings.val("bar.modules.center", [])
                        delegate: PreviewModule { moduleId: modelData; scaleRef: root; vertical: true }
                    }
                }
                Column {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.barGap
                    Repeater {
                        model: Settings.val("bar.modules.right", [])
                        delegate: PreviewModule { moduleId: modelData; scaleRef: root; vertical: true }
                    }
                }
            }
        }

        // ---- quick settings panel ------------------------------------------
        Rectangle {
            id: qs
            visible: root.showQuickSettings
            width: root.px(420)
            height: root.px(360)
            radius: root.px(28)
            color: Colors.surfaceContainer
            x: parent.width - width - root.barMargin - root.px(8)
            y: root.barPos === "top" ? root.barSpace + root.px(8)
                                     : root.barMargin + root.px(8)
            opacity: root.showQuickSettings ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

            Column {
                anchors.fill: parent
                anchors.margins: root.px(24)
                spacing: root.px(14)

                Rectangle {
                    width: parent.width * 0.45; height: root.px(16)
                    radius: height / 2; color: Colors.on.surface; opacity: 0.75
                }

                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: root.px(12)
                    rowSpacing: root.px(12)
                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            required property int index
                            width: (parent.width - root.px(12)) / 2
                            height: root.px(60)
                            radius: root.px(20)
                            color: index < 2 ? Colors.primary : Colors.surfaceContainerHighest
                        }
                    }
                }

                Repeater {
                    model: 2
                    delegate: Rectangle {
                        width: parent.width; height: root.px(16)
                        radius: height / 2
                        color: Colors.secondaryContainer
                        Rectangle {
                            width: parent.width * 0.62; height: parent.height
                            radius: height / 2; color: Colors.primary
                        }
                    }
                }
            }
        }

        // ---- night light tint ------------------------------------------------
        // Multiplied over the whole preview, matching what the gamma ramp does.
        Rectangle {
            anchors.fill: parent
            visible: Settings.val("nightLight.enabled", false)
                     && Settings.val("nightLight.schedule", "manual") !== "off"
            color: NightLight.tintFor(Settings.val("nightLight.temperature", 4000))
            opacity: 0.42
            Behavior on color { ColorAnimation { duration: Motion.durMedium } }
        }

        // ---- cursor ------------------------------------------------------
        MIcon {
            visible: root.interactive
            name: "arrow_selector_tool"
            size: Math.max(12, root.px(Settings.val("appearance.cursorSize", 24)))
            fill: 1
            color: "#FFFFFF"
            x: parent.width * 0.42
            y: parent.height * 0.55
            opacity: 0.85
        }
    }

    // Soft outline so the preview reads as a screen.
    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.m
        color: "transparent"
        border.width: 1
        border.color: Colors.outlineVariant
    }
}
