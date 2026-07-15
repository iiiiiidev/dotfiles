import Quickshell
import Quickshell.Wayland
import QtQuick

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        property var modelData
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }
        margins {
            top: 6
            left: 8
            right: 8
        }

        implicitHeight: 36
        color: "transparent"
        WlrLayershell.namespace: "quickshell-bar"

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.alpha(Theme.base, 0.85)
            border.color: Theme.surface0
            border.width: 1

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Workspaces {}
                ActiveWindow {}
            }

            ClockWidget {
                anchors.centerIn: parent
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                WeatherWidget {}
                VolumeWidget {}
                NotifButton {}
                TrayWidget { bar: bar }
            }
        }
    }
}
