// Now playing: art + title + position + prev/play/next.
import QtQuick
import Quickshell.Services.Mpris

Column {
  ShellFont { id: shellFont }
  id: root
  width: parent.width
  spacing: 10

  property string pickedId: ""
  property var player: Mpris.players.values.find(p => p.uniqueId === root.pickedId) ?? Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

  function fmt(sec) {
    if (sec < 0 || isNaN(sec)) return "--:--";
    const m = Math.floor(sec / 60), s = Math.floor(sec % 60);
    return m + ":" + (s < 10 ? "0" + s : s);
  }

  Text {
    visible: !root.player
    text: "Nothing playing"
    color: Theme.textMuted
    font.family: shellFont.family; font.pixelSize: 13
  }

  Column {
    visible: !!root.player
    width: parent.width
    spacing: 10

    Row {
      width: parent.width
      spacing: 12
      Image {
        visible: root.player && root.player.trackArtUrl !== ""
        width: 56; height: 56
        source: root.player ? root.player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
      }
      Lucide {
        visible: !root.player || root.player.trackArtUrl === ""
        name: "music"; px: 34
      }
      Column {
        width: parent.width - 68
        spacing: 2
        Text {
          text: root.player ? (root.player.trackTitle || "Unknown title") : ""
          color: "#ffffff"
          font.family: shellFont.family; font.pixelSize: 13; font.bold: true
          elide: Text.ElideRight
          width: parent.width
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.player) root.player.raise(); } }
        }
        Text {
          text: root.player ? (root.player.trackArtist || root.player.identity || "") : ""
          color: Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 12
          elide: Text.ElideRight
          width: parent.width
        }
      }
    }

    Row {
      visible: Mpris.players.values.length > 1
      width: parent.width
      spacing: 10
      Repeater {
        model: Mpris.players.values
        delegate: Item {
          required property var modelData
          width: Math.min(140, pickText.implicitWidth)
          height: 18
          Text {
            id: pickText
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.identity
            color: (root.player && modelData.uniqueId === root.player.uniqueId) ? "#ffffff" : Theme.textMuted
            font.family: shellFont.family; font.pixelSize: 11
            elide: Text.ElideRight
            width: parent.width
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.pickedId = modelData.uniqueId }
        }
      }
    }

    Column {
      visible: root.player && root.player.lengthSupported
      width: parent.width
      spacing: 2
      Rectangle {
        width: parent.width; height: 3; radius: 1.5
        color: "#22ffffff"
        Rectangle {
          width: (root.player && root.player.length > 0) ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
          height: parent.height; radius: 1.5
          color: Theme.text
        }
      }
      Row {
        width: parent.width
        Text {
          id: posText
          text: root.player ? root.fmt(root.player.position) : ""
          color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 11
        }
        Text {
          text: root.player ? root.fmt(root.player.length) : ""
          color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 11
          width: parent.width - posText.width
          horizontalAlignment: Text.AlignRight
        }
      }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 28
      Item {
        width: 22; height: 22
        Lucide { anchors.centerIn: parent; name: "skip-back"; px: 20; opacity: hoverMa.containsMouse ? 1 : 0.6 }
        MouseArea { id: hoverMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.player) root.player.previous(); } }
      }
      Item {
        width: 22; height: 22
        Lucide { anchors.centerIn: parent; name: (root.player && root.player.isPlaying) ? "pause" : "play"; px: 22; opacity: playMa.containsMouse ? 1 : 0.85 }
        MouseArea { id: playMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.player) root.player.togglePlaying(); } }
      }
      Item {
        width: 22; height: 22
        Lucide { anchors.centerIn: parent; name: "skip-forward"; px: 20; opacity: nextMa.containsMouse ? 1 : 0.6 }
        MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.player) root.player.next(); } }
      }
    }
  }
}
