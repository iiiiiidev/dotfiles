import QtQuick
import Quickshell
import Quickshell.Io

Text {
    id: root

    property int count: 0
    property bool dnd: false

    text: {
        const icon = dnd ? "󰂛" : "󰂚";
        return count > 0 ? icon + " " + count : icon;
    }
    color: count > 0 ? Theme.mauve : dnd ? Theme.overlay0 : Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    anchors.verticalCenter: parent.verticalCenter

    Process {
        running: true
        command: ["swaync-client", "-swb"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const j = JSON.parse(data);
                    root.count = parseInt(j.text) || 0;
                    root.dnd = String(j.class).includes("dnd");
                } catch (e) {}
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.LeftButton)
                Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
            else
                Quickshell.execDetached(["swaync-client", "-d", "-sw"]);
        }
    }
}
