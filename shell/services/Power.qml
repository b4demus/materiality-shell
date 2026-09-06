pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "root:/config"

// ---------------------------------------------------------------------------
// PowerManager — battery, power profiles, session actions and idle timeouts.
//
// Battery + profiles come from UPower / power-profiles-daemon over DBus.
// Idle timeouts are delegated to swayidle through `expressive-idle`, because
// neither niri nor this Quickshell build exposes an idle-notify binding.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    // ---- battery ---------------------------------------------------------
    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property bool hasBattery: dev && dev.isPresent
                                       && dev.type === UPowerDeviceType.Battery
    // Quickshell gives UPower percentages as 0.0–1.0 fractions; scale to 0–100
    // so the thresholds below and the Power page read right.
    readonly property real percent: dev ? dev.percentage * 100 : 0
    readonly property bool onBattery: UPower.onBattery
    readonly property bool charging: dev && (dev.state === UPowerDeviceState.Charging
                                             || dev.state === UPowerDeviceState.PendingCharge)
    readonly property real timeToEmpty: dev ? dev.timeToEmpty : 0
    readonly property real timeToFull: dev ? dev.timeToFull : 0
    readonly property real health: dev ? dev.healthPercentage * 100 : 0

    function humanTime(seconds) {
        if (!seconds || seconds <= 0) return ""
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        if (h > 0) return `${h} h ${m} min`
        return `${m} min`
    }

    readonly property string batteryDetail: {
        if (!hasBattery) return "No battery — running on AC"
        if (charging) {
            const t = humanTime(timeToFull)
            return t ? `Charging · ${t} until full` : "Charging"
        }
        const t = humanTime(timeToEmpty)
        return t ? `${t} remaining` : "On battery"
    }

    // ---- power profiles --------------------------------------------------
    readonly property bool profilesAvailable: PowerProfiles.hasPerformanceProfile
                                              || PowerProfiles.profile !== undefined
    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    readonly property int degradation: PowerProfiles.degradationReason

    readonly property var profileList: {
        const out = [
            { value: PowerProfile.PowerSaver,  name: "power-saver", label: "Power saver",
              icon: "energy_savings_leaf", hint: "Longest battery life, reduced performance" },
            { value: PowerProfile.Balanced,    name: "balanced", label: "Balanced",
              icon: "balance", hint: "The default trade-off" }
        ]
        if (hasPerformance)
            out.push({ value: PowerProfile.Performance, name: "performance", label: "Performance",
                       icon: "rocket_launch", hint: "Maximum speed, more heat and drain" })
        return out
    }

    function setProfile(v) {
        PowerProfiles.profile = v
        for (const p of profileList)
            if (p.value === v) Settings.set("power.profile", p.name)
    }

    // The name of the profile that is live right now, "" if we can't tell.
    function profileName() {
        for (const p of profileList) if (p.value === profile) return p.name
        return ""
    }

    // Apply a profile given by name ("balanced", …). This is what makes
    // `power.profile` work as a profile/automation field — a patch that sets it
    // has to actually reach power-profiles-daemon, not just sit in the store.
    function applyProfileName(name) {
        if (!name || name === profileName()) return
        for (const p of profileList)
            if (p.name === name) { PowerProfiles.profile = p.value; return }
    }

    function profileLabel() {
        for (const p of profileList) if (p.value === profile) return p.label
        return "Unknown"
    }

    // ---- session actions -------------------------------------------------
    function suspend()   { run(["systemctl", "suspend"]) }
    function hibernate() { run(["systemctl", "hibernate"]) }
    function reboot()    { run(["systemctl", "reboot"]) }
    function powerOff()  { run(["systemctl", "poweroff"]) }
    function logOut()    { run(["niri", "msg", "action", "quit", "-s"]) }
    function lock()      { Bus.locked = true }
    function blankScreen() { run(["niri", "msg", "action", "power-off-monitors"]) }

    function run(cmd) { actProc.command = cmd; actProc.running = true }

    Process { id: actProc }

    // ---- idle timeouts ---------------------------------------------------
    property bool idleAvailable: false
    property bool idleRunning: false
    property string idleHint: "sudo dnf install swayidle"

    readonly property var timeoutChoices: [
        { value: 0,    label: "Never" },
        { value: 60,   label: "1 minute" },
        { value: 120,  label: "2 minutes" },
        { value: 300,  label: "5 minutes" },
        { value: 600,  label: "10 minutes" },
        { value: 900,  label: "15 minutes" },
        { value: 1800, label: "30 minutes" },
        { value: 3600, label: "1 hour" }
    ]

    function timeoutLabel(secs) {
        for (const c of timeoutChoices) if (c.value === secs) return c.label
        if (!secs) return "Never"
        return secs >= 60 ? `${Math.round(secs / 60)} minutes` : `${secs} seconds`
    }

    function applyIdle() {
        if (!idleAvailable) return
        idleProc.command = [Files.bin("expressive-idle"), "apply",
                            JSON.stringify({
                                screenTimeoutSec: Settings.val("power.screenTimeoutSec", 0),
                                lockTimeoutSec: Settings.val("power.lockTimeoutSec", 0),
                                suspendTimeoutSec: Settings.val("power.suspendTimeoutSec", 0),
                                dimBeforeSleep: Settings.val("power.dimBeforeSleep", true)
                            })]
        idleProc.running = true
    }

    function refreshIdle() { idleStatus.running = true }

    Component.onCompleted: refreshIdle()

    Process {
        id: idleStatus
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text)
                    root.idleAvailable = !!s.available
                    root.idleRunning = !!s.running
                    if (s.installHint) root.idleHint = s.installHint
                } catch (e) { root.idleAvailable = false }
            }
        }
        Component.onCompleted: command = [Files.bin("expressive-idle"), "status"]
    }

    Process { id: idleProc; onExited: idleRecheck.restart() }
    Timer { id: idleRecheck; interval: 300; onTriggered: root.refreshIdle() }
    Timer { id: idleApply; interval: 400; onTriggered: root.applyIdle() }

    // ---- low battery watch ------------------------------------------------
    readonly property int lowThreshold: Settings.val("power.lowBatteryPercent", 15)
    property bool _warned: false

    onPercentChanged: {
        if (!hasBattery || charging) { _warned = false; return }
        if (percent <= lowThreshold && !_warned) {
            _warned = true
            const action = Settings.val("power.lowBatteryAction", "notify")
            if (action === "powersave") setProfile(PowerProfile.PowerSaver)
            else if (action === "suspend") suspend()
            root.lowBattery(percent)
        } else if (percent > lowThreshold + 5) {
            _warned = false
        }
    }

    signal lowBattery(real percent)

    Connections {
        target: Settings
        function onChanged(path, value) {
            const p = String(path)
            if (p.startsWith("power.") || p === "*") idleApply.restart()
            // A profile/automation patch that carries power.profile has to be
            // pushed to power-profiles-daemon; setProfile() mirrors the name
            // back here, and applyProfileName() no-ops when it already matches,
            // so this can't ping-pong.
            if (p === "power.profile" || p === "*")
                root.applyProfileName(Settings.val("power.profile", ""))
        }
    }
}
