// Window overview: windows on the focused workspace. Click focuses, middle-click closes.
import QtQuick
import Quickshell.Hyprland

Column {
  ShellFont { id: shellFont }
  id: root
  width: parent.width
  spacing: 6

  // showAll lists every window (dashboard); otherwise focused workspace only
  property bool showAll: false
  property var wins: {
    if (root.showAll) return [...Hyprland.toplevels.values];
    const fw = Hyprland.focusedWorkspace;
    if (!fw) return [];
    return Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id === fw.id);
  }
  // maxItems > 0 caps the list (dashboard use)
  property int maxItems: 0
  property var shown: root.maxItems > 0 ? root.wins.slice(0, root.maxItems) : root.wins

  Text {
    text: "Windows" + (Hyprland.focusedWorkspace ? "  ·  " + Hyprland.focusedWorkspace.name : "")
    color: "#ffffff"
    font.family: shellFont.family; font.pixelSize: 13; font.bold: true
  }

  Text {
    visible: root.shown.length === 0
    text: "No windows here"
    color: Theme.textMuted
    font.family: shellFont.family; font.pixelSize: 12
  }

  Repeater {
    model: root.shown
    delegate: Item {
      required property var modelData
      property var t: modelData
      width: root.width; height: 26
      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        text: (root.showAll && t.workspace ? "[" + t.workspace.id + "] " : "") + (t.lastIpcObject.class || "?") + "  ·  " + (t.title || t.lastIpcObject.class || "")
        color: winMa.containsMouse ? "#ffffff" : Theme.text
        font.family: shellFont.family; font.pixelSize: 12
        elide: Text.ElideRight
      }
      MouseArea {
        id: winMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
          if (mouse.button === Qt.MiddleButton) Hyprland.dispatch("closewindow address:" + t.address);
          else Hyprland.dispatch("focuswindow address:" + t.address);
        }
      }
    }
  }
}
