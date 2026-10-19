//@ pragma UseQApplication
// mybar - floating liquid-glass top bar for Hyprland
// Run: quickshell -p ~/.config/quickshell/mybar/shell.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Io
import Qt5Compat.GraphicalEffects

ShellRoot {
  ShellFont { id: shellFont }
  id: root

  // ── dock settings (persisted to dock.json, edited from dashboard Dock page) ──
  DockSettings { id: dockStore }

  // ── desktop widgets (persisted to widgets.json, edited from dashboard Widgets page / Super+G) ──
  WidgetStore { id: widgetStore }

  // blur-behind for bar/dock/widgets (toggles hyprland handles from hyprland.lua)
  // + global liquid-glass intensity (thickness) and corner radius
  // + gaming mode: master off-switch for all glass + decoration blur
  // toolbox glass follows open state (ball r21 vs orbs r28 need own edge maps)
  function syncToolboxGlass() {
    Quickshell.execDetached(["hyprctl", "eval", "mytoolsBallGlass:set_enabled(" + (!dockStore.toolboxOpen ? "true" : "false") + ")"]);
    Quickshell.execDetached(["hyprctl", "eval", "mytoolsOrbGlass:set_enabled(" + (dockStore.toolboxOpen ? "true" : "false") + ")"]);
  }
  function applyGlassBlur() {
    if (dockStore.gamingMode) {
      Quickshell.execDetached(["hyprctl", "eval", "hl.config({plugin={hyprliquid={enabled=false}}})"]);
      Quickshell.execDetached(["hyprctl", "eval", "hl.config({decoration={blur={enabled=false}}})"]);
      return;
    }
    Quickshell.execDetached(["hyprctl", "eval", "hl.config({plugin={hyprliquid={enabled=true}}})"]);
    Quickshell.execDetached(["hyprctl", "eval", "hl.config({decoration={blur={enabled=true}}})"]);
    Quickshell.execDetached(["hyprctl", "eval", "mybarBlur:set_enabled(" + (dockStore.barBlur ? "true" : "false") + ")"]);
    Quickshell.execDetached(["hyprctl", "eval", "mytoolsBlur:set_enabled(" + (dockStore.barBlur ? "true" : "false") + ")"]);
    Quickshell.execDetached(["hyprctl", "eval", "mydockBlur:set_enabled(" + (dockStore.dockBlur ? "true" : "false") + ")"]);
    Quickshell.execDetached(["hyprctl", "eval", "mywidgetsGlass:set_enabled(" + (widgetStore.glass ? "true" : "false") + ")"]);
    Quickshell.execDetached(["hyprctl", "eval", "mywidgetsBlur:set_enabled(" + (widgetStore.blur ? "true" : "false") + ")"]);
    const thick = Math.round(100 + dockStore.glassLevel * 8);
    Quickshell.execDetached(["hyprctl", "eval", "hl.config({plugin={hyprliquid={glass_thickness=" + thick + ",corner_radius=" + dockStore.rounding + "}}})"]);
  }
  Connections {
    target: dockStore
    function onBarBlurChanged() { root.applyGlassBlur(); }
    function onDockBlurChanged() { root.applyGlassBlur(); }
    function onRoundingChanged() { root.applyGlassBlur(); }
    function onGlassLevelChanged() { root.applyGlassBlur(); }
    function onGamingModeChanged() {
      root.applyGlassBlur();
      Quickshell.execDetached(["notify-send", "Gaming mode", dockStore.gamingMode ? "ON — glass + blur off" : "OFF — effects restored"]);
    }
    function onToolboxOpenChanged() { root.syncToolboxGlass(); }
  }

  IpcHandler {
    target: "gaming"
    function toggle(): void { dockStore.gamingMode = !dockStore.gamingMode; }
    function on(): void { dockStore.gamingMode = true; }
    function off(): void { dockStore.gamingMode = false; }
  }

  IpcHandler {
    target: "toolbox"
    function toggle(): void {
      dockStore.toolboxOpen = !dockStore.toolboxOpen;
      if (dockStore.toolboxOpen) dockStore.playerExpanded = false;
    }
  }
  Connections {
    target: widgetStore
    function onGlassChanged() { root.applyGlassBlur(); }
    function onBlurChanged() { root.applyGlassBlur(); }
  }

  property var clients: []

  // live width of the center media pill (toolbox ball anchors to its edge)
  property int mediaIslandW: 328

  // ── dock autohide: show = always, auto = empty workspace or hover, hide = hover only ──
  property bool dockHover: false
  property bool dockEdgeHover: false
  property bool workspaceEmpty: {
    const fw = Hyprland.focusedWorkspace;
    if (!fw) return true;
    return !Hyprland.toplevels.values.some(t => t.workspace && t.workspace.id === fw.id);
  }
  property bool dockOpen: dockStore.autohide === "show" ? true
    : dockStore.autohide === "hide" ? (root.dockHover || root.dockEdgeHover)
    : (root.dockHover || root.dockEdgeHover || root.workspaceEmpty)

  // ── bar popups: "volume" | "media" | "calendar" | "sys" | "power" | "overview" | "" ──
  property string popup: ""
  function togglePopup(name) { root.popup = (root.popup === name ? "" : name); }

  // lightweight stats for the bar (popup polls faster while open)
  property string sysCpu: "--"
  property string sysMem: "--"
  property string sysTemp: "--"
  property string netUp: ""
  Timer { interval: 3000; running: true; repeat: true; onTriggered: sysProc.running = true }
  Process {
    id: sysProc
    running: true
    command: ["/home/octal/.local/bin/sysstat"]
    stdout: StdioCollector {
      onStreamFinished: {
        const m = this.text.match(/CPU=(\d+) MEM=(\d+) TEMP=(\d+)/);
        if (m) { root.sysCpu = m[1]; root.sysMem = m[2]; root.sysTemp = m[3]; }
        const n = this.text.match(/NET=(up|down)/);
        if (n) root.netUp = n[1];
      }
    }
  }

  IpcHandler {
    target: "popups"
    function toggle(name: string): void { root.togglePopup(name); }
    function close(): void { root.popup = ""; }
  }

  Connections {
    target: Hyprland
    function onRawEvent(ev) {
      if (ev.name.endsWith("v2") || ev.name === "openwindow" || ev.name === "closewindow"
        || ev.name === "movewindow" || ev.name === "changefloatingmode") {
        clientsTimer.restart();
      }
    }
  }
  Timer { id: clientsTimer; interval: 250; onTriggered: root.clients = Hyprland.toplevels.values }
  Component.onCompleted: { clientsTimer.start(); root.applyGlassBlur(); root.syncToolboxGlass(); }

  // glass app launcher overlay (Super+R)
  Launcher { id: launcher }

  // glass wallpaper gallery (Super+W)
  WallpaperMenu { id: wallpapers }

  // bar widget popups (volume mixer / media / calendar)
  Popups { current: root.popup; onClosed: root.popup = ""; rounding: dockStore.rounding; dockStore: dockStore; widgetStore: widgetStore }

  // glass notification popups (plain-data Repeater: crash-safe)
  Notifications {}

  // dashboard overlay (Super+D)
  Dashboard { dockStore: dockStore; widgetStore: widgetStore }

  // shared glass tray menu (right-click on tray icons)
  TrayMenu { id: trayMenuPopup; rounding: dockStore.rounding }

  // desktop widgets (drag in edit mode via dashboard Widgets page or Super+G)
  Widgets { store: widgetStore }

  // ── bar island clusters (copies of the full-bar clusters below, used when
  // barStyle === "islands"; kept in sync by hand) ──
  Component {
    id: islandLeftCluster
    Row {
      spacing: 10
      Item {
        width: 26; height: 26
        Lucide { anchors.centerIn: parent; name: "layout-grid"; px: 17; opacity: launcherBtn.containsMouse ? 1 : 0.75 }
        MouseArea {
          id: launcherBtn
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: launcher.toggle()
        }
      }
      Row {
        spacing: 6
        Repeater {
          model: [...Hyprland.workspaces.values].sort((a, b) => a.id - b.id)
          Rectangle {
            required property var modelData
            property var ws: modelData
            property bool focused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === ws.id
            width: focused ? 38 : 30; height: 26
            radius: dockStore.rounding
            color: focused ? "#40ffffff" : ws.active ? "#22ffffff" : "transparent"
            Behavior on width { NumberAnimation { duration: 150 } }
            Text {
              anchors.centerIn: parent
              text: ws.name
              color: focused ? "#ffffff" : Theme.textMuted
              font.family: shellFont.family
              font.pixelSize: 13
              font.bold: focused
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (focused) root.togglePopup("overview");
                else Hyprland.dispatch("workspace " + ws.id);
              }
            }
          }
        }
        Repeater {
          model: Hyprland.workspaces.values.length === 0 ? [1, 2, 3, 4, 5] : []
          Rectangle {
            required property var modelData
            width: 30; height: 26; radius: dockStore.rounding
            color: "transparent"
            Text { anchors.centerIn: parent; text: modelData; color: Theme.textMuted; font.pixelSize: 13 }
            MouseArea { anchors.fill: parent; onClicked: Hyprland.dispatch("workspace " + modelData) }
          }
        }
      }
    }
  }


  Component {
    id: islandCenterCluster
    // expandable mini player: collapsed chip, click morphs into full player card
    Column {
      id: islandPlayer
      spacing: 8
      property bool expanded: dockStore.playerExpanded
      function isVid(p) {
        const t = (p && p.trackTitle) || "";
        return /\.(mp4|mkv|webm|avi|mov|gif)$/i.test(t.trim());
      }
      property var player: {
        const all = Mpris.players.values;
        return all.find(p => p.isPlaying && !islandPlayer.isVid(p))
            ?? all.find(p => !islandPlayer.isVid(p))
            ?? null;
      }
      // NOTE: no auto-collapse on null player here on purpose: wantOpen already
      // hides the island, and resetting the stored flag fights the user.
      function fmt(sec) {
        if (sec < 0 || isNaN(sec)) return "0:00";
        const m = Math.floor(sec / 60), s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" + s : s);
      }
      function prog() {
        const p = islandPlayer.player;
        return (p && p.length > 0) ? Math.min(1, p.position / p.length) : 0;
      }
      function seekTo(f) {
        const p = islandPlayer.player;
        if (p && p.lengthSupported && p.canSeek && p.length > 0)
          p.position = Math.max(0, Math.min(1, f)) * p.length;
      }
      function act(kind) {
        const p = islandPlayer.player;
        if (!p) return;
        if (kind === "play") p.togglePlaying();
        else if (kind === "prev" && p.canGoPrevious) p.previous();
        else if (kind === "next" && p.canGoNext) p.next();
        else if (kind === "back" && p.canSeek) p.seek(-10);
        else if (kind === "fwd" && p.canSeek) p.seek(10);
        else if (kind === "shuffle" && p.shuffleSupported) p.shuffle = !p.shuffle;
      }

      // ── collapsed chip ──
      Row {
        visible: !islandPlayer.expanded
        spacing: 8
        Item {
          width: 28; height: 28
          anchors.verticalCenter: parent.verticalCenter
          Image {
            anchors.fill: parent
            source: islandPlayer.player ? islandPlayer.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            cache: true
            visible: status !== Image.Error && source !== ""
            onStatusChanged: if (status === Image.Error) source = ""
          }
          Lucide {
            visible: !islandPlayer.player || islandPlayer.player.trackArtUrl === ""
            anchors.centerIn: parent
            name: "music"; px: 18
          }
        }
        Item {
          width: 170; height: 28
          anchors.verticalCenter: parent.verticalCenter
          Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 0
            Text {
              width: parent.width
              text: islandPlayer.player ? (islandPlayer.player.trackTitle || "Unknown") : "Nothing playing"
              color: "#ffffff"
              font.family: shellFont.family; font.pixelSize: 12; font.bold: true
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              text: islandPlayer.player ? (islandPlayer.player.trackArtist || islandPlayer.player.identity || "") : "Play something"
              color: Theme.textMuted
              font.family: shellFont.family; font.pixelSize: 10
              elide: Text.ElideRight
            }
          }
        }
        Row {
          spacing: 6
          anchors.verticalCenter: parent.verticalCenter
          Repeater {
            model: [
              { kind: "prev", icon: "skip-back" },
              { kind: "play", icon: (islandPlayer.player && islandPlayer.player.isPlaying) ? "pause" : "play" },
              { kind: "next", icon: "skip-forward" }
            ]
            delegate: Item {
              required property var modelData
              width: 26; height: 26
              Rectangle {
                anchors.fill: parent
                radius: 13
                color: modelData.kind === "play" ? "#55ffffff" : "#33ffffff"
              }
              Lucide {
                anchors.centerIn: parent
                name: modelData.icon
                px: 14
                opacity: {
                  const p = islandPlayer.player;
                  if (!p) return 0.35;
                  if (modelData.kind === "prev" && !p.canGoPrevious) return 0.35;
                  if (modelData.kind === "next" && !p.canGoNext) return 0.35;
                  return 0.9;
                }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: islandPlayer.act(modelData.kind)
              }
            }
          }
        }
      }

      // ── expanded full player ──
      Column {
        visible: islandPlayer.expanded
        width: 400
        spacing: 10
        Row {
          width: parent.width
          spacing: 6
          Text {
            width: parent.width - 30
            text: "Now playing"
            color: Theme.textMuted
            font.family: shellFont.family; font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
          }
          Item {
            width: 24; height: 20
            anchors.verticalCenter: parent.verticalCenter
            Text { anchors.centerIn: parent; text: "▾"; color: Theme.textMuted; font.pixelSize: 14 }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { if (dockStore) dockStore.playerExpanded = false; }
            }
          }
        }
        Row {
          width: parent.width
          spacing: 12
          Item {
            width: 110; height: 110
            Image {
              id: islArt
              anchors.fill: parent
              source: islandPlayer.player ? islandPlayer.player.trackArtUrl : ""
              fillMode: Image.PreserveAspectCrop
              smooth: true
              asynchronous: true
              cache: true
              visible: false
            }
            Rectangle {
              id: islArtMask
              anchors.fill: parent
              radius: 14
              visible: false
            }
            OpacityMask {
              anchors.fill: parent
              source: islArt
              maskSource: islArtMask
              visible: islArt.source !== ""
            }
            Rectangle {
              visible: islArt.source === ""
              anchors.fill: parent
              radius: 14
              color: "#22ffffff"
              Lucide { anchors.centerIn: parent; name: "music"; px: 40 }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { if (islandPlayer.player) islandPlayer.player.raise(); }
            }
          }
          Column {
            width: parent.width - 122
            spacing: 6
            Text {
              width: parent.width
              text: islandPlayer.player ? (islandPlayer.player.trackTitle || "Unknown title") : "Nothing playing"
              color: "#ffffff"
              font.family: shellFont.family; font.pixelSize: 17; font.bold: true
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              text: {
                const p = islandPlayer.player;
                if (!p) return "Play something to begin";
                const a = p.trackArtist || "", b = p.trackAlbum || "";
                if (a && b) return a + "  ·  " + b;
                return a || b || p.identity || "";
              }
              color: Theme.text
              font.family: shellFont.family; font.pixelSize: 11
              elide: Text.ElideRight
            }
            Row {
              spacing: 8
              Repeater {
                model: [
                  { kind: "prev", size: 30 },
                  { kind: "back", size: 30 },
                  { kind: "play", size: 40 },
                  { kind: "fwd", size: 30 },
                  { kind: "next", size: 30 },
                  { kind: "shuffle", size: 30 }
                ]
                delegate: Item {
                  required property var modelData
                  width: modelData.size; height: 40
                  Rectangle {
                    anchors.centerIn: parent
                    width: modelData.size; height: modelData.size
                    radius: modelData.size / 2
                    color: modelData.kind === "play" ? "#55ffffff"
                      : (modelData.kind === "shuffle" && islandPlayer.player && islandPlayer.player.shuffle) ? "#66ffffff" : "#33ffffff"
                  }
                  Lucide {
                    anchors.centerIn: parent
                    px: modelData.kind === "play" ? 18 : 14
                    opacity: {
                      const p = islandPlayer.player;
                      if (!p) return 0.35;
                      if (modelData.kind === "prev" && !p.canGoPrevious) return 0.35;
                      if (modelData.kind === "next" && !p.canGoNext) return 0.35;
                      if ((modelData.kind === "back" || modelData.kind === "fwd") && !p.canSeek) return 0.35;
                      if (modelData.kind === "shuffle" && !p.shuffleSupported) return 0.35;
                      return 0.9;
                    }
                    name: {
                      const p = islandPlayer.player;
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
                    cursorShape: Qt.PointingHandCursor
                    onClicked: islandPlayer.act(modelData.kind)
                  }
                }
              }
            }
          }
        }
        Row {
          width: parent.width
          spacing: 8
          Text {
            width: 34
            anchors.verticalCenter: parent.verticalCenter
            text: islandPlayer.fmt(islandPlayer.player ? islandPlayer.player.position : 0)
            color: "#ffffff"
            font.family: shellFont.family; font.pixelSize: 11
          }
          Item {
            width: parent.width - 84
            height: 26
            anchors.verticalCenter: parent.verticalCenter
            Row {
              anchors.centerIn: parent
              spacing: 3
              Repeater {
                model: 44
                delegate: Rectangle {
                  required property int index
                  width: 3
                  height: 5 + 17 * (Math.abs(Math.sin(index * 12.9898) * 43758.5453) % 1)
                  radius: 1.5
                  anchors.verticalCenter: parent.verticalCenter
                  color: (index / 44) < islandPlayer.prog() ? "#ffffff" : "#66ffffff"
                }
              }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: mouse => islandPlayer.seekTo(mouse.x / width)
              onPositionChanged: mouse => { if (pressed) islandPlayer.seekTo(mouse.x / width); }
            }
          }
          Text {
            width: 34
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: (islandPlayer.player && islandPlayer.player.lengthSupported) ? islandPlayer.fmt(islandPlayer.player.length) : "0:00"
            color: "#ffffff"
            font.family: shellFont.family; font.pixelSize: 11
          }
        }
      }
    }
  }

  Component {
    id: islandToolboxCluster
    // toolbox ball: collapsed circle, click morphs into tool panel
    Column {
      id: toolboxBox
      spacing: 8
      property bool expanded: dockStore.toolboxOpen
      property bool recording: false
      Timer { interval: 3000; running: true; repeat: true; onTriggered: recProc.running = true }
      Process {
        id: recProc
        command: ["sh", "-c", "pgrep -x wf-recorder >/dev/null && echo yes || echo no"]
        stdout: StdioCollector {
          onStreamFinished: toolboxBox.recording = this.text.trim() === "yes"
        }
      }
      function toggle() {
        if (!dockStore) return;
        const open = !dockStore.toolboxOpen;
        dockStore.toolboxOpen = open;
        if (open) dockStore.playerExpanded = false;
      }
      // collapsed ball (blinks while recording)
      Item {
        visible: !toolboxBox.expanded
        width: 42; height: 42
        Lucide { anchors.centerIn: parent; name: toolboxBox.recording ? "video" : "tool"; px: 20 }
        Rectangle {
          visible: toolboxBox.recording
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.margins: 7
          width: 10; height: 10; radius: 5
          color: Theme.red
          SequentialAnimation on opacity {
            running: toolboxBox.recording
            loops: Animation.Infinite
            NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutQuad }
            onStopped: parent.opacity = 1
          }
        }
      }
      // expanded: 4 individual glass buttons (no container box)
      Row {
        visible: toolboxBox.expanded
        spacing: 10
        Repeater {
          model: [
            { icon: "camera", cmd: ["sh", "-c", "/home/octal/.local/bin/shot region"] },
            { icon: "image", cmd: ["sh", "-c", "/home/octal/.local/bin/shot full"] },
            { icon: "video", cmd: ["/home/octal/.local/bin/rec"] },
            { icon: "droplet", cmd: ["hyprpicker", "-a"] }
          ]
          delegate: Item {
            required property var modelData
            property bool isRec: modelData.icon === "video"
            width: 56; height: 56
            Rectangle {
              anchors.fill: parent
              radius: 28
              color: (isRec && toolboxBox.recording) ? Theme.redA(0x66/255) : Theme.ground(0x42/255)
              Lucide {
                anchors.centerIn: parent
                name: modelData.icon
                px: 24
                opacity: toolMa.containsMouse ? 1 : 0.8
              }
              Text {
                visible: isRec && toolboxBox.recording
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                text: "●"
                color: Theme.red
                font.pixelSize: 12
              }
              MouseArea {
                id: toolMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached(modelData.cmd);
                  if (dockStore) dockStore.toolboxOpen = false;
                }
              }
            }
          }
        }
      }
    }
  }

  Component {
    id: islandRightCluster
    Row {
      spacing: 14
      Row {
        spacing: 4
        Repeater {
          model: SystemTray.items
          MouseArea {
            id: trayMa
            required property var modelData
            property var item: modelData
            width: 24; height: 24
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
              if (mouse.button === Qt.LeftButton) item.activate();
              else trayMenuPopup.open(item, trayMa);
            }
            Image { anchors.centerIn: parent; width: 18; height: 18; source: item.icon }
          }
        }
      }
      Row {
        spacing: 5
        Lucide { name: root.netUp === "up" ? "wifi" : "wifi-off"; px: 15 }
        Text {
          color: Theme.text; font.family: shellFont.family; font.pixelSize: 12
          text: root.netUp === "" ? "--" : root.netUp
        }
      }
      PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
      Item {
        property var sink: Pipewire.defaultAudioSink
        width: volRow.width; height: 18
        Row {
          id: volRow
          spacing: 5
          anchors.verticalCenter: parent.verticalCenter
          Lucide { name: (!parent.parent.sink || !parent.parent.sink.ready || parent.parent.sink.audio.muted) ? "volume-x" : "volume-2"; px: 15 }
          Text {
            color: Theme.text; font.family: shellFont.family; font.pixelSize: 12
            text: {
              const s = parent.parent.sink;
              if (!s || !s.ready) return "--";
              return s.audio.muted ? "mute" : Math.round(s.audio.volume * 100) + "%";
            }
          }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.togglePopup("volume")
          onWheel: wheel => {
            const s = Pipewire.defaultAudioSink;
            if (!s || !s.ready) return;
            s.audio.volume = Math.max(0, Math.min(1, s.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
          }
        }
      }
      Row {
        spacing: 5
        visible: UPower.displayDevice.isLaptopBattery
        Lucide {
          px: 15
          name: {
            const d = UPower.displayDevice;
            if (!d.ready) return "battery";
            if (d.state === UPowerDeviceState.Charging) return "battery-charging";
            return (d.percentage * 100 <= 20) ? "battery" : "battery-medium";
          }
        }
        Text {
          color: Theme.text; font.family: shellFont.family; font.pixelSize: 12
          text: {
            const d = UPower.displayDevice;
            if (!d.ready) return "--";
            return Math.round(d.percentage * 100) + "%";
          }
        }
      }
      Text {
        color: Theme.text
        font.family: shellFont.family; font.pixelSize: 12
        SystemClock { id: clock; precision: SystemClock.Seconds }
        text: Qt.formatDateTime(clock.date, "HH:mm")
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.togglePopup("calendar")
        }
      }
      // control center
      Item {
        width: 20; height: 18
        Lucide { anchors.centerIn: parent; name: "sliders"; px: 15; opacity: ccMa.containsMouse ? 1 : 0.75 }
        MouseArea {
          id: ccMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.togglePopup("controlcenter")
        }
      }
      Item {
        width: 20; height: 18
        Lucide { anchors.centerIn: parent; name: "power"; px: 15; opacity: powerMa.containsMouse ? 1 : 0.75 }
        MouseArea {
          id: powerMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.togglePopup("power")
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      WlrLayershell.namespace: "mybar"
      WlrLayershell.layer: WlrLayer.Top
      visible: dockStore.barStyle === "full"

      anchors { top: true; left: true; right: true }
      margins { top: 8; left: 12; right: 12 }
      implicitHeight: 42
      color: "transparent"

      // Single full-width glass bar.
      Rectangle {
        anchors.fill: parent
        radius: dockStore.rounding
        color: Theme.ground(0x2b/255)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 12

          // LEFT: launcher button + workspaces
          Row {
            spacing: 10
            Layout.alignment: Qt.AlignVCenter
            Item {
              width: 26; height: 26
              Lucide { anchors.centerIn: parent; name: "layout-grid"; px: 17; opacity: launcherBtn.containsMouse ? 1 : 0.75 }
              MouseArea {
                id: launcherBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: launcher.toggle()
              }
            }
            Row {
              spacing: 6

            Repeater {
              model: [...Hyprland.workspaces.values].sort((a, b) => a.id - b.id)
              Rectangle {
                required property var modelData
                property var ws: modelData
                property bool focused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === ws.id
                width: focused ? 38 : 30; height: 26
                radius: dockStore.rounding
                color: focused ? "#40ffffff" : ws.active ? "#22ffffff" : "transparent"
                Behavior on width { NumberAnimation { duration: 150 } }

                Text {
                  anchors.centerIn: parent
                  text: ws.name
                  color: focused ? "#ffffff" : Theme.textMuted
                  font.family: shellFont.family
                  font.pixelSize: 13
                  font.bold: focused
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (focused) root.togglePopup("overview");
                    else Hyprland.dispatch("workspace " + ws.id);
                  }
                }
              }
            }
            Repeater {
              model: Hyprland.workspaces.values.length === 0 ? [1, 2, 3, 4, 5] : []
              Rectangle {
                required property var modelData
                width: 30; height: 26; radius: dockStore.rounding
                color: "transparent"
                Text { anchors.centerIn: parent; text: modelData; color: Theme.textMuted; font.pixelSize: 13 }
                MouseArea { anchors.fill: parent; onClicked: Hyprland.dispatch("workspace " + modelData) }
              }
            }
          }

          }

          // CENTER: window title
          Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            text: Hyprland.focusedToplevel ? (Hyprland.focusedToplevel.title || Hyprland.focusedToplevel.appId) : "Hyprland"
            color: Theme.textMuted
            font.family: shellFont.family
            font.pixelSize: 12
          }

          // RIGHT: status cluster
          Row {
            spacing: 14
            Layout.alignment: Qt.AlignVCenter

            Row {
              spacing: 4
              Repeater {
                model: SystemTray.items
                MouseArea {
                  id: trayMaFull
                  required property var modelData
                  property var item: modelData
                  width: 24; height: 24
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) item.activate();
                    else trayMenuPopup.open(item, trayMaFull);
                  }
                  Image { anchors.centerIn: parent; width: 18; height: 18; source: item.icon }
                }
              }
            }

            Row {
              spacing: 5
              Lucide { name: root.netUp === "up" ? "wifi" : "wifi-off"; px: 15 }
              Text {
                color: Theme.text; font.family: shellFont.family; font.pixelSize: 12
                text: root.netUp === "" ? "--" : root.netUp
              }
            }

            PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
            Item {
              property var sink: Pipewire.defaultAudioSink
              width: volRow.width; height: 18
              Row {
                id: volRow
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter
                Lucide { name: (!parent.parent.sink || !parent.parent.sink.ready || parent.parent.sink.audio.muted) ? "volume-x" : "volume-2"; px: 15 }
                Text {
                  color: Theme.text; font.family: shellFont.family; font.pixelSize: 12
                  text: {
                    const s = parent.parent.sink;
                    if (!s || !s.ready) return "--";
                    return s.audio.muted ? "mute" : Math.round(s.audio.volume * 100) + "%";
                  }
                }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePopup("volume")
                onWheel: wheel => {
                  const s = Pipewire.defaultAudioSink;
                  if (!s || !s.ready) return;
                  s.audio.volume = Math.max(0, Math.min(1, s.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                }
              }
            }

            Row {
              spacing: 5
              visible: UPower.displayDevice.isLaptopBattery
              Lucide {
                px: 15
                name: {
                  const d = UPower.displayDevice;
                  if (!d.ready) return "battery";
                  if (d.state === UPowerDeviceState.Charging) return "battery-charging";
                  return (d.percentage * 100 <= 20) ? "battery" : "battery-medium";
                }
              }
              Text {
                color: Theme.text; font.family: shellFont.family; font.pixelSize: 12
                text: {
                  const d = UPower.displayDevice;
                  if (!d.ready) return "--";
                  return Math.round(d.percentage * 100) + "%";
                }
              }
            }

            // system stats (click for details + btop)
            Text {
              color: Theme.text; font.family: shellFont.family; font.pixelSize: 12
              text: root.sysCpu + "%·" + root.sysMem + "%·" + root.sysTemp + "°"
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePopup("sys")
              }
            }

            // now playing (only while something plays)
            Item {
              property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
              visible: !!player
              width: mediaRow.width; height: 18
              Row {
                id: mediaRow
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter
                Lucide { name: "music"; px: 14 }
                Text {
                  color: Theme.text; font.family: shellFont.family; font.pixelSize: 12
                  text: {
                    const p = parent.parent.player;
                    if (!p) return "";
                    return (((p.trackArtist ? p.trackArtist + " - " : "") + (p.trackTitle || "playing"))).slice(0, 24);
                  }
                }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePopup("media")
                onWheel: wheel => {
                  const p = parent.player;
                  if (p && p.canSeek) p.seek(wheel.angleDelta.y > 0 ? 10 : -10);
                }
              }
            }

            // clock (no pill, plain text)
            Text {
              color: Theme.text
              font.family: shellFont.family; font.pixelSize: 12
              SystemClock { id: clock; precision: SystemClock.Seconds }
              text: Qt.formatDateTime(clock.date, "ddd MMM d  HH:mm")
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePopup("calendar")
              }
            }

            // power menu
            Item {
              width: 20; height: 18
              Lucide { anchors.centerIn: parent; name: "sliders"; px: 15; opacity: ccMaFull.containsMouse ? 1 : 0.75 }
              MouseArea {
                id: ccMaFull
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePopup("controlcenter")
              }
            }
            Item {
              width: 20; height: 18
              Lucide { anchors.centerIn: parent; name: "power"; px: 15; opacity: powerMa.containsMouse ? 1 : 0.75 }
              MouseArea {
                id: powerMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePopup("power")
              }
            }
          }
        }
      }
    }
  }

  // ── BAR ISLANDS: three floating pills (left / title / status) ──
  // Same mybar namespace, so glass + blur rules apply unchanged.
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      WlrLayershell.namespace: "mybar"
      WlrLayershell.layer: WlrLayer.Top
      visible: dockStore.barStyle === "islands"

      anchors { top: true; left: true; right: true }
      margins { top: 8 }
      implicitHeight: 42
      color: "transparent"
      mask: Region { item: islandLeftPill }

      Rectangle {
        id: islandLeftPill
        x: 12
        width: leftLoader.implicitWidth + 24
        height: 42
        radius: dockStore.rounding
        color: Theme.ground(0x2b/255)
        Loader { id: leftLoader; active: dockStore.barStyle === "islands"; anchors.centerIn: parent; sourceComponent: islandLeftCluster }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: islandCenterWin
      required property var modelData
      screen: modelData

      WlrLayershell.namespace: "mybar"
      WlrLayershell.layer: WlrLayer.Top
      visible: dockStore.barStyle === "islands"
      exclusionMode: ExclusionMode.Ignore

      property bool wantOpen: !(dockStore.hidePlayerIdle && !(centerLoader.item && centerLoader.item.player))

      anchors { top: true; left: true; right: true }
      margins { top: 8 }
      // fixed height: the pill morphs inside a static surface so the compositor
      // never resizes mid-animation (resizing + glass reallocs = flicker)
      implicitHeight: 210
      color: "transparent"
      mask: Region { item: islandCenterPill }

      Rectangle {
        id: islandCenterPill
        anchors.horizontalCenter: parent.horizontalCenter
        width: centerLoader.implicitWidth + 24
        height: centerLoader.implicitHeight + 14
        onWidthChanged: root.mediaIslandW = width
        radius: dockStore.rounding
        color: Theme.ground(0x2b/255)
        clip: true
        Behavior on width { SpringAnimation { spring: 3.5; damping: 0.28; epsilon: 0.5 } }
        Behavior on height { SpringAnimation { spring: 3.5; damping: 0.28; epsilon: 0.5 } }
        visible: islandCenterWin.wantOpen || opacity > 0
        opacity: islandCenterWin.wantOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        // expand on background click (content sits above and keeps its clicks)
        MouseArea {
          anchors.fill: parent
          enabled: !dockStore.playerExpanded
          cursorShape: Qt.PointingHandCursor
          onClicked: { if (dockStore) { dockStore.playerExpanded = true; dockStore.toolboxOpen = false; } }
        }
        Loader {
          id: centerLoader
          active: dockStore.barStyle === "islands"
          anchors.top: parent.top
          anchors.topMargin: 7
          anchors.horizontalCenter: parent.horizontalCenter
          sourceComponent: islandCenterCluster
        }
      }
    }
  }

  // ── TOOLBOX ISLAND: glass ball left of the player, morphs into tool panel ──
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: islandToolboxWin
      required property var modelData
      screen: modelData

      WlrLayershell.namespace: "mytools"
      WlrLayershell.layer: WlrLayer.Top
      visible: dockStore.barStyle === "islands"
      exclusionMode: ExclusionMode.Ignore

      anchors { top: true; left: true; right: true }
      margins { top: 8 }
      implicitHeight: 260
      color: "transparent"
      mask: Region { item: islandToolboxPill }

      Rectangle {
        id: islandToolboxPill
        // single shared progress drives x+y so the flight path stays diagonal
        property real morphT: dockStore.toolboxOpen ? 1 : 0
        Behavior on morphT { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        x: {
          const closedX = parent.width / 2 + root.mediaIslandW / 2 + 10;
          const openX = (parent.width - width) / 2;
          return closedX + (openX - closedX) * morphT;
        }
        y: 60 * morphT
        width: dockStore.toolboxOpen ? toolboxLoader.implicitWidth + 24 : 42
        height: dockStore.toolboxOpen ? toolboxLoader.implicitHeight + 14 : 42
        radius: dockStore.toolboxOpen ? islandToolboxPill.height / 2 : 21
        color: dockStore.toolboxOpen ? Theme.ground(0x55/255) : Theme.ground(0x42/255)
        clip: true
        Behavior on width { SpringAnimation { spring: 3.5; damping: 0.28; epsilon: 0.5 } }
        Behavior on height { SpringAnimation { spring: 3.5; damping: 0.28; epsilon: 0.5 } }
        Behavior on radius { SpringAnimation { spring: 3.5; damping: 0.28; epsilon: 0.5 } }
        // expand on background click (content sits above and keeps its clicks)
        MouseArea {
          anchors.fill: parent
          enabled: !dockStore.toolboxOpen
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (dockStore) {
              dockStore.toolboxOpen = true;
              dockStore.playerExpanded = false;
            }
          }
        }
        Loader {
          id: toolboxLoader
          active: dockStore.barStyle === "islands"
          anchors.centerIn: parent
          sourceComponent: islandToolboxCluster
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      WlrLayershell.namespace: "mybar"
      WlrLayershell.layer: WlrLayer.Top
      visible: dockStore.barStyle === "islands"
      exclusionMode: ExclusionMode.Ignore

      anchors { top: true; left: true; right: true }
      margins { top: 8 }
      implicitHeight: 42
      color: "transparent"
      mask: Region { item: islandRightPill }

      Rectangle {
        id: islandRightPill
        anchors.right: parent.right
        anchors.rightMargin: 12
        width: rightLoader.implicitWidth + 24
        height: 42
        radius: dockStore.rounding
        color: Theme.ground(0x2b/255)
        Loader { id: rightLoader; active: dockStore.barStyle === "islands"; anchors.centerIn: parent; sourceComponent: islandRightCluster }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    // ── DOCK: floating glass pill, bottom center ──
    PanelWindow {
      required property var modelData
      // modelData = screen from Variants
      screen: modelData

      WlrLayershell.namespace: "mydock"
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      anchors { left: true; right: true; bottom: true }
      // tall surface: pill sits at the bottom, tooltips render in the headroom above
      implicitHeight: 120
      color: "transparent"
      mask: Region { item: dockBox }

      MouseArea {
        id: magnetic
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        // off when hidden so it never eats clicks meant for windows (edge strip reveals)
        enabled: root.dockOpen
        onPositionChanged: dockRow.magnet(mouseX)
        onExited: dockRow.relax()
        onContainsMouseChanged: root.dockHover = containsMouse
      }

      Item {
        id: dockBox
        // slide off-screen when hidden (mask follows layout, so no dead click zone)
        property real slide: root.dockOpen ? 0 : 1
        Behavior on slide { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8 - slide * (dockBox.height + 20)
        width: dockRow.width + 14
        height: dockRow.height + 6

        Rectangle {
          anchors.fill: parent
          radius: dockStore.rounding
          color: "#401e2535"
        }

        Row {
          id: dockRow
          anchors.centerIn: parent
          spacing: 6

          function magnet(mx) {
            for (let i = 0; i < children.length; i++) {
              const c = children[i];
              if (!c || c.centerX === undefined) continue;
              const cx = c.x + dockRow.x + 14 + c.width / 2;
              const d = Math.abs(mx - cx);
              c.mag = Math.max(1, 1.7 - d / 110);
            }
          }
          function relax() {
            for (let i = 0; i < children.length; i++)
              if (children[i] && children[i].mag !== undefined) children[i].mag = 1;
          }

          Repeater {
            model: dockStore.pinned
            delegate: DockIcon {
              base: dockStore.iconBase; max: dockStore.iconMax
              mag: 1
              appId: modelData.id
              execCmd: modelData.exec
              iconName: modelData.icon
              running: root.clients.some(c =>
                (c.lastIpcObject.class || "").toLowerCase().includes(modelData.id))
            }
          }
        }
      }
    }
  }

  // ── DOCK reveal strip: 4px hover edge at screen bottom (Overlay, reserves nothing) ──
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      WlrLayershell.namespace: "mydock-edge"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      anchors { left: true; right: true; bottom: true }
      implicitHeight: 4
      color: "transparent"

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: root.dockEdgeHover = containsMouse
      }
    }
  }
}
