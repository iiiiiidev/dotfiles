import QtQuick
import Quickshell.Hyprland

Text {
    text: Hyprland.activeToplevel?.title ?? ""
    color: Theme.subtext1
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    elide: Text.ElideRight
    maximumLineCount: 1
    width: Math.min(implicitWidth, 600)
    anchors.verticalCenter: parent.verticalCenter
}
