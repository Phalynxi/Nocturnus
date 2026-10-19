// Display / night-light controls for the dashboard.
// No backlight or DDC/CI on this machine, so this controls hyprsunset
// (blue-light filter) instead of hardware brightness.
import QtQuick
import Quickshell
import Quickshell.Io

Column {
  ShellFont { id: shellFont }
  id: root
  width: parent.width
  spacing: 10

  property bool nightLight: false
  // kelvin 1000 (warm) .. 6500 (off-white); hyprsunset default 6000
  property int temperature: 4500

  function refresh() { checkProc.running = true; }
  Component.onCompleted: refresh()

  // poll daemon state every 5s while dashboard is open (cheap pgrep)
  Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }

  Process {
    id: checkProc
    command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo on || echo off"]
    stdout: StdioCollector {
      onStreamFinished: { root.nightLight = this.text.trim() === "on"; }
    }
  }

  function applyTemp(k) {
    root.temperature = k;
    if (root.nightLight)
      Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(k)]);
  }

  function setNightLight(on) {
    if (on) {
      // start daemon at current temp (idempotent: pkill stale first)
      Quickshell.execDetached(["sh", "-c", "pgrep -x hyprsunset >/dev/null || hyprsunset -t " + root.temperature + " &"]);
      root.nightLight = true;
    } else {
      Quickshell.execDetached(["sh", "-c", "pkill -x hyprsunset"]);
      root.nightLight = false;
    }
  }

  Text {
    text: "Display"
    color: "#ffffff"
    font.family: shellFont.family; font.pixelSize: 13; font.bold: true
  }

  // night light toggle row
  Item {
    width: parent.width; height: 22
    Row {
      anchors.fill: parent
      spacing: 10
      Lucide { anchors.verticalCenter: parent.verticalCenter; name: "moon"; px: 16 }
      Text {
        width: parent.width - 80
        anchors.verticalCenter: parent.verticalCenter
        text: "Night light"
        color: Theme.text
        font.family: shellFont.family; font.pixelSize: 12
        elide: Text.ElideRight
      }
    }
    // switch
    Rectangle {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 38; height: 20; radius: 10
      color: root.nightLight ? Theme.text : "#22ffffff"
      Rectangle {
        x: root.nightLight ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 14; height: 14; radius: 7
        color: root.nightLight ? Theme.background : Theme.textMuted
        Behavior on x { NumberAnimation { duration: 150 } }
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.setNightLight(!root.nightLight)
      }
    }
  }

  // temperature slider (only useful while on)
  Column {
    width: parent.width
    spacing: 3
    opacity: root.nightLight ? 1 : 0.4
    Item {
      width: parent.width; height: 20
      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "Warmth"
        color: Theme.textMuted
        font.family: shellFont.family; font.pixelSize: 12
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.temperature + "K"
        color: Theme.text
        font.family: shellFont.family; font.pixelSize: 12
      }
    }
    MiniSlider {
      width: parent.width
      knob: false
      // slider 0..1 maps 6500K (cool) .. 2500K (warm); invert so right = cooler
      value: 1 - (6500 - root.temperature) / 4000
      onChanged: v => {
        const k = Math.round(6500 - (1 - v) * 4000);
        root.applyTemp(Math.max(2500, Math.min(6500, k)));
      }
    }
  }

  Text {
    text: "No backlight/DDC on HDMI-A-1 — hardware brightness unavailable"
    color: Theme.textMuted
    font.family: shellFont.family; font.pixelSize: 11
    wrapMode: Text.Wrap
    width: parent.width
  }
}
