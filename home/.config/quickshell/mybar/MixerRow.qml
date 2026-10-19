// Compact app row: icon + name + % on top, slim knobless bar below.
// Click the top line toggles mute.
import QtQuick

Column {
  ShellFont { id: shellFont }
  id: root
  property string title: ""
  property string sub: ""
  property string icon: ""
  property real volume: 0
  property bool muted: false
  signal setVolume(real v)
  signal toggleMute()

  width: parent.width
  spacing: 3

  Item {
    width: parent.width; height: 20
    Row {
      anchors.fill: parent
      spacing: 8
      Image {
        visible: root.icon !== ""
        width: 18; height: 18
        anchors.verticalCenter: parent.verticalCenter
        source: root.icon !== "" ? "image://icon/" + root.icon : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        onStatusChanged: if (status === Image.Error) root.icon = ""
      }
      Text {
        width: parent.width - (root.icon !== "" ? 26 : 0) - pctText.width - 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.title + (root.sub !== "" ? "  ·  " + root.sub : "")
        color: root.muted ? Theme.textMuted : Theme.text
        font.family: shellFont.family; font.pixelSize: 12
        elide: Text.ElideRight
      }
      Text {
        id: pctText
        anchors.verticalCenter: parent.verticalCenter
        text: root.muted ? "mute" : Math.round(root.volume * 100) + "%"
        color: root.muted ? Theme.textMuted : Theme.text
        font.family: shellFont.family; font.pixelSize: 12
      }
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggleMute()
    }
  }
  MiniSlider {
    width: parent.width
    knob: false
    value: root.muted ? 0 : root.volume
    onChanged: v => root.setVolume(v)
  }
}
