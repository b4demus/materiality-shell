import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Keyboard"
    subtitle: "Layouts, switching and key repeat. These are niri's xkb settings, so "
              + "they apply to every application."
    maxWidth: 900

    readonly property var layouts: String(Settings.val("input.keyboard.layouts", "us"))
                                   .split(",").map(s => s.trim()).filter(s => s.length > 0)

    readonly property var switchOptions: [
        { value: "",                     label: "No shortcut" },
        { value: "grp:alt_shift_toggle", label: "Alt + Shift" },
        { value: "grp:ctrl_shift_toggle", label: "Ctrl + Shift" },
        { value: "grp:win_space_toggle", label: "Super + Space" },
        { value: "grp:caps_toggle",      label: "Caps Lock" },
        { value: "grp:alt_space_toggle", label: "Alt + Space" }
    ]

    // The xkb options string carries several settings at once; these helpers
    // read and rewrite just the group-switch part without losing the rest.
    function optionList() {
        return String(Settings.val("input.keyboard.options", ""))
            .split(",").map(s => s.trim()).filter(s => s.length > 0)
    }
    function currentSwitch() {
        for (const o of optionList()) if (o.indexOf("grp:") === 0) return o
        return ""
    }
    function setSwitch(v) {
        const rest = optionList().filter(o => o.indexOf("grp:") !== 0)
        if (v) rest.push(v)
        Settings.set("input.keyboard.options", rest.join(","))
    }
    function hasOption(o) { return optionList().indexOf(o) >= 0 }
    function toggleOption(o) {
        const list = optionList()
        const i = list.indexOf(o)
        if (i >= 0) list.splice(i, 1)
        else list.push(o)
        Settings.set("input.keyboard.options", list.join(","))
    }

    function setLayouts(list) {
        Settings.set("input.keyboard.layouts", list.join(","))
    }

    // ---- live state ---------------------------------------------------------
    MCard {
        width: parent.width
        tone: Colors.surfaceContainerLow

        Row {
            width: parent.width
            spacing: Appearance.space.l

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 56; height: 56
                radius: Appearance.radius.m
                color: Colors.primaryContainer

                Text {
                    anchors.centerIn: parent
                    text: page.layouts.length > 0
                          ? page.layouts[Math.min(live.index, page.layouts.length - 1)].toUpperCase()
                          : "US"
                    color: Colors.on.primaryContainer
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.titleMedium
                    font.weight: Appearance.font.weightBold
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: live.names.length > 0
                          ? live.names[Math.min(live.index, live.names.length - 1)]
                          : "English (US)"
                    color: Colors.on.surface
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.titleMedium
                    font.weight: Appearance.font.weightMedium
                }
                Text {
                    text: live.names.length > 1
                          ? `Active layout · switch with ${page.switchLabel()}`
                          : "Only one layout configured"
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.bodySmall
                }
            }
        }

        // A simplified keyboard, purely to make the layout tangible.
        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: [
                    "` 1 2 3 4 5 6 7 8 9 0 - =",
                    "Q W E R T Y U I O P [ ]",
                    "A S D F G H J K L ; '",
                    "Z X C V B N M , . /"
                ]

                delegate: Row {
                    required property string modelData
                    required property int index
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    leftPadding: index * 8

                    Repeater {
                        model: modelData.split(" ")
                        delegate: Rectangle {
                            required property string modelData
                            width: 28; height: 28
                            radius: Appearance.radius.xs
                            color: Colors.surfaceContainerHighest

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData
                                color: Colors.on.surfaceVariant
                                font.family: Appearance.monoFamily
                                font.pixelSize: Appearance.font.labelMedium
                            }
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                topPadding: 4

                Rectangle {
                    width: 200; height: 22
                    radius: Appearance.radius.xs
                    color: Colors.secondaryContainer
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: Appearance.space.s
                text: "Physical key positions — the characters they produce follow the "
                    + "layout selected above."
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelSmall
            }
        }
    }

    function switchLabel() {
        for (const o of switchOptions) if (o.value === currentSwitch()) return o.label
        return currentSwitch() || "no shortcut"
    }

    // ---- layouts ------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Layouts"
        icon: "keyboard"
        description: "The first layout is the default. Order matters — the switch "
                   + "shortcut cycles through them."

        Repeater {
            model: page.layouts

            delegate: Column {
                required property string modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: index === 0 ? "star" : "language"
                    title: xkb.nameFor(modelData)
                    subtitle: modelData + (index === 0 ? " · default" : "")

                    Row {
                        spacing: Appearance.space.xs

                        MButton {
                            icon: "keyboard_arrow_up"
                            iconSize: 18
                            enabled: index > 0
                            opacity: index > 0 ? 1 : 0.3
                            onClicked: {
                                const l = page.layouts.slice()
                                const t = l[index]; l[index] = l[index - 1]; l[index - 1] = t
                                page.setLayouts(l)
                            }
                        }
                        MButton {
                            icon: "keyboard_arrow_down"
                            iconSize: 18
                            enabled: index < page.layouts.length - 1
                            opacity: index < page.layouts.length - 1 ? 1 : 0.3
                            onClicked: {
                                const l = page.layouts.slice()
                                const t = l[index]; l[index] = l[index + 1]; l[index + 1] = t
                                page.setLayouts(l)
                            }
                        }
                        MButton {
                            icon: "delete"
                            iconSize: 18
                            fg: Colors.error
                            enabled: page.layouts.length > 1
                            opacity: page.layouts.length > 1 ? 1 : 0.3
                            onClicked: page.setLayouts(page.layouts.filter((_, i) => i !== index))
                        }
                    }
                }

                MDivider { width: parent.width; visible: index < page.layouts.length - 1 }
            }
        }

        MButton {
            icon: "add"
            label: "Add layout"
            bg: Colors.primaryContainer
            fg: Colors.on.primaryContainer
            hpad: Appearance.space.l
            onClicked: addLayout.open = true
        }
    }

    // ---- switching ----------------------------------------------------------
    MSection {
        width: parent.width
        title: "Switching & modifiers"
        icon: "swap_horiz"

        MRow {
            width: parent.width
            icon: "keyboard_tab"
            title: "Switch layout with"
            enabledRow: page.layouts.length > 1

            MSelect {
                width: 220
                model: page.switchOptions
                value: page.currentSwitch()
                enabledSelect: page.layouts.length > 1
                onPicked: v => page.setSwitch(v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "keyboard_capslock"
            title: "Caps Lock acts as Ctrl"

            MSwitch {
                checked: page.hasOption("ctrl:nocaps")
                onToggled: c => page.toggleOption("ctrl:nocaps")
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "keyboard_alt"
            title: "Right Alt is Compose"
            subtitle: "Type accented characters with a compose sequence"

            MSwitch {
                checked: page.hasOption("compose:ralt")
                onToggled: c => page.toggleOption("compose:ralt")
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "pin"
            title: "Num Lock on at startup"
            badge: "restart"
            subtitle: "Takes effect the next time niri starts"

            MSwitch {
                checked: Settings.val("input.keyboard.numlockOnBoot", false)
                onToggled: c => Settings.set("input.keyboard.numlockOnBoot", c)
            }
        }
    }

    // ---- repeat -------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Key repeat"
        icon: "repeat"

        MSliderRow {
            width: parent.width
            icon: "timer"
            title: "Delay before repeating"
            from: 150; to: 1200; stepSize: 25; suffix: " ms"
            value: Settings.val("input.keyboard.repeatDelay", 600)
            onMoved: v => Settings.set("input.keyboard.repeatDelay", v)
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "speed"
            title: "Repeat rate"
            subtitle: "Characters per second while a key is held"
            from: 5; to: 80; stepSize: 1; suffix: "/s"
            value: Settings.val("input.keyboard.repeatRate", 25)
            onMoved: v => Settings.set("input.keyboard.repeatRate", v)
        }

        MDivider { width: parent.width }

        MTextField {
            width: parent.width
            label: "Try key repeat here"
            placeholder: "Hold a key…"
        }
    }

    // ---- helpers -------------------------------------------------------------
    QtObject {
        id: live
        property var names: []
        property int index: 0
    }

    Process {
        id: liveProc
        command: ["niri", "msg", "--json", "keyboard-layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    live.names = j.names || []
                    live.index = j.current_idx || 0
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 1500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: liveProc.running = true
    }

    // The xkb layout catalogue, read once from the X11 rules list.
    Item {
        id: xkb
        property var all: []

        function nameFor(code) {
            for (const l of all) if (l.value === code) return l.label
            return code
        }

        Process {
            running: true
            command: ["sh", "-c",
                "sed -n '/^! layout/,/^!/p' /usr/share/X11/xkb/rules/base.lst " +
                "| sed '1d;$d' | sed 's/^ *//' | awk 'NF{code=$1; $1=\"\"; sub(/^ +/,\"\"); " +
                "print code \"\\t\" $0}'"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const out = []
                    for (const line of text.trim().split("\n")) {
                        const p = line.split("\t")
                        if (p.length >= 2 && p[0]) out.push({ value: p[0], label: p[1] })
                    }
                    if (out.length > 0) xkb.all = out
                }
            }
        }
    }

    MDialog {
        id: addLayout
        title: "Add a keyboard layout"
        icon: "language"
        cancelText: "Done"
        confirmText: ""
        dialogWidth: 520

        MTextField {
            id: layoutSearch
            width: parent.width
            label: "Search layouts"
            leadingIcon: "search"
        }

        MScroll {
            width: parent.width
            height: 280
            contentHeight: resultCol.implicitHeight

            Column {
                id: resultCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: {
                        const q = layoutSearch.text.trim().toLowerCase()
                        const pool = xkb.all.filter(l => page.layouts.indexOf(l.value) < 0)
                        const hits = q
                            ? pool.filter(l => l.label.toLowerCase().indexOf(q) >= 0
                                               || l.value.indexOf(q) >= 0)
                            : pool
                        return hits.slice(0, 60)
                    }
                    delegate: MRow {
                        required property var modelData
                        width: resultCol.width
                        minHeight: 44
                        icon: "language"
                        title: modelData.label
                        subtitle: modelData.value
                        clickable: true
                        onClicked: page.setLayouts(page.layouts.concat([modelData.value]))
                    }
                }
            }
        }
    }
}
