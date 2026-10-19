// Glass app launcher: icon grid + modes (!run, =calc, >power).
// Toggle: quickshell -p .../mybar/shell.qml ipc call launcher toggle  (Super+R)
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io

Scope {
  ShellFont { id: shellFont }
  id: root
  property bool open: false
  property string query: ""
  property int selected: 0

  // modes from first character
  property string mode: query.startsWith("!") ? "run" : query.startsWith("=") ? "calc" : query.startsWith(">") ? "power" : "apps"
  property string modeArg: query.length > 1 ? query.slice(1).trim() : ""

  property var filtered: []
  property var powerActions: []
  property string calcOut: ""

  readonly property int cols: 6
  readonly property int maxApps: 18

  readonly property var allPower: [
    { name: "Shutdown", icon: "power",      cmd: ["systemctl", "poweroff"] },
    { name: "Reboot",   icon: "rotate-ccw", cmd: ["systemctl", "reboot"] },
    { name: "Logout",   icon: "log-out",    cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
    { name: "Suspend",  icon: "moon",       cmd: ["systemctl", "suspend"] },
    { name: "Lock",     icon: "lock",       cmd: ["hyprlock"] }
  ]

  function allApps() {
    const out = [];
    for (const a of DesktopEntries.applications.values) {
      if (!a.noDisplay && a.name) out.push(a);
    }
    return out;
  }

  // tiny math evaluator (QML has no eval): + - * / % ^, parens, unary minus
  function calcEval(src) {
    const s = src.replace(/\s+/g, "");
    if (s === "" || /[^0-9+\-*/%^().]/.test(s)) return null;
    const toks = [];
    let i = 0;
    while (i < s.length) {
      const c = s[i];
      if (/[0-9.]/.test(c)) {
        let j = i;
        while (j < s.length && /[0-9.]/.test(s[j])) j++;
        const raw = s.slice(i, j);
        if (!/^\d+(\.\d+)?$/.test(raw)) return null;
        toks.push(parseFloat(raw)); i = j;
      } else if ("+-*/%^()".includes(c)) { toks.push(c); i++; }
      else return null;
    }
    const prec = { "+": 1, "-": 1, "*": 2, "/": 2, "%": 2, "^": 3, "u": 4 };
    const right = { "^": true, "u": true };
    const out = [], ops = [];
    let prev = null;
    for (const t of toks) {
      if (typeof t === "number") { out.push(t); prev = "v"; continue; }
      if (t === "(") { ops.push(t); prev = "("; continue; }
      if (t === ")") {
        while (ops.length && ops[ops.length - 1] !== "(") out.push(ops.pop());
        if (!ops.length) return null;
        ops.pop(); prev = "v"; continue;
      }
      let op = t;
      if ((t === "-" || t === "+") && (prev === null || prev === "op" || prev === "(")) {
        if (t === "+") { prev = "op"; continue; }
        op = "u";
      }
      while (ops.length) {
        const top = ops[ops.length - 1];
        if (top === "(") break;
        if ((right[op] && prec[op] < prec[top]) || (!right[op] && prec[op] <= prec[top])) out.push(ops.pop());
        else break;
      }
      ops.push(op); prev = "op";
    }
    while (ops.length) {
      const o = ops.pop();
      if (o === "(") return null;
      out.push(o);
    }
    const st = [];
    for (const t of out) {
      if (typeof t === "number") { st.push(t); continue; }
      if (t === "u") { if (!st.length) return null; st.push(-st.pop()); continue; }
      if (st.length < 2) return null;
      const b = st.pop(), a = st.pop();
      if (t === "+") st.push(a + b);
      else if (t === "-") st.push(a - b);
      else if (t === "*") st.push(a * b);
      else if (t === "/") { if (b === 0) return null; st.push(a / b); }
      else if (t === "%") st.push(a % b);
      else if (t === "^") st.push(Math.pow(a, b));
    }
    if (st.length !== 1 || !isFinite(st[0])) return null;
    return Number(st[0].toPrecision(10)).toString();
  }

  function refilter() {
    root.selected = 0;
    if (root.mode === "apps") {
      const q = root.query.trim().toLowerCase();
      let list = root.allApps();
      if (q.length > 0) {
        const starts = [], contains = [];
        for (const a of list) {
          const n = (a.name + " " + (a.genericName || "")).toLowerCase();
          if (n.startsWith(q)) starts.push(a);
          else if (n.includes(q)) contains.push(a);
        }
        list = starts.concat(contains);
      } else {
        list.sort((a, b) => a.name.localeCompare(b.name));
      }
      root.filtered = list.slice(0, root.maxApps);
    } else if (root.mode === "power") {
      const q = root.modeArg.toLowerCase();
      root.powerActions = root.allPower.filter(a => a.name.toLowerCase().includes(q));
    } else if (root.mode === "calc") {
      root.calcOut = root.calcEval(root.modeArg) ?? "";
    }
  }

  function launchApp(entry) {
    if (!entry) return;
    entry.execute();
    root.close();
  }

  function activate() {
    if (root.mode === "apps") {
      if (root.filtered.length > 0)
        root.launchApp(root.filtered[Math.min(root.selected, root.filtered.length - 1)]);
    } else if (root.mode === "run") {
      if (root.modeArg !== "") Quickshell.execDetached(["sh", "-c", root.modeArg]);
      root.close();
    } else if (root.mode === "calc") {
      if (root.calcOut !== "") Quickshell.execDetached(["sh", "-c", "printf '%s' '" + root.calcOut + "' | wl-copy"]);
      root.close();
    } else if (root.mode === "power") {
      const a = root.powerActions[Math.min(root.selected, root.powerActions.length - 1)];
      if (a) Quickshell.execDetached(a.cmd);
      root.close();
    }
  }

  function moveSelection(dx, dy) {
    if (root.mode === "apps") {
      const n = root.filtered.length;
      if (n === 0) return;
      let s = root.selected + dx + dy * root.cols;
      s = Math.max(0, Math.min(n - 1, s));
      root.selected = s;
    } else if (root.mode === "power") {
      const n = root.powerActions.length;
      if (n === 0) return;
      root.selected = Math.max(0, Math.min(n - 1, root.selected + dy + dx));
    }
  }

  function openLauncher() {
    searchInput.text = "";
    root.query = "";
    root.refilter();
    root.open = true;
  }
  function close() { root.open = false; }
  function toggle() { root.open ? root.close() : root.openLauncher(); }

  IpcHandler {
    target: "launcher"
    function toggle(): void { root.toggle(); }
    function open(): void { root.openLauncher(); }
    function close(): void { root.close(); }
  }

  Connections {
    target: DesktopEntries
    function onApplicationsChanged() { root.refilter(); }
  }

  onOpenChanged: if (open) searchInput.forceActiveFocus()

  property var currentScreen: {
    const f = Hyprland.focusedMonitor;
    const s = Quickshell.screens.find(scr => f && scr.name === f.name);
    return s ?? Quickshell.screens[0];
  }

  // BACKDROP: plain blur + dim
  PanelWindow {
    visible: root.open
    screen: root.currentScreen
    WlrLayershell.namespace: "mylauncher-bg"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    Rectangle { anchors.fill: parent; color: "#4d000000" }
    MouseArea { anchors.fill: parent; onClicked: root.close() }
  }

  // PANEL: liquid glass, input masked to content
  PanelWindow {
    visible: root.open
    screen: root.currentScreen
    WlrLayershell.namespace: "mylauncher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region { item: launcherCol }

    Column {
      id: launcherCol
      property bool shown: root.open
      opacity: shown ? 1 : 0
      transform: Translate { y: launcherCol.shown ? 0 : 16; Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } }
      Behavior on opacity { NumberAnimation { duration: 200 } }
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 120
      width: 640
      spacing: 12

      // search pill
      Rectangle {
        width: parent.width; height: 56
        radius: 18
        color: Theme.ground(0x40/255)
        Row {
          anchors.fill: parent
          anchors.leftMargin: 18; anchors.rightMargin: 18
          spacing: 12
          Lucide {
            anchors.verticalCenter: parent.verticalCenter
            name: root.mode === "run" ? "terminal" : root.mode === "calc" ? "calculator" : root.mode === "power" ? "power" : "search"
            px: 20
          }
          TextInput {
            id: searchInput
            width: parent.width - 32
            anchors.verticalCenter: parent.verticalCenter
            color: "#ffffff"
            font.family: shellFont.family; font.pixelSize: 17
            focus: true
            onTextChanged: { root.query = text; root.refilter(); }
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true; }
              else if (event.key === Qt.Key_Left) { root.moveSelection(-1, 0); event.accepted = true; }
              else if (event.key === Qt.Key_Right) { root.moveSelection(1, 0); event.accepted = true; }
              else if (event.key === Qt.Key_Up) { root.moveSelection(0, -1); event.accepted = true; }
              else if (event.key === Qt.Key_Down) { root.moveSelection(0, 1); event.accepted = true; }
              else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.activate(); event.accepted = true; }
            }
          }
        }
        Text {
          visible: searchInput.text === ""
          anchors.fill: parent
          anchors.leftMargin: 50; anchors.rightMargin: 18
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
          text: "Search apps…   (!run   =calc   >power)"
          color: Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 15
        }
      }

      // results glass panel
      Rectangle {
        width: parent.width
        height: resultsCol.height + 28
        radius: 18
        color: Theme.ground(0x33/255)
        visible: root.mode !== "apps" || root.filtered.length > 0

        Column {
          id: resultsCol
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: 14
          spacing: 4

          // APPS grid
          GridView {
            id: appGrid
            visible: root.mode === "apps"
            width: parent.width
            height: Math.max(1, Math.ceil(Math.min(root.filtered.length, root.maxApps) / root.cols)) * 100
            clip: true
            cellWidth: parent.width / root.cols
            cellHeight: 100
            interactive: false
            model: root.filtered
            currentIndex: root.selected
            delegate: Item {
              required property var modelData
              required property int index
              width: appGrid.cellWidth; height: 100
              property bool sel: index === root.selected
              Column {
                anchors.centerIn: parent
                spacing: 4
                Image {
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: sel ? 56 : 48; height: sel ? 56 : 48
                  source: modelData.icon ? "image://icon/" + modelData.icon : "image://icon/application-x-executable"
                  fillMode: Image.PreserveAspectFit
                  smooth: true
                  opacity: sel ? 1 : 0.75
                  onStatusChanged: if (status === Image.Error) source = "image://icon/application-x-executable"
                  Behavior on width { NumberAnimation { duration: 120 } }
                  Behavior on height { NumberAnimation { duration: 120 } }
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.name
                  color: sel ? "#ffffff" : Theme.textMuted
                  font.family: shellFont.family; font.pixelSize: 11
                  font.bold: sel
                  elide: Text.ElideRight
                  width: appGrid.cellWidth - 12
                  horizontalAlignment: Text.AlignHCenter
                }
              }
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selected = index
                onClicked: root.launchApp(modelData)
              }
            }
          }

          // RUN mode
          Row {
            visible: root.mode === "run"
            width: parent.width
            spacing: 12
            Lucide { name: "terminal"; px: 22 }
            Text {
              width: parent.width - 34
              anchors.verticalCenter: parent.verticalCenter
              text: root.modeArg === "" ? "Type a command…" : "Run:  " + root.modeArg
              color: "#ffffff"
              font.family: shellFont.family; font.pixelSize: 14
              elide: Text.ElideRight
            }
          }

          // CALC mode
          Row {
            visible: root.mode === "calc"
            width: parent.width
            spacing: 12
            Lucide { name: "calculator"; px: 22 }
            Text {
              width: parent.width - 34
              anchors.verticalCenter: parent.verticalCenter
              text: root.calcOut === "" ? "Invalid expression" : "=  " + root.calcOut + "   (enter copies)"
              color: root.calcOut === "" ? Theme.textMuted : "#ffffff"
              font.family: shellFont.family; font.pixelSize: 16; font.bold: true
              elide: Text.ElideRight
            }
          }

          // POWER mode
          Repeater {
            model: root.mode === "power" ? root.powerActions : []
            delegate: Row {
              required property var modelData
              required property int index
              width: resultsCol.width
              spacing: 12
              property bool sel: index === root.selected
              Lucide { name: modelData.icon; px: 20; opacity: sel ? 1 : 0.6 }
              Text {
                text: modelData.name
                color: sel ? "#ffffff" : Theme.textMuted
                font.family: shellFont.family; font.pixelSize: 14
                font.bold: sel
                anchors.verticalCenter: parent.verticalCenter
              }
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selected = index
                onClicked: { Quickshell.execDetached(modelData.cmd); root.close(); }
              }
            }
          }
        }
      }
    }
  }

  Component.onCompleted: root.refilter()
}
