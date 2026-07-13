import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    id: root

    property var bar

    spacing: 8

    Repeater {
        model: SystemTray.items

        delegate: IconImage {
            id: item

            required property var modelData

            implicitSize: 18
            source: modelData.icon
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: event => {
                    if (event.button === Qt.LeftButton && !item.modelData.onlyMenu) {
                        item.modelData.activate();
                    } else if (event.button === Qt.MiddleButton) {
                        item.modelData.secondaryActivate();
                    } else if (item.modelData.hasMenu) {
                        const p = item.mapToItem(null, 0, item.height + 12);
                        item.modelData.display(root.bar, Math.round(p.x), Math.round(p.y));
                    }
                }
            }
        }
    }
}
