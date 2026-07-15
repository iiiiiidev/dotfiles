import QtQuick
import Quickshell
import Quickshell.Hyprland

Text {
    id: root

    property bool expanded: false

    HyprlandFocusGrab {
        windows: [popup, root.QsWindow.window]
        active: root.expanded
        onCleared: root.expanded = false
    }

    text: Weather.glyph + " " + Weather.temp
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    anchors.verticalCenter: parent.verticalCenter

    MouseArea {
        anchors.fill: parent
        onClicked: root.expanded = !root.expanded
    }

    PopupWindow {
        id: popup

        anchor.item: root
        anchor.rect.x: root.width
        anchor.rect.y: root.height + 14
        anchor.gravity: Edges.Bottom | Edges.Left

        visible: root.expanded
        implicitWidth: 300
        implicitHeight: content.implicitHeight + 32
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Qt.alpha(Theme.base, 0.95)
            border.color: Theme.surface0
            border.width: 1

            Column {
                id: content

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 12

                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        width: parent.width - 60
                        text: Weather.location
                        color: Theme.lavender
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: Weather.fahrenheit ? "°F" : "°C"
                        color: unitMouse.containsMouse ? Theme.mauve : Theme.overlay0
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: unitMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Weather.fahrenheit = !Weather.fahrenheit
                        }
                    }

                    Text {
                        text: "󰑐"
                        color: refreshMouse.containsMouse ? Theme.mauve : Theme.overlay0
                        font.family: Theme.font
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Weather.reload()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    implicitHeight: currentRow.implicitHeight + 24
                    radius: 12
                    color: Qt.alpha(Theme.surface0, 0.5)

                    Row {
                        id: currentRow

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        spacing: 16

                        Text {
                            width: 64
                            text: Weather.glyph
                            color: Theme.yellow
                            font.family: Theme.font
                            font.pixelSize: 52
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: Weather.temp
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 34
                                font.bold: true
                            }

                            Text {
                                width: 150
                                text: Weather.condition
                                color: Theme.subtext0
                                font.family: Theme.font
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    implicitHeight: detailsRow.implicitHeight + 24
                    radius: 12
                    color: Qt.alpha(Theme.surface0, 0.5)

                    Row {
                        id: detailsRow

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width

                        Repeater {
                            model: [
                                { cap: "feels", val: Weather.feels },
                                { cap: "humid", val: Weather.humidity },
                                { cap: "wind",  val: Weather.wind }
                            ]

                            delegate: Column {
                                required property var modelData

                                width: detailsRow.width / 3
                                spacing: 2

                                Text {
                                    text: parent.modelData.val
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: parent.modelData.cap
                                    color: Theme.subtext0
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    implicitHeight: forecastRow.implicitHeight + 24
                    radius: 12
                    color: Qt.alpha(Theme.surface0, 0.5)

                    Row {
                        id: forecastRow

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width

                        Repeater {
                            model: 3

                            delegate: Column {
                                id: dayCol

                                required property int index
                                readonly property var d:
                                    (Weather.data, Weather.fahrenheit, Weather.day(index))

                                width: forecastRow.width / 3
                                spacing: 4

                                Text {
                                    text: dayCol.d.name
                                    color: Theme.lavender
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: dayCol.d.glyph
                                    color: Theme.yellow
                                    font.family: Theme.font
                                    font.pixelSize: 24
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: dayCol.d.hi
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: dayCol.d.lo
                                    color: Theme.overlay0
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: Weather.error !== ""
                    text: Weather.error
                    color: Theme.red
                    font.family: Theme.font
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
