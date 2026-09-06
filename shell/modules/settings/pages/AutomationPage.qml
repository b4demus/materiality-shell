import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Automation"
    subtitle: "Switch profiles by themselves when something about the machine changes. "
              + "Rules are checked every 15 seconds; the first one that matches wins."
    maxWidth: 900

    readonly property var rules: Settings.val("automation.rules", [])

    function updateRule(id, changes) {
        const next = rules.slice()
        for (let i = 0; i < next.length; i++)
            if (next[i].id === id) next[i] = Object.assign({}, next[i], changes)
        Settings.set("automation.rules", next)
    }
    function removeRule(id) {
        Settings.set("automation.rules", rules.filter(r => r.id !== id))
    }
    function addRule() {
        const next = rules.slice()
        next.push({
            id: "r" + Date.now().toString(36),
            enabled: true,
            when: { type: "app", value: "" },
            profile: Profiles.list.length > 0 ? Profiles.list[0].id : ""
        })
        Settings.set("automation.rules", next)
    }

    function conditionInfo(type) {
        for (const c of Profiles.conditionTypes) if (c.value === type) return c
        return Profiles.conditionTypes[0]
    }

    headerActions: [
        MButton {
            icon: "add"
            label: "New rule"
            bg: Colors.primaryContainer
            fg: Colors.on.primaryContainer
            hpad: Appearance.space.l
            enabled: Profiles.list.length > 0
            onClicked: page.addRule()
        }
    ]

    MSection {
        width: parent.width
        title: "Automation"
        icon: "auto_awesome"

        MRow {
            width: parent.width
            icon: Profiles.automationOn ? "auto_awesome" : "auto_awesome_motion"
            title: "Switch profiles automatically"
            subtitle: Profiles.automationOn
                      ? (Profiles.activeId
                         ? `Currently on “${(Profiles.byId(Profiles.activeId) || {}).name || "?"}”`
                         : "No rule matches right now")
                      : "Off"
            enabledRow: Profiles.list.length > 0

            MSwitch {
                checked: Profiles.automationOn
                enabledSwitch: Profiles.list.length > 0
                onToggled: c => Settings.set("automation.enabled", c)
            }
        }
    }

    MEmptyState {
        width: parent.width
        visible: Profiles.list.length === 0
        icon: "tune"
        title: "Create a profile first"
        message: "Automation switches between profiles, so there needs to be at least one."
        actionLabel: "Go to profiles"
        onActionClicked: Bus.settingsPage = "profiles"
    }

    MSection {
        width: parent.width
        visible: Profiles.list.length > 0
        title: "Rules"
        icon: "rule"
        description: "Rules are evaluated top to bottom."

        Repeater {
            model: page.rules

            delegate: Rectangle {
                id: ruleCard
                required property var modelData
                readonly property bool matching: Profiles.ruleMatches(modelData)

                width: parent.width
                implicitHeight: ruleCol.implicitHeight + Appearance.space.l * 2
                radius: Appearance.radius.m
                color: matching && Profiles.automationOn
                       ? Colors.secondaryContainer : Colors.surfaceContainerHighest

                Behavior on color { ColorAnimation { duration: Motion.durMedium } }

                Column {
                    id: ruleCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Appearance.space.l
                    spacing: Appearance.space.m

                    Row {
                        width: parent.width
                        spacing: Appearance.space.m

                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: page.conditionInfo(ruleCard.modelData.when.type).icon
                            size: 22
                            color: ruleCard.matching ? Colors.primary : Colors.on.surfaceVariant
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 22 - 120 - Appearance.space.m * 2
                            elide: Text.ElideRight
                            text: ruleCard.matching ? "Matching now" : "Not matching"
                            color: ruleCard.matching ? Colors.primary : Colors.on.surfaceVariant
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.labelLarge
                            font.weight: Appearance.font.weightMedium
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Appearance.space.s

                            MSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: ruleCard.modelData.enabled
                                onToggled: c => page.updateRule(ruleCard.modelData.id, { enabled: c })
                            }
                            MButton {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "delete"
                                iconSize: 18
                                fg: Colors.error
                                onClicked: page.removeRule(ruleCard.modelData.id)
                            }
                        }
                    }

                    MDivider { width: parent.width }

                    // when …
                    Row {
                        width: parent.width
                        spacing: Appearance.space.m

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40
                            text: "When"
                            color: Colors.on.surfaceVariant
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.bodyMedium
                        }
                        MSelect {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 260
                            model: Profiles.conditionTypes.map(c => ({
                                value: c.value, label: c.label, icon: c.icon }))
                            value: ruleCard.modelData.when.type
                            onPicked: v => page.updateRule(ruleCard.modelData.id,
                                                           { when: { type: v, value: "" } })
                        }
                        MTextField {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: ["app", "output", "battery", "time", "bluetooth"]
                                     .indexOf(ruleCard.modelData.when.type) >= 0
                            width: parent.width - 40 - 260 - Appearance.space.m * 2
                            label: page.conditionInfo(ruleCard.modelData.when.type).hint
                            text: ruleCard.modelData.when.value || ""
                            onEdited: t => page.updateRule(ruleCard.modelData.id, {
                                when: { type: ruleCard.modelData.when.type, value: t } })
                        }
                    }

                    // … then
                    Row {
                        width: parent.width
                        spacing: Appearance.space.m

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40
                            text: "Use"
                            color: Colors.on.surfaceVariant
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.bodyMedium
                        }
                        MSelect {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 260
                            model: Profiles.list.map(p => ({ value: p.id, label: p.name,
                                                             icon: p.icon || "tune" }))
                            value: ruleCard.modelData.profile
                            onPicked: v => page.updateRule(ruleCard.modelData.id, { profile: v })
                        }
                    }
                }
            }
        }

        MEmptyState {
            width: parent.width
            visible: page.rules.length === 0
            icon: "rule"
            title: "No rules"
            message: "For example: when Steam is running, use the Gaming profile."
        }
    }
}
