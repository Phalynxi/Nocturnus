// Volume mixer: big iPhone-style vertical output pill + compact rows.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Column {
  ShellFont { id: shellFont }
  id: root
  width: parent.width
  spacing: 10

  PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

  property var sink: Pipewire.defaultAudioSink
  // defaultAudioSource is unset here — fall back to the first real source node
  property var source: Pipewire.defaultAudioSource ?? Pipewire.nodes.values.find(n => !n.isSink && !n.isStream && n.audio) ?? null

  // the fallback node isn't in the tracker above until resolved — track it so it becomes ready
  PwObjectTracker { objects: root.source ? [root.source] : [] }

  Text {
    text: "Volume"
    color: "#ffffff"
    font.family: shellFont.family; font.pixelSize: 13; font.bold: true
  }

  Row {
    width: parent.width
    spacing: 16

    // big vertical output pill
    Column {
      spacing: 8
      MiniSlider {
        vertical: true
        width: 88; height: 200
        value: (root.sink && root.sink.ready && !root.sink.audio.muted) ? root.sink.audio.volume : 0
        onChanged: v => { if (root.sink && root.sink.ready) root.sink.audio.volume = v; }
      }
      Lucide {
        anchors.horizontalCenter: parent.horizontalCenter
        name: (!root.sink || !root.sink.ready || root.sink.audio.muted) ? "volume-x" : "volume-2"
        px: 20
        opacity: spkMa.containsMouse ? 1 : 0.8
        MouseArea {
          id: spkMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: { if (root.sink && root.sink.ready) root.sink.audio.muted = !root.sink.audio.muted; }
        }
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
          const s = root.sink;
          if (!s || !s.ready) return "--";
          return s.audio.muted ? "mute" : Math.round(s.audio.volume * 100) + "%";
        }
        color: "#ffffff"
        font.family: shellFont.family; font.pixelSize: 15; font.bold: true
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 80
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: (root.sink && root.sink.ready) ? (root.sink.description || root.sink.nickname || "") : "no sink"
        color: Theme.textMuted
        font.family: shellFont.family; font.pixelSize: 10
      }
    }

    // compact row: input
    Column {
      width: parent.width - 104
      MixerRow {
        visible: root.source && root.source.ready
        title: "Input"
        sub: (root.source && root.source.ready) ? (root.source.description || root.source.nickname || "") : ""
        icon: "audio-input-microphone"
        volume: (root.source && root.source.ready) ? root.source.audio.volume : 0
        muted: (root.source && root.source.ready) ? root.source.audio.muted : false
        onSetVolume: v => { if (root.source && root.source.ready) root.source.audio.volume = v; }
        onToggleMute: { if (root.source && root.source.ready) root.source.audio.muted = !root.source.audio.muted; }
      }
    }
  }
}
