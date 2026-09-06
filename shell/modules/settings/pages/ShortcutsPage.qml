import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Shortcuts"
    subtitle: "Every keybind niri knows about, editable in place. Changes are written "
              + "straight into your config and take effect immediately."
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
            label: "New shortcut"
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

                        // the key combination, as caps
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
        }
    }

    // ---- editor ---------------------------------------------------------------
    MDialog {
        id: editor

        property var editing: null
        property string capturedKey: ""
        property bool capturing: false

        function begin(bind) {
            editing = bind
            capturedKey = bind ? bind.key : ""
            capturing = false
            actionField.text = bind ? bind.action : ""
            titleField.text = bind ? bind.title : ""
            open = true
        }

        // The recorder turns a real key press into niri's bind syntax.
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
            // Modifiers alone are not a shortcut.
            const skip = [Qt.Key_Control, Qt.Key_Shift, Qt.Key_Alt, Qt.Key_Meta,
                          Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr]
            if (skip.indexOf(code) >= 0) return ""

            const named = {}
            named[Qt.Key_Return] = "Return"
            named[Qt.Key_Enter] = "Return"
            named[Qt.Key_Space] = "Space"
            named[Qt.Key_Tab] = "Tab"
            named[Qt.Key_Escape] = "Escape"
            named[Qt.Key_Backspace] = "BackSpace"
            named[Qt.Key_Delete] = "Delete"
            named[Qt.Key_Home] = "Home"
            named[Qt.Key_End] = "End"
            named[Qt.Key_PageUp] = "Page_Up"
            named[Qt.Key_PageDown] = "Page_Down"
            named[Qt.Key_Left] = "Left"
            named[Qt.Key_Right] = "Right"
            named[Qt.Key_Up] = "Up"
            named[Qt.Key_Down] = "Down"
            named[Qt.Key_Slash] = "Slash"
            named[Qt.Key_Backslash] = "Backslash"
            named[Qt.Key_Comma] = "Comma"
            named[Qt.Key_Period] = "Period"
            named[Qt.Key_Minus] = "Minus"
            named[Qt.Key_Equal] = "Equal"
            named[Qt.Key_Semicolon] = "Semicolon"
            named[Qt.Key_Apostrophe] = "Apostrophe"
            named[Qt.Key_BracketLeft] = "BracketLeft"
            named[Qt.Key_BracketRight] = "BracketRight"
            named[Qt.Key_QuoteLeft] = "Grave"
            if (named[code]) return named[code]

            if (code >= Qt.Key_F1 && code <= Qt.Key_F12)
                return "F" + (code - Qt.Key_F1 + 1)
            if (code >= Qt.Key_A && code <= Qt.Key_Z)
                return String.fromCharCode(code)
            if (code >= Qt.Key_0 && code <= Qt.Key_9)
                return String.fromCharCode(code)
            return ""
        }

        readonly property var conflict: capturedKey
            ? Shortcuts.conflicts(capturedKey, editing ? editing.key : "") : null

        title: editing ? "Edit shortcut" : "New shortcut"
        icon: "keyboard_command_key"
        confirmText: "Save"
        confirmEnabled: capturedKey.length > 0 && actionField.text.trim().length > 0
        dialogWidth: 520

        Column {
            width: parent.width
            spacing: Appearance.space.m

            // key recorder
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
                                                    : "Click, then press a key combination")
                        color: editor.capturing ? Colors.on.primaryContainer : Colors.on.surfaceVariant
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.bodySmall
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        editor.capturing = true
                        keyCatcher.forceActiveFocus()
                    }
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
                text: `Already used by: ${Shortcuts.describe(editor.conflict || {})} — `
                    + "saving will replace it."
                wrapMode: Text.WordWrap
                color: Colors.error
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodySmall
            }

            MTextField {
                id: actionField
                width: parent.width
                label: "Action"
                placeholder: 'spawn "alacritty"'
            }

            Text {
                width: parent.width
                text: "Use a niri action (close-window, focus-column-left, …) or "
                    + 'spawn "program" "arg". For a shell one-liner use spawn-sh "…".'
                wrapMode: Text.WordWrap
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelSmall
            }

            Flow {
                width: parent.width
                spacing: Appearance.space.s

                Repeater {
                    model: [
                        { label: "Terminal", action: 'spawn "' + Settings.val("apps.terminal", "alacritty") + '"' },
                        { label: "Launcher", action: 'spawn "qs" "-c" "expressive" "ipc" "call" "launcher" "toggle"' },
                        { label: "Quick settings", action: 'spawn "qs" "-c" "expressive" "ipc" "call" "controlCenter" "toggle"' },
                        { label: "Settings", action: 'spawn "expressive-settings"' },
                        { label: "Close window", action: "close-window" },
                        { label: "Fullscreen", action: "fullscreen-window" },
                        { label: "Float", action: "toggle-window-floating" },
                        { label: "Screenshot", action: "screenshot" },
                        { label: "Overview", action: "toggle-overview" }
                    ]
                    delegate: MChip {
                        required property var modelData
                        label: modelData.label
                        showCheck: false
                        onClicked: {
                            actionField.text = modelData.action
                            if (!titleField.text) titleField.text = modelData.label
                        }
                    }
                }
            }

            MTextField {
                id: titleField
                width: parent.width
                label: "Description (shown in the hotkey overlay)"
            }

            MButton {
                visible: editor.editing !== null
                label: "Delete this shortcut"
                icon: "delete"
                fg: Colors.error
                hpad: Appearance.space.l
                onClicked: {
                    Shortcuts.remove(editor.editing.key)
                    editor.open = false
                }
            }
        }

        onConfirmed: {
            Shortcuts.rebind(editing ? editing.key : "", capturedKey,
                             actionField.text.trim(), titleField.text.trim(),
                             editing ? editing.props : "")
            editing = null
        }
        onCancelled: { editing = null; capturing = false }
    }
}
