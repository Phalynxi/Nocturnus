// TrayMenu — glass context menu for system-tray icons.
// Layer-shell overlay on the mybar-pop namespace, so it inherits the same
// liquid-glass + blur as the other bar popups. Backdrop click / Esc closes.
// One shared instance lives in shell.qml: trayMenuPopup.open(item, iconItem)
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
  ShellFont { id: shellFont }
  id: root

  property bool isOpen: false
  property real cardX: 0
  property var curScreen: null
  property int rounding: 14

  function open(item, iconItem) {
    if (!item || !item.hasMenu) return;
    opener.menu = item.menu;
    const scr = iconItem.QsWindow.screen ?? Quickshell.screens[0];
    root.curScreen = scr;
    const p = iconItem.mapToItem(null, 0, 0);
    const maxX = (scr ? scr.width : 1366) - 238;
    root.cardX = Math.max(8, Math.min(p.x, maxX));
    root.isOpen = true;
  }

  function close() {
    root.isOpen = false;
  }

  QsMenuOpener { id: opener }

  PanelWindow {
    visible: root.isOpen
    screen: root.curScreen ?? Quickshell.screens[0]

    WlrLayershell.namespace: "mybar-pop"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region { item: menuCard }

    // click anywhere else closes
    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }

    Item {
      focus: true
      anchors.fill: parent
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true; }
      }
    }

    Rectangle {
      id: menuCard
      x: root.cardX
      y: 54
      width: 230
      height: menuCol.implicitHeight + 16
      radius: root.rounding
      color: Theme.ground(0x2b/255)

      Column {
        id: menuCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        spacing: 2

        Text {
          visible: opener.children.values.length === 0
          width: parent.width - 16
          text: "No menu items"
          color: Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 12
          horizontalAlignment: Text.AlignHCenter
        }

        Repeater {
          model: opener.children
          delegate: Item {
            required property var modelData
            width: menuCol.width - 16
            height: modelData.isSeparator ? 9 : 30

            Rectangle {
              visible: modelData.isSeparator
              anchors.centerIn: parent
              width: parent.width - 8
              height: 1
              color: "#33ffffff"
            }

            Rectangle {
              visible: !modelData.isSeparator
              anchors.fill: parent
              radius: 8
              color: rowMa.containsMouse && modelData.enabled ? "#40ffffff" : "transparent"
              Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8
                Text {
                  visible: modelData.buttonType !== QsMenuButtonType.None
                  anchors.verticalCenter: parent.verticalCenter
                  width: 14
                  text: modelData.checkState === Qt.Checked ? "✓" : ""
                  color: "#ffffff"
                  font.family: shellFont.family; font.pixelSize: 12
                }
                Image {
                  visible: (modelData.icon || "") !== ""
                  anchors.verticalCenter: parent.verticalCenter
                  width: 16; height: 16
                  source: modelData.icon || ""
                  sourceSize.width: 16
                  sourceSize.height: 16
                  smooth: true
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - 20 - ((modelData.icon || "") !== "" ? 24 : 0)
                  text: modelData.text
                  color: modelData.enabled ? "#ffffff" : Theme.textMuted
                  font.family: shellFont.family; font.pixelSize: 12
                  elide: Text.ElideRight
                }
              }
              MouseArea {
                id: rowMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: modelData.enabled
                onClicked: {
                  modelData.triggered();
                  root.close();
                }
              }
            }
          }
        }
      }
    }
  }
}
