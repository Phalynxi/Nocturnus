// Glass wallpaper gallery. Toggle with:
//   quickshell -p /home/octal/.config/quickshell/mybar/shell.qml ipc call wallpaper toggle
// Bound to Super+W in hyprland.lua. Backend: awww (runtime switching, no restarts).
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io

Scope {
  ShellFont { id: shellFont }
  id: root
  property bool open: false
  property var wallpapers: []
  property string current: ""

  property var currentScreen: {
    const f = Hyprland.focusedMonitor;
    const s = Quickshell.screens.find(scr => f && scr.name === f.name);
    return s ?? Quickshell.screens[0];
  }

  function isVideo(path) { return /\.(mp4|webm|mkv|mov)$/i.test(path); }

  function setWallpaper(path) {
    if (root.isVideo(path))
      Quickshell.execDetached(["/home/octal/.local/bin/wp", "vid", path]);
    else
      Quickshell.execDetached(["/home/octal/.local/bin/wp", "img", path]);
    root.current = path;
    root.close();
  }

  function openMenu() {
    root.open = true;
    queryProc.running = true;
  }
  function close() { root.open = false; }
  function toggle() { root.open ? root.close() : root.openMenu(); }

  IpcHandler {
    target: "wallpaper"
    function toggle(): void { root.toggle(); }
    function open(): void { root.openMenu(); }
    function close(): void { root.close(); }
  }

  // enumerate ~/WALLPAPERS once at startup (dynamic — new files appear automatically)
  Process {
    running: true
    command: ["sh", "-c", "for f in $HOME/WALLPAPERS/*; do case \"$f\" in *.png|*.PNG|*.jpg|*.JPG|*.jpeg|*.JPEG|*.gif|*.GIF|*.webp|*.WEBP|*.mp4|*.MP4|*.webm|*.WEBM|*.mkv|*.MKV|*.mov|*.MOV) echo \"$f\";; esac; done | sort"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.wallpapers = this.text.trim().split("\n").filter(s => s.length > 0);
      }
    }
  }

  // ask awww which wallpaper is active (runs each time menu opens)
  Process {
    id: queryProc
    running: false
    command: ["awww", "query"]
    stdout: StdioCollector {
      onStreamFinished: {
        const m = this.text.match(/currently displaying:\s*image:\s*(\S+)/);
        if (m) root.current = m[1];
      }
    }
  }

  onOpenChanged: if (open) keyGrab.forceActiveFocus()

  // BACKDROP: plain blur + dim
  PanelWindow {
    visible: root.open
    screen: root.currentScreen
    WlrLayershell.namespace: "mywallpaper-bg"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    Rectangle { anchors.fill: parent; color: "#4d000000" }
    MouseArea { anchors.fill: parent; onClicked: root.close() }
  }

  // GALLERY: liquid glass panel with thumbnail grid
  PanelWindow {
    visible: root.open
    screen: root.currentScreen
    WlrLayershell.namespace: "mywallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region { item: panel }

    Item {
      id: keyGrab
      focus: true
      anchors.fill: parent
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true; }
        else if (event.key === Qt.Key_Left) { grid.moveCurrentIndexLeft(); event.accepted = true; }
        else if (event.key === Qt.Key_Right) { grid.moveCurrentIndexRight(); event.accepted = true; }
        else if (event.key === Qt.Key_Up) { grid.moveCurrentIndexUp(); event.accepted = true; }
        else if (event.key === Qt.Key_Down) { grid.moveCurrentIndexDown(); event.accepted = true; }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          if (grid.currentIndex >= 0) root.setWallpaper(root.wallpapers[grid.currentIndex]);
          event.accepted = true;
        }
      }
    }

    Rectangle {
      id: panel
      property bool shown: root.open
      opacity: shown ? 1 : 0
      transform: Translate { y: panel.shown ? 0 : 16; Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } }
      Behavior on opacity { NumberAnimation { duration: 200 } }
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 90
      width: 780
      height: 520
      radius: 20
      color: Theme.ground(0x33/255)

      Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Text {
          text: "Wallpapers  ·  " + root.wallpapers.length + "  ·  esc to close"
          color: Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 12
        }

        GridView {
          id: grid
          width: parent.width
          height: parent.height - 30
          clip: true
          cellWidth: 182; cellHeight: 116
          model: root.wallpapers
          highlightMoveDuration: 150
          delegate: Item {
            required property var modelData
            required property int index
            width: 182; height: 116

            Image {
              visible: !root.isVideo(modelData)
              anchors.centerIn: parent
              width: 168; height: 102
              source: root.isVideo(modelData) ? "" : "file://" + modelData
              asynchronous: true
              fillMode: Image.PreserveAspectCrop
              smooth: true
              cache: true
              scale: index === grid.currentIndex ? 1.06 : 1.0
              Behavior on scale { NumberAnimation { duration: 120 } }
            }

            // video tile: clapperboard + filename
            Rectangle {
              visible: root.isVideo(modelData)
              anchors.centerIn: parent
              width: 168; height: 102
              radius: 10
              color: Theme.ground(0x22/255)
              scale: index === grid.currentIndex ? 1.06 : 1.0
              Behavior on scale { NumberAnimation { duration: 120 } }
              Column {
                anchors.centerIn: parent
                spacing: 6
                Lucide { anchors.horizontalCenter: parent.horizontalCenter; name: "clapperboard"; px: 30 }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.split("/").pop().replace(/\.[^.]+$/, "")
                  color: Theme.text
                  font.family: shellFont.family; font.pixelSize: 11
                  elide: Text.ElideMiddle
                  width: 150
                  horizontalAlignment: Text.AlignHCenter
                }
              }
            }

            // dot = currently active wallpaper
            Rectangle {
              visible: root.current !== "" && modelData === root.current
              anchors.right: parent.right; anchors.rightMargin: 14
              anchors.top: parent.top; anchors.topMargin: 14
              width: 8; height: 8; radius: 4
              color: "#ffffff"; opacity: 0.85
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: grid.currentIndex = index
              onClicked: root.setWallpaper(modelData)
            }
          }
        }
      }
    }
  }
}
