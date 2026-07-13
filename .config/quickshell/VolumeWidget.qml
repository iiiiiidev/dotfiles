import QtQuick
import Quickshell.Services.Pipewire

Text {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)

    PwObjectTracker { objects: [root.sink] }

    text: (muted ? "󰖁 " : "󰕾 ") + percent + "%"
    color: muted ? Theme.overlay0 : Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    anchors.verticalCenter: parent.verticalCenter

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.sink?.audio)
                root.sink.audio.muted = !root.sink.audio.muted;
        }
        onWheel: wheel => {
            if (!root.sink?.audio)
                return;
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
        }
    }
}
