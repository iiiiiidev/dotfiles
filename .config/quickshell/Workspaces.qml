import QtQuick
import Quickshell.Hyprland

Row {
    spacing: 4

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            required property var modelData

            visible: modelData.id > 0
            width: 24
            height: 24
            radius: 12
            anchors.verticalCenter: parent.verticalCenter

            color: modelData.focused ? Theme.mauve
                 : modelData.urgent ? Theme.red
                 : mouse.containsMouse ? Theme.surface1
                 : "transparent"

            Text {
                anchors.centerIn: parent
                text: modelData.name
                color: parent.modelData.focused ? Theme.crust
                     : parent.modelData.urgent ? Theme.crust
                     : Theme.subtext1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.bold: parent.modelData.focused
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: parent.modelData.activate()
            }
        }
    }
}
