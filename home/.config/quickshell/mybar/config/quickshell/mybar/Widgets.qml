// Desktop widgets: draggable glass cards on a bottom-layer surface.
// Edit mode (dashboard Widgets page, or Super+G) unlocks drag + delete.
// Usage in shell.qml: Widgets { store: widgetStore }
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

Scope {
  ShellFont { id: shellFont }
  id: root
  property var store: null

  function toggleEdit() { if (root.store) root.store.editMode = !root.store.editMode; }

  function parseTodo(p) {
    if (!p) return [];
    const out = [];
    for (const line of p.split("\n")) {
      if (line.trim() === "" || line.length < 2) continue;
      out.push({ text: line.slice(2), done: line.startsWith("1:") });
    }
    return out;
  }
  function serializeTodo(items) {
    return items.map(i => (i.done ? "1:" : "0:") + i.text).join("\n");
  }

  readonly property var quickApps: [
    { name: "Terminal", exec: "kitty",    icon: "kitty" },
    { name: "Files",    exec: "dolphin",  icon: "org.kde.dolphin" },
    { name: "Browser",  exec: "firefox",  icon: "firefox" },
    { name: "Editor",   exec: "code",     icon: "vscode" },
    { name: "Vesktop",  exec: "vesktop",  icon: "vesktop" },
    { name: "Music",    exec: "spotify",  icon: "spotify-client" },
    { name: "Apps",     exec: "QS_LAUNCHER", icon: "lucide:layout-grid" },
    { name: "Keys",     exec: "kitty -e sh -c 'cat ~/.config/hyprrevo/keybinds-reference.md 2>/dev/null || echo no-ref; read'", icon: "lucide:terminal" }
  ]

  readonly property var wallFavs: [
    "/home/octal/WALLPAPERS/04-ambxst-blobs-blue.png",
    "/home/octal/WALLPAPERS/05-ambxst-blobs-purple.png",
    "/home/octal/WALLPAPERS/09-ambxst-gruvbox-dark.png"
  ]

  IpcHandler {
    target: "widgets"
    function toggle(): void { root.toggleEdit(); }
    function toggleVisible(): void { if (root.store) root.store.visible = !root.store.visible; }
    function edit(): void { if (root.store) root.store.editMode = true; }
    function done(): void { if (root.store) root.store.editMode = false; }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      visible: root.store ? root.store.visible : true
      WlrLayershell.namespace: "mywidgets"
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"

      Item {
        anchors.fill: parent

        Repeater {
          model: root.store ? root.store.widgets : []

          delegate: Item {
            required property var modelData
            property var w: modelData
            id: card
            // scalable card: content lays out at base width, whole column zoomed from top-left
            property real s: (w.scale || 1)
            width: w.w * s
            height: cardCol.height * s + 14
            Component.onCompleted: { card.x = w.x; card.y = w.y; }

            property bool editing: root.store && root.store.editMode

            Rectangle {
              anchors.fill: parent
              radius: 18
              color: Theme.ground(0x2b/255)
              border.width: card.editing ? 1 : 0
              border.color: "#66ffffff"
            }

            Column {
              id: cardCol
              x: 12
              y: 7
              width: card.w.w - 24
              scale: card.s
              transformOrigin: Item.TopLeft
              spacing: 6

              // ── edit header: drag handle + size + delete ──
              Row {
                visible: card.editing
                width: parent.width
                height: 24
                spacing: 6
                MouseArea {
                  width: parent.width - 132
                  height: 24
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  drag.target: card
                  drag.axis: Drag.XAndYAxis
                  onReleased: root.store.moveWidget(card.w.uid, card.x, card.y)
                  Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Lucide { name: "more-vertical"; px: 14 }
                    Text {
                      text: root.store ? root.store.labelFor(card.w.type) : card.w.type
                      color: Theme.textMuted
                      font.family: shellFont.family; font.pixelSize: 11
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }
                }
                Repeater {
                  model: [{ label: "S", v: 0.8 }, { label: "M", v: 1.0 }, { label: "L", v: 1.3 }]
                  delegate: Rectangle {
                    required property var modelData
                    width: 30; height: 24
                    radius: 7
                    color: Math.abs((card.w.scale || 1) - modelData.v) < 0.01 ? "#40ffffff" : "transparent"
                    border.width: 1
                    border.color: "#44ffffff"
                    Text {
                      anchors.centerIn: parent
                      text: modelData.label
                      color: "#ffffff"
                      font.family: shellFont.family; font.pixelSize: 11
                      font.bold: Math.abs((card.w.scale || 1) - modelData.v) < 0.01
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.store.setScale(card.w.uid, modelData.v)
                    }
                  }
                }
                Item {
                  width: 24; height: 24
                  Lucide { anchors.centerIn: parent; name: "x"; px: 14 }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.store.removeWidget(card.w.uid) }
                }
              }

              // ── CLOCK ──
              Column {
                visible: card.w.type === "clock"
                width: parent.width
                spacing: 0
                Text {
                  SystemClock { id: wclock; precision: SystemClock.Seconds }
                  text: Qt.formatDateTime(wclock.date, "HH:mm")
                  color: "#ffffff"
                  font.family: shellFont.family; font.pixelSize: 44; font.bold: true
                }
                Text {
                  text: Qt.formatDateTime(wclock.date, "dddd, MMM d")
                  color: Theme.textMuted
                  font.family: shellFont.family; font.pixelSize: 13
                }
              }

              // ── SYSTEM ──
              Item {
                visible: card.w.type === "sys"
                width: parent.width
                height: wsys.height
                SysPanel {
                  id: wsys
                  active: parent.visible
                  width: parent.width
                  onOpenBtop: Quickshell.execDetached(["kitty", "-e", "btop"])
                }
              }

              // ── MEDIA ──
              Item {
                visible: card.w.type === "media"
                width: parent.width
                height: wmedia.height
                MediaPanel { id: wmedia; width: parent.width }
              }

              // ── CALENDAR ──
              Item {
                visible: card.w.type === "calendar"
                width: parent.width
                height: wcal.height
                CalendarPanel { id: wcal; width: parent.width }
              }

              // ── NOTES (saves on focus loss so typing never rebuilds the card) ──
              Column {
                visible: card.w.type === "notes"
                width: parent.width
                spacing: 6
                Text { text: "Notes"; color: "#ffffff"; font.family: shellFont.family; font.pixelSize: 13; font.bold: true }
                Rectangle {
                  width: parent.width; height: 140
                  radius: 12
                  color: Theme.ground(0x22/255)
                  TextEdit {
                    id: noteEdit
                    anchors.fill: parent
                    anchors.margins: 10
                    wrapMode: TextEdit.Wrap
                    color: Theme.text
                    font.family: shellFont.family; font.pixelSize: 12
                    selectByMouse: true
                    Component.onCompleted: noteEdit.text = card.w.payload || ""
                    onActiveFocusChanged: {
                      if (!activeFocus && root.store) root.store.setPayload(card.w.uid, noteEdit.text);
                    }
                  }
                  Text {
                    visible: noteEdit.text === ""
                    anchors.fill: parent
                    anchors.margins: 10
                    text: "Click to write… (saved on click-away)"
                    color: Theme.textMuted
                    font.family: shellFont.family; font.pixelSize: 12
                  }
                }
              }

              // ── TODO ──
              Column {
                id: todoCol
                visible: card.w.type === "todo"
                width: parent.width
                spacing: 6
                property var items: []
                Component.onCompleted: todoCol.items = root.parseTodo(card.w.payload)
                function save() { if (root.store) root.store.setPayload(card.w.uid, root.serializeTodo(todoCol.items)); }
                Text { text: "Todo"; color: "#ffffff"; font.family: shellFont.family; font.pixelSize: 13; font.bold: true }
                Repeater {
                  model: todoCol.items
                  delegate: Row {
                    required property var modelData
                    required property int index
                    width: todoCol.width
                    spacing: 8
                    Rectangle {
                      width: 16; height: 16; radius: 4
                      anchors.verticalCenter: parent.verticalCenter
                      color: modelData.done ? Theme.text : "transparent"
                      border.width: 1; border.color: Theme.textMuted
                      Text { visible: modelData.done; anchors.centerIn: parent; text: "✓"; color: Theme.background; font.pixelSize: 11; font.bold: true }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          const a = todoCol.items.slice();
                          a[index] = { text: a[index].text, done: !a[index].done };
                          todoCol.items = a;
                          todoCol.save();
                        }
                      }
                    }
                    Text {
                      width: parent.width - 48
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.text
                      color: modelData.done ? Theme.textMuted : Theme.text
                      font.family: shellFont.family; font.pixelSize: 12
                      font.strikeout: modelData.done
                      elide: Text.ElideRight
                    }
                    Item {
                      width: 16; height: 16
                      anchors.verticalCenter: parent.verticalCenter
                      Text { anchors.centerIn: parent; text: "×"; color: Theme.textMuted; font.pixelSize: 14 }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          const a = todoCol.items.slice();
                          a.splice(index, 1);
                          todoCol.items = a;
                          todoCol.save();
                        }
                      }
                    }
                  }
                }
                Row {
                  width: parent.width
                  spacing: 6
                  Rectangle {
                    width: parent.width - 34; height: 28; radius: 8
                    color: Theme.ground(0x22/255)
                    TextInput {
                      id: todoInput
                      anchors.fill: parent
                      anchors.leftMargin: 8; anchors.rightMargin: 8
                      verticalAlignment: TextInput.AlignVCenter
                      color: "#ffffff"
                      font.family: shellFont.family; font.pixelSize: 12
                      onAccepted: {
                        if (text.trim() === "") return;
                        todoCol.items = todoCol.items.concat([{ text: text.trim(), done: false }]);
                        text = "";
                        todoCol.save();
                      }
                    }
                    Text {
                      visible: todoInput.text === ""
                      anchors.fill: parent
                      anchors.leftMargin: 8
                      verticalAlignment: Text.AlignVCenter
                      text: "New task… (enter)"
                      color: Theme.textMuted
                      font.family: shellFont.family; font.pixelSize: 12
                    }
                  }
                  Item {
                    width: 28; height: 28
                    Lucide { anchors.centerIn: parent; name: "plus"; px: 16 }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (todoInput.text.trim() === "") return;
                        todoCol.items = todoCol.items.concat([{ text: todoInput.text.trim(), done: false }]);
                        todoInput.text = "";
                        todoCol.save();
                      }
                    }
                  }
                }
              }

              // ── WEATHER (wttr.in, city editable in edit mode) ──
              Column {
                id: wxCol
                visible: card.w.type === "weather"
                width: parent.width
                spacing: 2
                property string cond: "…"
                property string temp: "--"
                property string city: ""
                Component.onCompleted: wxCol.city = card.w.payload || ""
                Timer { interval: 1800000; running: wxCol.visible; repeat: true; onTriggered: wxProc.running = true }
                Process {
                  id: wxProc
                  running: wxCol.visible
                  command: ["sh", "-c", "curl -s 'https://wttr.in/" + (wxCol.city || "") + "?format=%C|%t'"]
                  stdout: StdioCollector {
                    onStreamFinished: {
                      const parts = this.text.trim().split("|");
                      if (parts.length >= 1 && parts[0] !== "") wxCol.cond = parts[0];
                      if (parts.length >= 2) wxCol.temp = parts[1];
                    }
                  }
                }
                Text {
                  text: wxCol.temp
                  color: "#ffffff"
                  font.family: shellFont.family; font.pixelSize: 34; font.bold: true
                }
                Text {
                  text: (wxCol.city !== "" ? wxCol.city + " · " : "") + wxCol.cond
                  color: Theme.textMuted
                  font.family: shellFont.family; font.pixelSize: 12
                  width: parent.width
                  elide: Text.ElideRight
                }
                Row {
                  visible: card.editing
                  width: parent.width
                  spacing: 6
                  Rectangle {
                    width: parent.width - 34; height: 26; radius: 8
                    color: Theme.ground(0x22/255)
                    TextInput {
                      id: cityInput
                      anchors.fill: parent
                      anchors.leftMargin: 8; anchors.rightMargin: 8
                      verticalAlignment: TextInput.AlignVCenter
                      color: "#ffffff"
                      font.family: shellFont.family; font.pixelSize: 12
                      Component.onCompleted: cityInput.text = card.w.payload || ""
                      onAccepted: {
                        wxCol.city = text.trim();
                        if (root.store) root.store.setPayload(card.w.uid, wxCol.city);
                        wxProc.running = true;
                      }
                    }
                    Text {
                      visible: cityInput.text === ""
                      anchors.fill: parent
                      anchors.leftMargin: 8
                      verticalAlignment: Text.AlignVCenter
                      text: "City (empty = auto)"
                      color: Theme.textMuted
                      font.family: shellFont.family; font.pixelSize: 11
                    }
                  }
                  Item {
                    width: 28; height: 26
                    Lucide { anchors.centerIn: parent; name: "check"; px: 14 }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        wxCol.city = cityInput.text.trim();
                        if (root.store) root.store.setPayload(card.w.uid, wxCol.city);
                        wxProc.running = true;
                      }
                    }
                  }
                }
              }

              // ── WALLPAPER ──
              Column {
                visible: card.w.type === "wallpaper"
                width: parent.width
                spacing: 8
                Text { text: "Wallpaper"; color: "#ffffff"; font.family: shellFont.family; font.pixelSize: 13; font.bold: true }
                Row {
                  width: parent.width
                  spacing: 6
                  Repeater {
                    model: root.wallFavs
                    delegate: Image {
                      required property var modelData
                      width: (parent.width - 12) / 3; height: 44
                      source: "file://" + modelData
                      asynchronous: true
                      fillMode: Image.PreserveAspectCrop
                      smooth: true
                      cache: true
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["/home/octal/.local/bin/wp", "img", modelData])
                      }
                    }
                  }
                }
                Row {
                  width: parent.width
                  spacing: 6
                  Rectangle {
                    width: (parent.width - 6) / 2; height: 28; radius: 8
                    color: "#22ffffff"
                    Text { anchors.centerIn: parent; text: "Gallery"; color: "#ffffff"; font.family: shellFont.family; font.pixelSize: 12 }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: Quickshell.execDetached(["quickshell", "-p", "/home/octal/.config/quickshell/mybar/shell.qml", "ipc", "call", "wallpaper", "open"])
                    }
                  }
                  Rectangle {
                    width: (parent.width - 6) / 2; height: 28; radius: 8
                    color: "#22ffffff"
                    Text { anchors.centerIn: parent; text: "Shuffle"; color: "#ffffff"; font.family: shellFont.family; font.pixelSize: 12 }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: Quickshell.execDetached(["sh", "-c", "f=$(ls ~/WALLPAPERS/*.png ~/WALLPAPERS/*.jpg ~/WALLPAPERS/*.gif 2>/dev/null | shuf -n 1); [ -n \"$f\" ] && /home/octal/.local/bin/wp img \"$f\""])
                    }
                  }
                }
              }

              // ── QUICK LAUNCH ──
              Grid {
                visible: card.w.type === "launcher"
                width: parent.width
                columns: 4
                columnSpacing: 4
                rowSpacing: 8
                Repeater {
                  model: root.quickApps
                  delegate: Item {
                    required property var modelData
                    width: (card.w.w - 24 - 12) / 4
                    height: 62
                    Image {
                      anchors.top: parent.top
                      anchors.horizontalCenter: parent.horizontalCenter
                      width: 36; height: 36
                      source: modelData.icon.startsWith("lucide:") ? "" : "image://icon/" + modelData.icon
                      fillMode: Image.PreserveAspectFit
                      smooth: true
                      onStatusChanged: if (status === Image.Error) source = "image://icon/application-x-executable";
                      Lucide { visible: modelData.icon.startsWith("lucide:"); anchors.centerIn: parent; name: modelData.icon.startsWith("lucide:") ? modelData.icon.slice(7) : ""; px: 24 }
                    }
                    Text {
                      anchors.bottom: parent.bottom
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: modelData.name
                      color: Theme.textMuted
                      font.family: shellFont.family; font.pixelSize: 10
                      elide: Text.ElideRight
                      width: parent.width
                      horizontalAlignment: Text.AlignHCenter
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (modelData.exec === "QS_LAUNCHER")
                          Quickshell.execDetached(["quickshell", "-p", "/home/octal/.config/quickshell/mybar/shell.qml", "ipc", "call", "launcher", "toggle"]);
                        else
                          Quickshell.execDetached(["sh", "-c", modelData.exec]);
                      }
                    }
                  }
                }
              }

              // ── NOW PLAYING (frosted player: art + title + controls + waveform) ──
              Item {
                id: npWrap
                visible: card.w.type === "nowplaying"
                width: parent.width
                height: npBox.height
                property var np: {
                  const all = Mpris.players.values;
                  const byId = all.find(p => p.uniqueId === npWrap.pickedId);
                  if (byId) return byId;
                  const c = all.find(p => p.isPlaying && !npWrap.isPaper(p))
                      ?? all.find(p => !npWrap.isPaper(p))
                      ?? all.find(p => p.isPlaying)
                      ?? all[0] ?? null;
                  // auto mode hides the video wallpaper (explicit pick still shows it)
                  if (c && npWrap.pickedId === "" && npWrap.isPaper(c)) return null;
                  return c;
                }
                property real lastVol: 0.8
                property bool muted: false
                property real prog: (npWrap.np && npWrap.np.length > 0) ? Math.min(1, npWrap.np.position / npWrap.np.length) : 0
                // manual player pick (persisted in payload) + wallpaper ignore-list
                property string pickedId: card.w.payload || ""
                property string wallFiles: ""
                function isPaper(p) {
                  if (!p) return false;
                  const t = (p.trackTitle || "").trim();
                  if (t === "") return false;
                  return ("\n" + npWrap.wallFiles + "\n").indexOf("\n" + t + "\n") !== -1;
                }
                function fmt(sec) {
                  if (sec < 0 || isNaN(sec)) return "0:00";
                  const m = Math.floor(sec / 60), s = Math.floor(sec % 60);
                  return m + ":" + (s < 10 ? "0" + s : s);
                }
                function sub() {
                  const p = npWrap.np;
                  if (!p) {
                    const anyPaper = Mpris.players.values.some(pp => npWrap.isPaper(pp));
                    return anyPaper ? "Video wallpaper hidden" : "Play something to begin";
                  }
                  const a = p.trackArtist || "", b = p.trackAlbum || "";
                  if (a && b) return a + "  ·  " + b;
                  return a || b || p.identity || "";
                }
                function cycle() {
                  if (!root.store) return;
                  const ids = Mpris.players.values.map(p => p.uniqueId);
                  if (!ids.length) return;
                  const i = ids.indexOf(npWrap.pickedId);
                  root.store.setPayload(card.w.uid, i + 1 < ids.length ? ids[i + 1] : "");
                }
                Process {
                  id: wallProc
                  running: npWrap.visible
                  command: ["sh", "-c", "ls ~/WALLPAPERS 2>/dev/null"]
                  stdout: StdioCollector {
                    onStreamFinished: npWrap.wallFiles = this.text.trim()
                  }
                }
                Timer { interval: 60000; running: npWrap.visible; repeat: true; onTriggered: wallProc.running = true }
                function seekTo(f) {
                  const p = npWrap.np;
                  if (p && p.lengthSupported && p.canSeek && p.length > 0)
                    p.position = Math.max(0, Math.min(1, f)) * p.length;
                }
                function act(kind) {
                  const p = npWrap.np;
                  if (!p) return;
                  if (kind === "play") p.togglePlaying();
                  else if (kind === "prev" && p.canGoPrevious) p.previous();
                  else if (kind === "next" && p.canGoNext) p.next();
                  else if (kind === "back" && p.canSeek) p.seek(-10);
                  else if (kind === "fwd" && p.canSeek) p.seek(10);
                  else if (kind === "shuffle" && p.shuffleSupported) p.shuffle = !p.shuffle;
                  else if (kind === "vol" && p.volumeSupported) {
                    if (npWrap.muted) { p.volume = npWrap.lastVol; npWrap.muted = false; }
                    else { npWrap.lastVol = p.volume > 0 ? p.volume : 0.8; p.volume = 0; npWrap.muted = true; }
                  }
                }
                Column {
                  id: npBox
                  width: parent.width
                  spacing: 10
                  Row {
                    width: parent.width
                    spacing: 14
                    // album art, rounded via mask (fallback: music icon)
                    Item {
                      width: 140; height: 140
                      Image {
                        id: npArt
                        anchors.fill: parent
                        source: npWrap.np ? npWrap.np.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        cache: true
                        visible: false
                        onStatusChanged: if (status === Image.Error) source = ""
                      }
                      Rectangle {
                        id: npArtMask
                        anchors.fill: parent
                        radius: 14
                        visible: false
                      }
                      OpacityMask {
                        anchors.fill: parent
                        source: npArt
                        maskSource: npArtMask
                        visible: npArt.source !== ""
                      }
                      Rectangle {
                        visible: npArt.source === ""
                        anchors.fill: parent
                        radius: 14
                        color: "#22ffffff"
                        Lucide { anchors.centerIn: parent; name: "music"; px: 48 }
                      }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (npWrap.np) npWrap.np.raise(); }
                      }
                    }
                    // title + artist + controls
                    Column {
                      width: parent.width - 154
                      spacing: 4
                      Text {
                        width: parent.width
                        text: npWrap.np ? (npWrap.np.trackTitle || "Unknown title") : "Nothing playing"
                        color: "#ffffff"
                        font.family: shellFont.family; font.pixelSize: 24; font.bold: true
                        elide: Text.ElideRight
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (npWrap.np) npWrap.np.raise(); } }
                      }
                      Text {
                        width: parent.width
                        text: npWrap.sub()
                        color: Theme.text
                        font.family: shellFont.family; font.pixelSize: 12
                        elide: Text.ElideRight
                      }
                      Text {
                        visible: Mpris.players.values.length > 1
                        width: parent.width
                        text: "via " + (npWrap.np ? npWrap.np.identity : "—") + (npWrap.pickedId === "" ? " (auto)" : "") + " · tap to switch"
                        color: Theme.textMuted
                        font.family: shellFont.family; font.pixelSize: 11
                        elide: Text.ElideRight
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: npWrap.cycle() }
                      }
                      Item { width: 1; height: 4 }
                      Row {
                        width: parent.width
                        height: 46
                        spacing: 8
                        Repeater {
                          model: [
                            { kind: "vol", size: 32 },
                            { kind: "prev", size: 32 },
                            { kind: "back", size: 32 },
                            { kind: "play", size: 46 },
                            { kind: "fwd", size: 32 },
                            { kind: "next", size: 32 },
                            { kind: "shuffle", size: 32 }
                          ]
                          delegate: Item {
                            required property var modelData
                            width: modelData.size; height: 46
                            Rectangle {
                              anchors.centerIn: parent
                              width: modelData.size; height: modelData.size
                              radius: modelData.size / 2
                              color: modelData.kind === "play" ? "#55ffffff"
                                : (modelData.kind === "shuffle" && npWrap.np && npWrap.np.shuffle) ? "#66ffffff" : "#33ffffff"
                            }
                            Lucide {
                              anchors.centerIn: parent
                              px: modelData.kind === "play" ? 22 : 16
                              opacity: {
                                const p = npWrap.np;
                                if (!p) return 0.4;
                                if (modelData.kind === "prev" && !p.canGoPrevious) return 0.35;
                                if (modelData.kind === "next" && !p.canGoNext) return 0.35;
                                if ((modelData.kind === "back" || modelData.kind === "fwd") && !p.canSeek) return 0.35;
                                if (modelData.kind === "shuffle" && !p.shuffleSupported) return 0.35;
                                if (modelData.kind === "vol" && !p.volumeSupported) return 0.35;
                                return 0.9;
                              }
                              name: {
                                const p = npWrap.np;
                                if (modelData.kind === "vol")
                                  return (!p || npWrap.muted || p.volume === 0) ? "volume-x" : (p.volume < 0.5 ? "volume-1" : "volume-2");
                                if (modelData.kind === "play") return (p && p.isPlaying) ? "pause" : "play";
                                if (modelData.kind === "prev") return "skip-back";
                                if (modelData.kind === "next") return "skip-forward";
                                if (modelData.kind === "back") return "rewind";
                                if (modelData.kind === "fwd") return "fast-forward";
                                return "shuffle";
                              }
                            }
                            MouseArea {
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: npWrap.act(modelData.kind)
                              onWheel: wheel => {
                                if (modelData.kind !== "vol") return;
                                const p = npWrap.np;
                                if (!p || !p.volumeSupported) return;
                                p.volume = Math.max(0, Math.min(1, p.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                                npWrap.muted = p.volume === 0;
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                  // waveform seekbar
                  Row {
                    width: parent.width
                    spacing: 8
                    Text {
                      width: 36
                      anchors.verticalCenter: parent.verticalCenter
                      text: npWrap.fmt(npWrap.np ? npWrap.np.position : 0)
                      color: "#ffffff"
                      font.family: shellFont.family; font.pixelSize: 11
                    }
                    Item {
                      width: parent.width - 88
                      height: 28
                      anchors.verticalCenter: parent.verticalCenter
                      Row {
                        anchors.centerIn: parent
                        spacing: 3
                        Repeater {
                          model: 40
                          delegate: Rectangle {
                            required property int index
                            width: 3
                            height: 6 + 20 * (Math.abs(Math.sin(index * 12.9898) * 43758.5453) % 1)
                            radius: 1.5
                            anchors.verticalCenter: parent.verticalCenter
                            color: (index / 40) < npWrap.prog ? "#ffffff" : "#66ffffff"
                          }
                        }
                      }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => npWrap.seekTo(mouse.x / width)
                        onPositionChanged: mouse => { if (pressed) npWrap.seekTo(mouse.x / width); }
                      }
                    }
                    Text {
                      width: 36
                      anchors.verticalCenter: parent.verticalCenter
                      horizontalAlignment: Text.AlignRight
                      text: (npWrap.np && npWrap.np.lengthSupported) ? npWrap.fmt(npWrap.np.length) : "0:00"
                      color: "#ffffff"
                      font.family: shellFont.family; font.pixelSize: 11
                    }
                  }
                }
              }

              Item { width: 1; height: 7 } // bottom padding
            }
          }
        }
      }
    }
  }
}
