// Dock settings with JSON persistence.
// Instantiated once in shell.qml as `DockSettings { id: dockStore }`,
// passed into Dashboard for the Dock page.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  property alias pinned: adapter.pinned
  property alias iconBase: adapter.iconBase
  property alias iconMax: adapter.iconMax
  property alias autohide: adapter.autohide
  property alias barBlur: adapter.barBlur
  property alias dockBlur: adapter.dockBlur
  property alias barStyle: adapter.barStyle
  property alias hidePlayerIdle: adapter.hidePlayerIdle
  property alias playerExpanded: adapter.playerExpanded
  property alias rounding: adapter.rounding
  property alias glassLevel: adapter.glassLevel
  property alias gamingMode: adapter.gamingMode
  property alias toolboxOpen: adapter.toolboxOpen

  readonly property var defaults: [
    { id: "firefox", exec: "firefox", icon: "firefox" },
    { id: "kitty", exec: "kitty", icon: "kitty" },
    { id: "dolphin", exec: "dolphin", icon: "org.kde.dolphin" },
    { id: "code", exec: "code", icon: "vscode" },
    { id: "vesktop", exec: "vesktop", icon: "vesktop" },
    { id: "spotify", exec: "spotify", icon: "spotify-client" },
    { id: "launcher", exec: "quickshell -p /home/octal/.config/quickshell/mybar/shell.qml ipc call launcher toggle", icon: "lucide:layout-grid" }
  ]

  function addApp(appId, exec, icon) {
    if (!appId || !exec) return;
    adapter.pinned = adapter.pinned.concat([{ id: appId, exec: exec, icon: icon || "application-x-executable" }]);
  }
  function removeAt(i) {
    const a = adapter.pinned.slice();
    if (i < 0 || i >= a.length) return;
    a.splice(i, 1);
    adapter.pinned = a;
  }
  function move(i, dir) {
    const a = adapter.pinned.slice();
    const j = i + dir;
    if (i < 0 || i >= a.length || j < 0 || j >= a.length) return;
    const t = a[i]; a[i] = a[j]; a[j] = t;
    adapter.pinned = a;
  }
  function resetDefaults() {
    adapter.pinned = root.defaults.slice();
    adapter.iconBase = 28;
    adapter.iconMax = 42;
    adapter.autohide = "auto";
    adapter.barBlur = false;
    adapter.dockBlur = false;
    adapter.barStyle = "full";
    adapter.hidePlayerIdle = true;
    adapter.playerExpanded = false;
    adapter.rounding = 16;
    adapter.glassLevel = 50;
    adapter.gamingMode = false;
    adapter.toolboxOpen = false;
  }

  Timer {
    id: writeTimer
    interval: 300
    repeat: false
    onTriggered: dockFile.writeAdapter()
  }

  FileView {
    id: dockFile
    path: Quickshell.env("HOME") + "/.config/quickshell/mybar/dock.json"
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeTimer.restart()
    onLoadFailed: err => {
      if (err === FileViewError.FileNotFound) writeTimer.restart();
    }

    JsonAdapter {
      id: adapter
      property var pinned: [
        { id: "firefox", exec: "firefox", icon: "firefox" },
        { id: "kitty", exec: "kitty", icon: "kitty" },
        { id: "dolphin", exec: "dolphin", icon: "org.kde.dolphin" },
        { id: "code", exec: "code", icon: "vscode" },
        { id: "vesktop", exec: "vesktop", icon: "vesktop" },
        { id: "spotify", exec: "spotify", icon: "spotify-client" },
        { id: "launcher", exec: "quickshell -p /home/octal/.config/quickshell/mybar/shell.qml ipc call launcher toggle", icon: "lucide:layout-grid" }
      ]
      property int iconBase: 28
      property int iconMax: 42
      // "show" = always visible, "auto" = empty workspace or hover, "hide" = hover only
      property string autohide: "auto"
      // blur-behind (same composition as notification cards); applied via hyprctl eval
      property bool barBlur: false
      property bool dockBlur: false
      // "full" = one slab, "islands" = three floating pills
      property string barStyle: "full"
      property bool hidePlayerIdle: true
      property bool playerExpanded: false
      // card corner radius for bar/dock/popups (px) + global glass intensity (0-100)
      property int rounding: 16
      property int glassLevel: 50
      // gaming mode: kills all liquid glass + blur for max fps
      property bool gamingMode: false
      property bool toolboxOpen: false
    }
  }
}
