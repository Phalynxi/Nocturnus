// Dashboard overlay: pages for overview / controls / dock.
// Toggle: quickshell -p .../mybar/shell.qml ipc call dashboard toggle  (Super+D)
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io

Scope {
  ShellFont { id: shellFont }
  id: root
  property bool open: false
  property string page: "overview"
  property var dockStore: null
  property var widgetStore: null

  readonly property int cellW: 325
  readonly property var favs: [
    "/home/octal/WALLPAPERS/04-ambxst-blobs-blue.png",
    "/home/octal/WALLPAPERS/05-ambxst-blobs-purple.png",
    "/home/octal/WALLPAPERS/09-ambxst-gruvbox-dark.png",
    "/home/octal/WALLPAPERS/pokemon.gif",
    "/home/octal/WALLPAPERS/luffy1.gif"
  ]
  readonly property var tabs: [
    { id: "overview", label: "Overview" },
    { id: "controls", label: "Controls" },
    { id: "dock", label: "Dock" },
    { id: "widgets", label: "Widgets" }
  ]

  function toggle() { root.open = !root.open; }
  function close() { root.open = false; }

  // animated page switch: fade content out, swap, morph panel, fade in
  property string pendingPage: "overview"
  function goPage(p) {
    if (p !== "overview" && p !== "controls" && p !== "dock" && p !== "widgets") return;
    if (root.page === p) return;
    dashFlick.contentY = 0;
    root.pendingPage = p;
    if (!pageAnim.running) pageAnim.restart();
  }

  SequentialAnimation {
    id: pageAnim
    NumberAnimation { target: dashCol; property: "opacity"; to: 0; duration: 130; easing.type: Easing.InCubic }
    ScriptAction { script: root.page = root.pendingPage; }
    NumberAnimation { target: dashCol; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
  }

  IpcHandler {
    target: "dashboard"
    function toggle(): void { root.toggle(); }
    function open(): void { root.open = true; }
    function close(): void { root.close(); }
    function page(name: string): void { root.goPage(name); root.open = true; }
  }

  onOpenChanged: {
    if (open) {
      root.page = "overview";
      dashFlick.contentY = 0;
      keyGrab.forceActiveFocus();
    }
  }

  property var currentScreen: {
    const f = Hyprland.focusedMonitor;
    const s = Quickshell.screens.find(scr => f && scr.name === f.name);
    return s ?? Quickshell.screens[0];
  }

  // BACKDROP: plain blur + dim
  PanelWindow {
    visible: root.open
    screen: root.currentScreen
    WlrLayershell.namespace: "mydash-bg"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    Rectangle { anchors.fill: parent; color: "#4d000000" }
    MouseArea { anchors.fill: parent; onClicked: root.close() }
  }

  // PANEL (vertically centered, height-capped so it never clips off-screen)
  PanelWindow {
    visible: root.open
    screen: root.currentScreen
    WlrLayershell.namespace: "mydash"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region { item: dashPanel }

    Item {
      id: keyGrab
      focus: true
      anchors.fill: parent
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true; }
        else if (event.key === Qt.Key_1) { root.goPage("overview"); event.accepted = true; }
        else if (event.key === Qt.Key_2) { root.goPage("controls"); event.accepted = true; }
        else if (event.key === Qt.Key_3) { root.goPage("dock"); event.accepted = true; }
        else if (event.key === Qt.Key_4) { root.goPage("widgets"); event.accepted = true; }
        else if (event.key === Qt.Key_PageDown) { dashFlick.contentY = Math.min(Math.max(0, dashFlick.contentHeight - dashFlick.height), dashFlick.contentY + 220); event.accepted = true; }
        else if (event.key === Qt.Key_PageUp) { dashFlick.contentY = Math.max(0, dashFlick.contentY - 220); event.accepted = true; }
        else if (event.key === Qt.Key_Home) { dashFlick.contentY = 0; event.accepted = true; }
        else if (event.key === Qt.Key_End) { dashFlick.contentY = Math.max(0, dashFlick.contentHeight - dashFlick.height); event.accepted = true; }
      }
    }

    Rectangle {
      id: dashPanel
      property bool shown: root.open
      opacity: shown ? 1 : 0
      transform: Translate { y: dashPanel.shown ? 0 : 20; Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
      Behavior on opacity { NumberAnimation { duration: 220 } }
      anchors.centerIn: parent
      width: Math.min(root.cellW * 3 + 24 + 40, parent.width - 40)
      height: Math.min(dashCol.height + 40, parent.height - 80)
      Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
      Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
      radius: 20
      color: Theme.ground(0x2b/255)
      clip: true

      Flickable {
        id: dashFlick
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: width
        contentHeight: dashCol.height
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
          width: 6
          policy: ScrollBar.AsNeeded
          contentItem: Rectangle { radius: 3; color: "#44ffffff" }
        }

      Column {
        id: dashCol
        width: dashFlick.width - (dashFlick.contentHeight > dashFlick.height ? 10 : 0)
        spacing: 14

        // header: clock + date + tabs
        Row {
          width: parent.width
          spacing: 14
          Text {
            SystemClock { id: dashClock; precision: SystemClock.Minutes }
            text: Qt.formatDateTime(dashClock.date, "HH:mm")
            color: "#ffffff"
            font.family: shellFont.family; font.pixelSize: 38; font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: Qt.formatDateTime(dashClock.date, "dddd, MMM d")
            color: Theme.textMuted
            font.family: shellFont.family; font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
          }
          Item { width: 1; height: 1; anchors.verticalCenter: parent.verticalCenter }
          Row {
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
              model: root.tabs
              delegate: Rectangle {
                required property var modelData
                property bool sel: root.page === modelData.id
                width: 92; height: 28
                radius: 14
                color: sel ? "#40ffffff" : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: modelData.label
                  color: sel ? "#ffffff" : Theme.textMuted
                  font.family: shellFont.family; font.pixelSize: 12
                  font.bold: sel
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.goPage(modelData.id)
                }
              }
            }
          }
        }

        // ── PAGE: overview ──
        // row 1: equal cards (Grid needs uniform children — wide cards live outside it)
        Grid {
          visible: root.page === "overview"
          width: parent.width
          columns: 3
          columnSpacing: 12
          rowSpacing: 12

          // system
          Rectangle {
            width: root.cellW; height: sysWrap.height + 28
            radius: 16; color: Theme.ground(0x22/255)
            Item {
              id: sysWrap
              anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
              anchors.margins: 14
              height: sysCard.height
              SysPanel { id: sysCard; active: root.open && root.page === "overview"; width: parent.width; onOpenBtop: { Quickshell.execDetached(["kitty", "-e", "btop"]); root.close(); } }
            }
          }
          // media
          Rectangle {
            width: root.cellW; height: mediaWrap.height + 28
            radius: 16; color: Theme.ground(0x22/255)
            Item {
              id: mediaWrap
              anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
              anchors.margins: 14
              height: mediaCard.height
              MediaPanel { id: mediaCard; width: parent.width }
            }
          }
          // calendar
          Rectangle {
            width: root.cellW; height: calWrap.height + 28
            radius: 16; color: Theme.ground(0x22/255)
            Item {
              id: calWrap
              anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
              anchors.margins: 14
              height: calCard.height
              CalendarPanel { id: calCard; width: parent.width }
            }
          }
        }
        // row 2: windows (all, full width)
        Rectangle {
          visible: root.page === "overview"
          width: parent.width; height: winWrap.height + 28
          radius: 16; color: Theme.ground(0x22/255)
          Item {
            id: winWrap
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 14
            height: winCard.height
            OverviewPanel { id: winCard; showAll: true; maxItems: 6; width: parent.width }
          }
        }

        // ── PAGE: controls ──
        Grid {
          visible: root.page === "controls"
          width: parent.width
          columns: 3
          columnSpacing: 12
          rowSpacing: 12

          // audio controls
          Rectangle {
            width: root.cellW; height: audioWrap.height + 28
            radius: 16; color: Theme.ground(0x22/255)
            Item {
              id: audioWrap
              anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
              anchors.margins: 14
              height: audioCard.height
              AudioPanel { id: audioCard; width: parent.width }
            }
          }
          // display / night light
          Rectangle {
            width: root.cellW; height: dispWrap.height + 28
            radius: 16; color: Theme.ground(0x22/255)
            Item {
              id: dispWrap
              anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
              anchors.margins: 14
              height: dispCard.height
              DisplayPanel { id: dispCard; width: parent.width }
            }
          }
          // power
          Rectangle {
            width: root.cellW; height: powerWrap.height + 28
            radius: 16; color: Theme.ground(0x22/255)
            Item {
              id: powerWrap
              anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
              anchors.margins: 14
              height: powerCard.height
              PowerPanel { id: powerCard; width: parent.width; onDone: root.close() }
            }
          }
        }
        // gaming mode (full width)
        Rectangle {
          visible: root.page === "controls"
          width: parent.width; height: 56
          radius: 16; color: (root.dockStore && root.dockStore.gamingMode) ? Theme.redA(0x66/255) : Theme.ground(0x22/255)
          Row {
            anchors.fill: parent
            anchors.leftMargin: 14; anchors.rightMargin: 14
            spacing: 10
            Text {
              width: parent.width - 110
              anchors.verticalCenter: parent.verticalCenter
              text: "Gaming mode  ·  kills glass + blur for max FPS"
              color: "#ffffff"
              font.family: shellFont.family; font.pixelSize: 13; font.bold: true
              elide: Text.ElideRight
            }
            Rectangle {
              width: 96; height: 30; radius: 15
              anchors.verticalCenter: parent.verticalCenter
              color: (root.dockStore && root.dockStore.gamingMode) ? Theme.text : "#22ffffff"
              Text {
                anchors.centerIn: parent
                text: (root.dockStore && root.dockStore.gamingMode) ? "ON" : "OFF"
                color: (root.dockStore && root.dockStore.gamingMode) ? Theme.background : "#ffffff"
                font.family: shellFont.family; font.pixelSize: 12; font.bold: true
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.dockStore) root.dockStore.gamingMode = !root.dockStore.gamingMode; }
              }
            }
          }
        }
        // wallpaper favorites (full width, below the equal cards)
        Rectangle {
          visible: root.page === "controls"
          width: parent.width; height: favCol.height + 28 + 14
          radius: 16; color: Theme.ground(0x22/255)
            Column {
              id: favCol
              anchors.top: parent.top
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.margins: 14
              spacing: 10
              Text { text: "Wallpapers"; color: "#ffffff"; font.family: shellFont.family; font.pixelSize: 13; font.bold: true }
              Row {
                width: parent.width
                spacing: 8
                Repeater {
                  model: root.favs
                  delegate: Image {
                    required property var modelData
                    width: (favCol.width - 32) / 5; height: 40
                    source: "file://" + modelData
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    cache: true
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: { Quickshell.execDetached(["/home/octal/.local/bin/wp", "img", modelData]); }
                    }
                  }
                }
              }
              Item {
                width: parent.width; height: 16
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Super+W for the full gallery"
                  color: Theme.textMuted
                  font.family: shellFont.family; font.pixelSize: 11
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { root.close(); Quickshell.execDetached(["quickshell", "-p", "/home/octal/.config/quickshell/mybar/shell.qml", "ipc", "call", "wallpaper", "open"]); }
                }
              }
            }
          }
        // ── PAGE: dock ──
        Rectangle {
          visible: root.page === "dock"
          width: parent.width
          height: dockWrap.height + 28
          radius: 16; color: Theme.ground(0x22/255)
          Item {
            id: dockWrap
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 14
            height: dockCard.height
            DockPanel { id: dockCard; dockStore: root.dockStore; width: parent.width }
          }
        }
        // ── PAGE: widgets ──
        Rectangle {
          visible: root.page === "widgets"
          width: parent.width
          height: widgetsCol.height + 28
          radius: 16; color: Theme.ground(0x22/255)
          Column {
            id: widgetsCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            spacing: 10
            Row {
              width: parent.width
              spacing: 10
              Text { text: "Desktop widgets"; color: "#ffffff"; font.family: shellFont.family; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
              Item { width: parent.width - 260; height: 1 }
              Rectangle {
                width: 130; height: 30; radius: 15
                anchors.verticalCenter: parent.verticalCenter
                color: (root.widgetStore && root.widgetStore.editMode) ? "#40ffffff" : "#22ffffff"
                Text {
                  anchors.centerIn: parent
                  text: (root.widgetStore && root.widgetStore.editMode) ? "Editing… done?" : "Edit layout"
                  color: "#ffffff"
                  font.family: shellFont.family; font.pixelSize: 12
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { if (root.widgetStore) root.widgetStore.editMode = !root.widgetStore.editMode; }
                }
              }
            }
            Text { text: "Super+G toggles edit mode · drag cards by their header · × deletes"; color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 11 }
            Row {
              width: parent.width
              spacing: 8
              Text { text: "Glass:"; color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
              Rectangle {
                width: 64; height: 28; radius: 14
                anchors.verticalCenter: parent.verticalCenter
                color: (root.widgetStore && root.widgetStore.glass) ? "#40ffffff" : "#22ffffff"
                Text {
                  anchors.centerIn: parent
                  text: (root.widgetStore && root.widgetStore.glass) ? "ON" : "OFF"
                  color: "#ffffff"
                  font.family: shellFont.family; font.pixelSize: 12; font.bold: true
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { if (root.widgetStore) root.widgetStore.glass = !root.widgetStore.glass; }
                }
              }
              Item { width: 12; height: 1 }
              Text { text: "Blur:"; color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
              Rectangle {
                width: 64; height: 28; radius: 14
                anchors.verticalCenter: parent.verticalCenter
                color: (root.widgetStore && root.widgetStore.blur) ? "#40ffffff" : "#22ffffff"
                Text {
                  anchors.centerIn: parent
                  text: (root.widgetStore && root.widgetStore.blur) ? "ON" : "OFF"
                  color: "#ffffff"
                  font.family: shellFont.family; font.pixelSize: 12; font.bold: true
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { if (root.widgetStore) root.widgetStore.blur = !root.widgetStore.blur; }
                }
              }
            }
            Text { text: "Add:"; color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12 }
            Grid {
              width: parent.width
              columns: 3
              columnSpacing: 8
              rowSpacing: 8
              Repeater {
                model: root.widgetStore ? root.widgetStore.catalog : []
                delegate: Rectangle {
                  required property var modelData
                  width: (widgetsCol.width - 16) / 3; height: 32
                  radius: 10
                  color: "#22ffffff"
                  Text { anchors.centerIn: parent; text: "+ " + modelData.label; color: Theme.text; font.family: shellFont.family; font.pixelSize: 12 }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.widgetStore.addWidget(modelData.type)
                  }
                }
              }
            }
            Text { text: "On desktop (" + (root.widgetStore ? root.widgetStore.widgets.length : 0) + "):"; color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12 }
            Repeater {
              model: root.widgetStore ? root.widgetStore.widgets : []
              delegate: Row {
                required property var modelData
                width: widgetsCol.width
                spacing: 8
                Text {
                  width: parent.width - 70
                  anchors.verticalCenter: parent.verticalCenter
                  text: (root.widgetStore ? root.widgetStore.labelFor(modelData.type) : modelData.type) + "  @ " + modelData.x + "," + modelData.y + "  ·  " + (root.widgetStore ? root.widgetStore.sizeLetter(modelData.scale || 1) : "M")
                  color: Theme.text
                  font.family: shellFont.family; font.pixelSize: 12
                  elide: Text.ElideRight
                }
                Rectangle {
                  width: 62; height: 26; radius: 8
                  anchors.verticalCenter: parent.verticalCenter
                  color: "#22ffffff"
                  Text { anchors.centerIn: parent; text: "remove"; color: Theme.red; font.family: shellFont.family; font.pixelSize: 11 }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.widgetStore.removeWidget(modelData.uid) }
                }
              }
            }
            Rectangle {
              width: 130; height: 30; radius: 15
              color: "transparent"
              border.width: 1; border.color: Theme.textMuted
              Text { anchors.centerIn: parent; text: "Reset defaults"; color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12 }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.widgetStore) root.widgetStore.resetDefaults(); } }
            }
          }
        }
      } // dashCol
      } // dashFlick
    }
  }
}
