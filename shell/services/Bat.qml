pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property bool present: dev && dev.isPresent
                                    && dev.type === UPowerDeviceType.Battery
                                    && dev.percentage > 0
    // Quickshell reports UPower percentage as a 0.0–1.0 fraction; the shell
    // works in 0–100 everywhere (labels, thresholds, icon steps).
    readonly property real percent: dev ? dev.percentage * 100 : 0
    readonly property int state: dev ? dev.state : UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
                                     || state === UPowerDeviceState.PendingCharge
    readonly property bool full: state === UPowerDeviceState.FullyCharged
    readonly property bool low: present && !charging && percent <= 20
    readonly property bool critical: present && !charging && percent <= 8

    // Material Symbols name for the current level/charge state.
    readonly property string icon: {
        if (!present) return "power"
        if (charging || full) return "battery_charging_full"
        const p = percent
        if (p >= 95) return "battery_full"
        if (p >= 85) return "battery_6_bar"
        if (p >= 70) return "battery_5_bar"
        if (p >= 55) return "battery_4_bar"
        if (p >= 40) return "battery_3_bar"
        if (p >= 25) return "battery_2_bar"
        if (p >= 12) return "battery_1_bar"
        return "battery_alert"
    }
}
