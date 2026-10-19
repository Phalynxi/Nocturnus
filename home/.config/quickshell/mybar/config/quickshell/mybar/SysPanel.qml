// System monitor popup: bars + top processes. Click header opens btop.
import QtQuick
import Quickshell.Io

Column {
  ShellFont { id: shellFont }
  id: root
  property bool active: false
  signal openBtop()

  width: parent.width
  spacing: 10

  property string cpu: "--"
  property string mem: "--"
  property string temp: "--"
  property var tops: []

  function poll() { statProc.running = true; }
  onActiveChanged: if (active) poll()

  Timer { interval: 2000; running: root.active; repeat: true; onTriggered: root.poll() }
  Process {
    id: statProc
    command: ["/home/octal/.local/bin/sysstat"]
    stdout: StdioCollector {
      onStreamFinished: {
        for (const line of this.text.trim().split("\n")) {
          if (line.startsWith("CPU=")) {
            const m = line.match(/CPU=(\d+) MEM=(\d+) TEMP=(\d+)/);
            if (m) { root.cpu = m[1]; root.mem = m[2]; root.temp = m[3]; }
          } else if (line.startsWith("TOP=")) {
            root.tops = line.slice(4).split(",").filter(s => s !== "");
          }
        }
      }
    }
  }

  Text {
    text: "System  ·  btop ↗"
    color: "#ffffff"
    font.family: shellFont.family; font.pixelSize: 13; font.bold: true
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.openBtop() }
  }

  Column {
    width: parent.width
    spacing: 6
    Row {
      width: parent.width
      spacing: 8
      Text { text: "CPU"; color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12; width: 36 }
      Rectangle {
        width: parent.width - 100; height: 6; radius: 3
        anchors.verticalCenter: parent.verticalCenter
        color: "#22ffffff"
        Rectangle { width: parent.width * Math.min(1, parseInt(root.cpu || "0") / 100); height: parent.height; radius: 3; color: Theme.text }
      }
      Text { text: root.cpu + "%"; color: Theme.text; font.family: shellFont.family; font.pixelSize: 12; width: 48; horizontalAlignment: Text.AlignRight }
    }
    Row {
      width: parent.width
      spacing: 8
      Text { text: "MEM"; color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12; width: 36 }
      Rectangle {
        width: parent.width - 100; height: 6; radius: 3
        anchors.verticalCenter: parent.verticalCenter
        color: "#22ffffff"
        Rectangle { width: parent.width * Math.min(1, parseInt(root.mem || "0") / 100); height: parent.height; radius: 3; color: Theme.text }
      }
      Text { text: root.mem + "%"; color: Theme.text; font.family: shellFont.family; font.pixelSize: 12; width: 48; horizontalAlignment: Text.AlignRight }
    }
    Row {
      width: parent.width
      spacing: 8
      Text { text: "TEMP"; color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12; width: 36 }
      Text { text: root.temp + "°C"; color: Theme.text; font.family: shellFont.family; font.pixelSize: 12 }
    }
  }

  Repeater {
    model: root.tops
    delegate: Text {
      required property var modelData
      width: root.width
      text: modelData.replace("|", "   ") + "%"
      color: Theme.textMuted
      font.family: shellFont.family; font.pixelSize: 12
      elide: Text.ElideRight
    }
  }
}
