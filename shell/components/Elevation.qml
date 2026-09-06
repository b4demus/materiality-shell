import QtQuick
import QtQuick.Effects
import "root:/config"

// Soft drop shadow for floating surfaces (overlays, cards).
// Usage:  Elevation { target: myCard; level: 3 }   (place as a sibling *before* the card)
MultiEffect {
    id: root

    property Item target
    property int level: 2      // 1..4

    source: target
    anchors.fill: target

    shadowEnabled: true
    shadowColor: Appearance.shadowColor
    shadowVerticalOffset: level * 2
    shadowHorizontalOffset: 0
    shadowBlur: Math.min(1.0, 0.35 + level * 0.18)
    autoPaddingEnabled: true
    opacity: 0.9
}
