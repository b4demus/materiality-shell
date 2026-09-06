import QtQuick
import "root:/config"

// Hairline between rows in a card.
Rectangle {
    property real inset: 0
    height: 1
    color: Colors.outlineVariant
    opacity: 0.6
    anchors.leftMargin: inset
}
