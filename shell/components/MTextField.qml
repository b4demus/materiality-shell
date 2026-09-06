import QtQuick
import "root:/config"

// M3 filled text field with a floating label.
Item {
    id: root

    property string label: ""
    property string placeholder: ""
    property string text: ""
    property bool password: false
    property string leadingIcon: ""
    property string trailingIcon: ""
    property bool enabledField: true
    property string errorText: ""
    readonly property bool hasError: errorText.length > 0
    property alias input: field

    signal accepted(string text)
    signal edited(string text)
    signal trailingClicked()

    implicitHeight: 56 + (hasError ? 20 : 0)
    implicitWidth: 240

    Rectangle {
        id: box
        width: parent.width
        height: 56
        radius: Appearance.radius.s
        color: Colors.surfaceContainerHighest
        opacity: root.enabledField ? 1 : 0.5

        // Bottom rule thickens and takes the accent on focus, per M3 filled fields.
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: field.activeFocus ? 2 : 1
            color: root.hasError ? Colors.error
                   : field.activeFocus ? Colors.primary : Colors.outline
            Behavior on height { NumberAnimation { duration: Motion.durShort } }
            Behavior on color { ColorAnimation { duration: Motion.durShort } }
        }

        MIcon {
            id: lead
            visible: root.leadingIcon !== ""
            anchors.left: parent.left
            anchors.leftMargin: Appearance.space.m
            anchors.verticalCenter: parent.verticalCenter
            name: root.leadingIcon
            size: 20
            color: Colors.on.surfaceVariant
        }

        Text {
            id: floatLabel
            visible: root.label !== ""
            x: (root.leadingIcon !== "" ? lead.x + lead.width + Appearance.space.m
                                        : Appearance.space.m)
            y: (field.activeFocus || root.text.length > 0) ? 8 : (box.height - height) / 2
            text: root.label
            color: root.hasError ? Colors.error
                   : field.activeFocus ? Colors.primary : Colors.on.surfaceVariant
            font.family: Appearance.fontFamily
            font.pixelSize: (field.activeFocus || root.text.length > 0)
                            ? Appearance.font.labelSmall : Appearance.font.bodyLarge
            Behavior on y { NumberAnimation { duration: Motion.durShort; easing.type: Motion.easeStandard } }
            Behavior on font.pixelSize { NumberAnimation { duration: Motion.durShort } }
        }

        TextInput {
            id: field
            anchors.left: parent.left
            anchors.leftMargin: (root.leadingIcon !== "" ? lead.x + lead.width + Appearance.space.m
                                                         : Appearance.space.m)
            anchors.right: trail.visible ? trail.left : parent.right
            anchors.rightMargin: Appearance.space.m
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.label !== "" ? 10 : (box.height - height) / 2
            height: contentHeight
            enabled: root.enabledField
            text: root.text
            color: Colors.on.surface
            selectionColor: Colors.primary
            selectedTextColor: Colors.on.primary
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.bodyLarge
            echoMode: root.password ? TextInput.Password : TextInput.Normal
            clip: true
            selectByMouse: true

            onTextChanged: if (root.text !== text) { root.text = text; root.edited(text) }
            onAccepted: root.accepted(text)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: field.text.length === 0 && root.label === ""
                text: root.placeholder
                color: Colors.on.surfaceVariant
                font: field.font
            }
        }

        MIcon {
            id: trail
            visible: root.trailingIcon !== ""
            anchors.right: parent.right
            anchors.rightMargin: Appearance.space.m
            anchors.verticalCenter: parent.verticalCenter
            name: root.trailingIcon
            size: 20
            color: Colors.on.surfaceVariant

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: root.trailingClicked()
            }
        }
    }

    Text {
        anchors.top: box.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.leftMargin: Appearance.space.m
        visible: root.hasError
        text: root.errorText
        color: Colors.error
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.font.labelSmall
    }
}
