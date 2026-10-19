// Compact audio controls for the dashboard: output + input rows.
// Reuses MixerRow (horizontal sliders) instead of MixerPanel's tall pill.
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
  property var source: Pipewire.defaultAudioSource ?? Pipewire.nodes.values.find(n => !n.isSink && !n.isStream && n.audio) ?? null

  PwObjectTracker { objects: root.source ? [root.source] : [] }

  Text {
    text: "Audio"
    color: "#ffffff"
    font.family: shellFont.family; font.pixelSize: 13; font.bold: true
  }

  MixerRow {
    title: "Output"
    sub: (root.sink && root.sink.ready) ? (root.sink.description || root.sink.nickname || "") : ""
    icon: ""
    volume: (root.sink && root.sink.ready) ? root.sink.audio.volume : 0
    muted: (root.sink && root.sink.ready) ? root.sink.audio.muted : false
    onSetVolume: v => { if (root.sink && root.sink.ready) root.sink.audio.volume = v; }
    onToggleMute: { if (root.sink && root.sink.ready) root.sink.audio.muted = !root.sink.audio.muted; }
  }

  MixerRow {
    visible: root.source && root.source.ready
    title: "Input"
    sub: (root.source && root.source.ready) ? (root.source.description || root.source.nickname || "") : ""
    icon: ""
    volume: (root.source && root.source.ready) ? root.source.audio.volume : 0
    muted: (root.source && root.source.ready) ? root.source.audio.muted : false
    onSetVolume: v => { if (root.source && root.source.ready) root.source.audio.volume = v; }
    onToggleMute: { if (root.source && root.source.ready) root.source.audio.muted = !root.source.audio.muted; }
  }

  Text {
    visible: !root.sink || !root.sink.ready
    text: "No output device"
    color: Theme.textMuted
    font.family: shellFont.family; font.pixelSize: 12
  }
}
