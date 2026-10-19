// Shared popup surface for bar widgets (volume mixer / media / calendar).
// Parent binds `current` to root.popup; emits closed() on outside click.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io

Scope {
  id: root
  property string current: ""
  signal closed()
  property int rounding: 16
  property var dockStore: null
  property var widgetStore: null

  property var currentScreen: {
    const f = Hyprland.focusedMonitor;
    const s = Quickshell.screens.find(scr => f && scr.name === f.name);
    return s ?? Quickshell.screens[0];
  }

  PanelWindow {
    visible: root.current !== ""
    screen: root.currentScreen
    WlrLayershell.namespace: "mybar-pop"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    MouseArea {
      anchors.fill: parent
      onClicked: root.closed()
    }

    Rectangle {
      id: popPanel
      property bool shown: root.current !== ""
      opacity: shown ? 1 : 0
      transform: Translate { y: popPanel.shown ? 0 : 12; Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
      Behavior on opacity { NumberAnimation { duration: 180 } }
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.top: parent.top
      anchors.topMargin: 58
      width: root.current === "controlcenter" ? 360 : 348
      height: popCol.height + 32
      radius: root.rounding
      color: Theme.ground(0x33/255)

      Column {
        id: popCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        MixerPanel { visible: root.current === "volume" }
        MediaPanel { visible: root.current === "media" }
        CalendarPanel { visible: root.current === "calendar" }
        ControlCenter {
          visible: root.current === "controlcenter"
          dockStore: root.dockStore
          widgetStore: root.widgetStore
        }
        SysPanel {
          visible: root.current === "sys"
          active: root.current === "sys"
          onOpenBtop: { Quickshell.execDetached(["kitty", "-e", "btop"]); root.closed(); }
        }
        PowerPanel { visible: root.current === "power"; onDone: root.closed() }
        OverviewPanel { visible: root.current === "overview" }
      }
    }
  }
}
