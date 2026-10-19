// Power menu popup.
import QtQuick
import Quickshell
import Quickshell.Io

Column {
  ShellFont { id: shellFont }
  id: root
  signal done()
  width: parent.width
  spacing: 4

  readonly property var actions: [
    { name: "Shutdown", icon: "power",      cmd: ["systemctl", "poweroff"] },
    { name: "Reboot",   icon: "rotate-ccw", cmd: ["systemctl", "reboot"] },
    { name: "Logout",   icon: "log-out",    cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
    { name: "Suspend",  icon: "moon",       cmd: ["systemctl", "suspend"] },
    { name: "Lock",     icon: "lock",       cmd: ["hyprlock"] }
  ]

  Text {
    text: "Power"
    color: "#ffffff"
    font.family: shellFont.family; font.pixelSize: 13; font.bold: true
  }

  Repeater {
    model: root.actions
    delegate: Item {
      required property var modelData
      width: root.width; height: 30
      Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12
        Lucide { name: modelData.icon; px: 18; opacity: actMa.containsMouse ? 1 : 0.7 }
        Text {
          text: modelData.name
          color: actMa.containsMouse ? "#ffffff" : Theme.text
          font.family: shellFont.family; font.pixelSize: 13
        }
      }
      MouseArea {
        id: actMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { Quickshell.execDetached(modelData.cmd); root.done(); }
      }
    }
  }
}
