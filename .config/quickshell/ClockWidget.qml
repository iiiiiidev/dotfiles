import QtQuick

Text {
    id: clock

    property var now: new Date()

    text: Qt.formatDateTime(now, "ddd MMM d   HH:mm")
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    font.bold: true

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.now = new Date()
    }
}
