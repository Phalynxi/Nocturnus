// Minimal glass dock icon: bare icon, no tile. Magnify + tooltip + running dot only.
// Fixed height with centered visuals so icons stay aligned while magnifying.
import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
  ShellFont { id: shellFont }
  id: icon
  property int base: 44
  property int max: 68
  property real mag: 1
  property string appId: ""
  property string execCmd: ""
  property string iconName: "application-x-executable"
  property bool running: false
  signal clicked

  property bool isText: iconName.startsWith("text:")
  property bool isLucide: iconName.startsWith("lucide:")
  property real centerX: x + width / 2
  width: size
  height: max + 6
  property real size: base + (max - base) * (mag - 1) / 0.7

  Behavior on size { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

  // centered icon box (dot zone reserved at the bottom for all icons alike)
  Item {
    id: visuals
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: -3
    width: icon.size; height: icon.size

    Image {
      visible: !icon.isText && !icon.isLucide
      anchors.centerIn: parent
      width: parent.width; height: parent.height
      source: (icon.isText || icon.isLucide) ? "" : "image://icon/" + icon.iconName
      fillMode: Image.PreserveAspectFit
      smooth: true
    }

    Lucide {
      visible: icon.isLucide
      anchors.centerIn: parent
      name: icon.isLucide ? icon.iconName.slice(7) : ""
      px: icon.size * 0.85
    }

    Text {
      visible: icon.isText
      anchors.centerIn: parent
      width: parent.width; height: parent.height
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      text: icon.iconName.slice(5)
      color: Theme.text
      font.pixelSize: icon.size * 0.55
      font.family: shellFont.family
    }

    // tooltip (follows the icon box, not the tile)
    Rectangle {
      visible: iconMouse.containsMouse
      anchors.bottom: parent.top; anchors.bottomMargin: 10
      anchors.horizontalCenter: parent.horizontalCenter
      width: tipText.width + 20; height: 28
      radius: 9; color: Theme.ground(0.8)
      Text {
        id: tipText; anchors.centerIn: parent
        text: icon.appId; color: Theme.text
        font.pixelSize: 12; font.family: shellFont.family
      }
    }
  }

  MouseArea {
    id: iconMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: mouse => {
      if (mouse.button === Qt.MiddleButton) {
        if (icon.execCmd) Quickshell.execDetached(icon.execCmd.split(" "));
        return;
      }
      const t = Hyprland.toplevels.values.find(t =>
        (t.lastIpcObject.class || "").toLowerCase().includes(icon.appId));
      if (t) Hyprland.dispatch("focuswindow address:" + t.address);
      else if (icon.execCmd) Quickshell.execDetached(icon.execCmd.split(" "));
      icon.clicked();
      bounce.restart();
    }
  }
  SequentialAnimation {
    id: bounce
    NumberAnimation { target: visuals; property: "y"; to: -18; duration: 160; easing.type: Easing.OutQuad }
    NumberAnimation { target: visuals; property: "y"; to: 0; duration: 220; easing.type: Easing.OutBounce }
  }

  // running dot
  Rectangle {
    visible: icon.running
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    width: 5; height: 5; radius: 2.5
    color: "#ffffff"
    opacity: 0.7
  }
}
