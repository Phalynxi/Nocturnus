// Glass notification popups. Feeds the Repeater plain data copies:
// a Repeater over QObject arrays crashes Qt 6.11 (see crash log zp91cu86mt).
// Top-right stack, newest first. Click card dismisses, action buttons invoke.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
  ShellFont { id: shellFont }
  id: root

  NotificationServer {
    id: server
    keepOnReload: false
    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true
    // NOTE: arrivals come with tracked=false, so we keep our own list
    onNotification: n => root.push(n)
  }

  // plain-data cards (safe for Repeater); objs maps id -> live object for actions/dismiss
  property var notifs: []
  property var objs: ({})

  function push(n) {
    const acts = [];
    try {
      const al = n.actions;
      for (let i = 0; i < al.length; i++) acts.push({ aid: al[i].identifier, text: al[i].text });
    } catch (e) {}
    const data = {
      nid: n.id,
      app: n.appName || "",
      icon: n.appIcon || "",
      summary: n.summary || "",
      body: n.body || "",
      timeout: n.expireTimeout > 0 ? n.expireTimeout : 6000,
      actions: acts
    };
    const m = Object.assign({}, root.objs);
    m[n.id] = n;
    root.objs = m;
    root.notifs = [data, ...root.notifs].slice(0, 5);
  }

  function drop(nid) {
    root.notifs = root.notifs.filter(d => d.nid !== nid);
    const m = Object.assign({}, root.objs);
    if (m[nid]) {
      try { m[nid].dismiss(); } catch (e) {}
      delete m[nid];
    }
    root.objs = m;
  }

  function act(nid, aid) {
    const o = root.objs[nid];
    if (o) {
      try {
        const al = o.actions;
        for (let i = 0; i < al.length; i++)
          if (al[i].identifier === aid) { al[i].invoke(); break; }
      } catch (e) {}
    }
    root.drop(nid);
  }

  property var currentScreen: {
    const f = Hyprland.focusedMonitor;
    const s = Quickshell.screens.find(scr => f && scr.name === f.name);
    return s ?? Quickshell.screens[0];
  }

  PanelWindow {
    screen: root.currentScreen
    WlrLayershell.namespace: "mynotifs"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region { item: notifCol }

    Column {
      id: notifCol
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.top: parent.top
      anchors.topMargin: 58
      width: 360
      spacing: 8

      Repeater {
        model: root.notifs
        delegate: Rectangle {
          required property var modelData
          property var d: modelData
          width: notifCol.width
          height: cardCol.height + 24
          radius: 18
          color: Theme.ground(0x40/255)

          Timer {
            interval: d.timeout
            running: true
            onTriggered: root.drop(d.nid)
          }

          // dismiss on card click (below content so action buttons win)
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.drop(d.nid)
          }

          Column {
            id: cardCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 6

            Row {
              width: parent.width
              spacing: 10
              Image {
                width: 30; height: 30
                source: d.icon !== "" ? "image://icon/" + d.icon : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
              }
              Lucide {
                visible: d.icon === ""
                name: "bell"; px: 22
              }
              Column {
                width: parent.width - 40
                spacing: 1
                Text {
                  text: (d.app || "") + (d.summary !== "" ? "  ·  " + d.summary : "")
                  color: "#ffffff"
                  font.family: shellFont.family; font.pixelSize: 12; font.bold: true
                  elide: Text.ElideRight
                  width: parent.width
                }
                Text {
                  visible: d.body !== ""
                  text: d.body
                  textFormat: Text.StyledText
                  color: Theme.text
                  font.family: shellFont.family; font.pixelSize: 12
                  wrapMode: Text.Wrap
                  maximumLineCount: 3
                  elide: Text.ElideRight
                  width: parent.width
                }
              }
            }

            Row {
              id: actionRow
              visible: actionRep.count > 0
              width: parent.width
              spacing: 8
              Repeater {
                id: actionRep
                model: d.actions
                delegate: Item {
                  required property var modelData
                  width: actText.width; height: 20
                  Text {
                    id: actText
                    anchors.verticalCenter: parent.verticalCenter
                    text: "［ " + modelData.text + " ］"
                    color: actMa.containsMouse ? "#ffffff" : Theme.textMuted
                    font.family: shellFont.family; font.pixelSize: 12
                  }
                  MouseArea {
                    id: actMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.act(d.nid, modelData.aid)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
