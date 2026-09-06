import QtQuick
import Quickshell
import Quickshell.Widgets
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Shortcuts"
    subtitle: "Add a shortcut for any app: press the keys, type its name, done. "
              + "Everything is written straight into your niri config and works right away."
    maxWidth: 940

    property string group: "all"
    property string query: ""

    readonly property var filtered: {
        const q = query.trim().toLowerCase()
        return Shortcuts.binds.filter(b => {
            if (group !== "all" && Shortcuts.groupOf(b.action) !== group) return false
            if (!q) return true
            return String(b.key).toLowerCase().indexOf(q) >= 0
                   || String(b.action).toLowerCase().indexOf(q) >= 0
                   || Shortcuts.describe(b).toLowerCase().indexOf(q) >= 0
        })
    }

    headerActions: [
        MButton {
            icon: "add"
            label: "Add shortcut"
            bg: Colors.primaryContainer
            fg: Colors.on.primaryContainer
            hpad: Appearance.space.l
            onClicked: editor.begin(null)
        }
    ]

    // ---- filters ------------------------------------------------------------
    Column {
        width: parent.width
        spacing: Appearance.space.m

        MTextField {
            width: parent.width
            label: "Search shortcuts"
            leadingIcon: "search"
            onEdited: t => page.query = t
        }

        Flow {
            width: parent.width
            spacing: Appearance.space.s

            MChip {
                label: `All (${Shortcuts.binds.length})`
                selected: page.group === "all"
                onClicked: page.group = "all"
            }
            Repeater {
                model: Shortcuts.groups
                delegate: MChip {
                    required property var modelData
                    label: modelData.label
                    icon: modelData.icon
                    selected: page.group === modelData.id
                    onClicked: page.group = modelData.id
                }
            }
        }
    }

    // ---- the list -----------------------------------------------------------
    MSection {
        width: parent.width
        title: ""

        Repeater {
            model: page.filtered

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    minHeight: 60
                    title: Shortcuts.describe(modelData)
                    subtitle: modelData.action
                    clickable: true
                    onClicked: editor.begin(modelData)

                    Row {
                        spacing: Appearance.space.xs

                        Repeater {
                            model: Shortcuts.keyChips(modelData.key)
                            delegate: Rectangle {
                                required property string modelData
                                anchors.verticalCenter: parent.verticalCenter
                                height: 28
                                width: Math.max(28, keyLabel.implicitWidth + Appearance.space.m)
                                radius: Appearance.radius.xs
                                color: Colors.surfaceContainerHighest
                                border.width: 1
                                border.color: Colors.outlineVariant

                                Text {
                                    id: keyLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: Colors.on.surface
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.font.labelMedium
                                    font.weight: Appearance.font.weightMedium
                                }
                            }
                        }

                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "edit"
                            size: 18
                            color: Colors.on.surfaceVariant
                        }
                    }
                }

                MDivider { width: parent.width; visible: index < page.filtered.length - 1 }
            }
        }

        MEmptyState {
            width: parent.width
            visible: page.filtered.length === 0
            icon: "keyboard_command_key"
            title: Shortcuts.loaded ? "No shortcuts match" : "Reading your config…"
            message: Shortcuts.loaded
                     ? "Try a different filter, or add a new shortcut."
                     : ""
            actionLabel: Shortcuts.loaded ? "Add shortcut" : ""
            onActionClicked: editor.begin(null)
        }
    }

    // ---- editor ---------------------------------------------------------------
    MDialog {
        id: editor

        property var editing: null
        property string mode: "app"          // "app" | "action"
        property string capturedKey: ""
        property bool capturing: false
        property var chosenCmd: null          // argv array when an app was picked
        property bool runInShell: false

        function begin(bind) {
            editing = bind
            capturing = false
            chosenCmd = null
            runInShell = false
            capturedKey = bind ? bind.key : ""
            actionField.text = ""
            appField.text = ""
            titleField.text = bind ? (bind.title || "") : ""
            sugg.q = ""

            if (bind) {
                const a = String(bind.action || "")
                let m = a.match(/^spawn-sh\s+"([\s\S]*)"$/)
                if (m) { mode = "app"; runInShell = true; appField.text = m[1].replace(/\\"/g, '"') }
                else if (a.indexOf("spawn ") === 0) {
                    mode = "app"
                    const parts = a.match(/"([^"]*)"/g) || []
                    appField.text = parts.map(p => p.replace(/"/g, "")).join(" ")
                } else {
                    mode = "action"
                    actionField.text = a
                }
            } else {
                mode = "app"
            }
            open = true
        }

        function quote(s) { return '"' + String(s).replace(/"/g, '\\"') + '"' }

        function builtAction() {
            if (mode === "action") return actionField.text.trim()
            const raw = appField.text.trim()
            if (!raw) return ""
            if (runInShell) return "spawn-sh " + quote(raw)
            if (chosenCmd && chosenCmd.length) return "spawn " + chosenCmd.map(quote).join(" ")
            return "spawn " + raw.split(/\s+/).map(quote).join(" ")
        }

        function builtTitle() {
            const t = titleField.text.trim()
            if (t) return t
            if (mode === "app") {
                const raw = appField.text.trim()
                return raw ? (raw.split(/[\s/]+/).pop() || raw) : ""
            }
            return ""
        }

        // --- key recorder ---------------------------------------------------
        function record(event) {
            const mods = []
            if (event.modifiers & Qt.MetaModifier) mods.push("Mod")
            if (event.modifiers & Qt.ControlModifier) mods.push("Ctrl")
            if (event.modifiers & Qt.AltModifier) mods.push("Alt")
            if (event.modifiers & Qt.ShiftModifier) mods.push("Shift")
            const name = keyName(event.key)
            if (!name) return false
            capturedKey = mods.concat([name]).join("+")
            capturing = false
            return true
        }

        function keyName(code) {
            const skip = [Qt.Key_Control, Qt.Key_Shift, Qt.Key_Alt, Qt.Key_Meta,
                          Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr]
            if (skip.indexOf(code) >= 0) return ""
            const named = {}
            named[Qt.Key_Return] = "Return";      named[Qt.Key_Enter] = "Return"
            named[Qt.Key_Space] = "Space";        named[Qt.Key_Tab] = "Tab"
            named[Qt.Key_Escape] = "Escape";      named[Qt.Key_Backspace] = "BackSpace"
            named[Qt.Key_Delete] = "Delete";      named[Qt.Key_Home] = "Home"
            named[Qt.Key_End] = "End";            named[Qt.Key_PageUp] = "Page_Up"
            named[Qt.Key_PageDown] = "Page_Down"; named[Qt.Key_Left] = "Left"
            named[Qt.Key_Right] = "Right";        named[Qt.Key_Up] = "Up"
            named[Qt.Key_Down] = "Down";          named[Qt.Key_Slash] = "Slash"
            named[Qt.Key_Backslash] = "Backslash";named[Qt.Key_Comma] = "Comma"
            named[Qt.Key_Period] = "Period";      named[Qt.Key_Minus] = "Minus"
            named[Qt.Key_Equal] = "Equal";       named[Qt.Key_Semicolon] = "Semicolon"
            named[Qt.Key_Apostrophe] = "Apostrophe"
            named[Qt.Key_BracketLeft] = "BracketLeft"
            named[Qt.Key_BracketRight] = "BracketRight"
            named[Qt.Key_QuoteLeft] = "Grave"
            if (named[code]) return named[code]
            if (code >= Qt.Key_F1 && code <= Qt.Key_F12) return "F" + (code - Qt.Key_F1 + 1)
            if (code >= Qt.Key_A && code <= Qt.Key_Z) return String.fromCharCode(code)
            if (code >= Qt.Key_0 && code <= Qt.Key_9) return String.fromCharCode(code)
            return ""
        }

        readonly property var conflict: capturedKey
            ? Shortcuts.conflicts(capturedKey, editing ? editing.key : "") : null

        title: editing ? "Edit shortcut" : "Add shortcut"
        icon: "keyboard_command_key"
        confirmText: "Save"
        confirmEnabled: capturedKey.length > 0
                        && (mode === "action" ? actionField.text.trim().length > 0
                                              : appField.text.trim().length > 0)
        dialogWidth: 540

        Column {
            width: parent.width
            spacing: Appearance.space.m

            MSegmented {
                width: parent.width
                model: [
                    { label: "Application", value: "app" },
                    { label: "niri action", value: "action" }
                ]
                value: editor.mode
                onPicked: v => editor.mode = v
            }

            // --- step 1: the keys --------------------------------------------
            Text {
                text: "1  ·  Shortcut"
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelMedium
                font.weight: Appearance.font.weightMedium
            }

            Rectangle {
                width: parent.width
                height: 76
                radius: Appearance.radius.m
                color: editor.capturing ? Colors.primaryContainer : Colors.surfaceContainerHighest
                border.width: editor.capturing ? 2 : 1
                border.color: editor.capturing ? Colors.primary : Colors.outlineVariant
                Behavior on color { ColorAnimation { duration: Motion.durShort } }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Appearance.space.xs
                        visible: editor.capturedKey.length > 0 && !editor.capturing

                        Repeater {
                            model: editor.capturedKey ? Shortcuts.keyChips(editor.capturedKey) : []
                            delegate: Rectangle {
                                required property string modelData
                                height: 30
                                width: Math.max(30, capLabel.implicitWidth + Appearance.space.m)
                                radius: Appearance.radius.xs
                                color: Colors.surfaceContainer
                                Text {
                                    id: capLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: Colors.on.surface
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.font.labelLarge
                                    font.weight: Appearance.font.weightMedium
                                }
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: editor.capturing ? "Press the keys now…"
                              : (editor.capturedKey ? "Click to record a different combination"
                                                    : "Click here, then press a key combination")
                        color: editor.capturing ? Colors.on.primaryContainer : Colors.on.surfaceVariant
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.bodySmall
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { editor.capturing = true; keyCatcher.forceActiveFocus() }
                }

                Item {
                    id: keyCatcher
                    focus: editor.capturing
                    Keys.onPressed: event => {
                        if (!editor.capturing) return
                        event.accepted = true
                        if (event.key === Qt.Key_Escape) { editor.capturing = false; return }
                        editor.record(event)
                    }
                }
            }

            Text {
                width: parent.width
                visible: editor.conflict !== null
                text: `${Shortcuts.keyChips(editor.capturedKey).join(" + ")} is already `
                    + `"${Shortcuts.describe(editor.conflict || {})}" — saving replaces it.`
                wrapMode: Text.WordWrap
                color: Colors.error
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodySmall
            }

            // --- step 2 (app mode): the program ----------------------------
            Column {
                width: parent.width
                spacing: Appearance.space.s
                visible: editor.mode === "app"

                Text {
                    text: "2  ·  Application"
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.labelMedium
                    font.weight: Appearance.font.weightMedium
                }

                MTextField {
                    id: appField
                    width: parent.width
                    label: "App name or command"
                    placeholder: "firefox"
                    leadingIcon: "apps"
                    onEdited: t => { editor.chosenCmd = null; sugg.q = t }
                }

                // live suggestions from the installed .desktop apps
                Rectangle {
                    width: parent.width
                    visible: sugg.shouldShow
                    height: visible ? suggCol.implicitHeight + Appearance.space.s * 2 : 0
                    radius: Appearance.radius.m
                    color: Colors.surfaceContainerHighest

                    Column {
                        id: suggCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Appearance.space.s
                        spacing: 2

                        Repeater {
                            model: sugg.list
                            delegate: Rectangle {
                                required property var modelData
                                width: suggCol.width
                                height: 40
                                radius: Appearance.radius.s
                                color: sma.containsMouse ? Colors.surfaceContainer : "transparent"

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Appearance.space.s
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Appearance.space.s

                                    IconImage {
                                        anchors.verticalCenter: parent.verticalCenter
                                        implicitSize: 24
                                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        color: Colors.on.surface
                                        font.family: Appearance.fontFamily
                                        font.pixelSize: Appearance.font.bodyMedium
                                    }
                                }

                                MouseArea {
                                    id: sma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        appField.text = modelData.name
                                        editor.chosenCmd = modelData.command
                                        sugg.q = ""
                                    }
                                }
                            }
                        }
                    }
                }

                // filter state — an Item so it can hold JS props / functions
                Item {
                    id: sugg
                    property string q: ""
                    readonly property var list: {
                        const s = q.trim().toLowerCase()
                        if (s.length < 1) return []
                        return Apps.visibleApps.filter(a =>
                            String(a.name).toLowerCase().indexOf(s) >= 0
                            || String(a.id).toLowerCase().indexOf(s) >= 0
                            || String(a.execString).toLowerCase().indexOf(s) >= 0
                        ).slice(0, 6)
                    }
                    readonly property bool exact: list.length >= 1
                        && String(list[0].name).toLowerCase() === q.trim().toLowerCase()
                    readonly property bool shouldShow: q.trim().length > 0 && list.length > 0 && !exact
                }

                MRow {
                    width: parent.width
                    minHeight: 48
                    icon: "terminal"
                    title: "Run in a shell"
                    subtitle: "for pipes, env vars or several commands at once"

                    MSwitch {
                        checked: editor.runInShell
                        onToggled: c => editor.runInShell = c
                    }
                }
            }

            // --- step 2 (action mode): a niri action ----------------------
            Column {
                width: parent.width
                spacing: Appearance.space.s
                visible: editor.mode === "action"

                Text {
                    text: "2  ·  niri action"
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.labelMedium
                    font.weight: Appearance.font.weightMedium
                }

                MTextField {
                    id: actionField
                    width: parent.width
                    label: "Action"
                    placeholder: "close-window"
                }

                Flow {
                    width: parent.width
                    spacing: Appearance.space.s

                    Repeater {
                        model: [
                            "close-window", "fullscreen-window", "maximize-column",
                            "toggle-window-floating", "center-column",
                            "focus-column-left", "focus-column-right",
                            "focus-workspace-down", "focus-workspace-up",
                            "toggle-overview", "screenshot", "screenshot-screen",
                            "power-off-monitors", "quit"
                        ]
                        delegate: MChip {
                            required property string modelData
                            label: modelData
                            showCheck: false
                            onClicked: actionField.text = modelData
                        }
                    }
                }
            }

            // --- preview of exactly what gets written ---------------------
            Rectangle {
                width: parent.width
                visible: editor.builtAction().length > 0
                height: visible ? prev.implicitHeight + Appearance.space.m * 2 : 0
                radius: Appearance.radius.s
                color: Colors.surfaceContainerLow

                Text {
                    id: prev
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.space.m
                    text: (editor.capturedKey
                           ? Shortcuts.keyChips(editor.capturedKey).join(" + ") + "   →   "
                           : "") + editor.builtAction()
                    wrapMode: Text.WrapAnywhere
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.monoFamily
                    font.pixelSize: Appearance.font.bodySmall
                }
            }

            MTextField {
                id: titleField
                width: parent.width
                label: "Label (optional)"
                placeholder: editor.mode === "app" ? "shown in the shortcuts list" : ""
            }

            MButton {
                visible: editor.editing !== null
                label: "Delete this shortcut"
                icon: "delete"
                fg: Colors.error
                hpad: Appearance.space.l
                onClicked: { Shortcuts.remove(editor.editing.key); editor.open = false }
            }
        }

        onConfirmed: {
            Shortcuts.rebind(editing ? editing.key : "", capturedKey,
                             builtAction(), builtTitle(),
                             editing ? editing.props : "")
            editing = null
        }
        onCancelled: { editing = null; capturing = false }
    }
}
