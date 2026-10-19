// Widget store with JSON persistence.
// Instantiated once in shell.qml as `WidgetStore { id: widgetStore }`,
// passed into Widgets + Dashboard (Widgets page).
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  property alias widgets: adapter.widgets
  property alias editMode: adapter.editMode
  property alias glass: adapter.glass
  property alias blur: adapter.blur
  property alias visible: adapter.visible

  // type catalog: default size + spawn position (cascaded per existing count)
  readonly property var catalog: [
    { type: "clock",     label: "Clock",        w: 260, x: 12,   y: 60  },
    { type: "nowplaying", label: "Now playing", w: 460, x: 453,  y: 470 },
    { type: "sys",       label: "System",       w: 300, x: 12,   y: 250 },
    { type: "media",     label: "Media",        w: 314, x: 1040, y: 380 },
    { type: "calendar",  label: "Calendar",     w: 264, x: 1090, y: 60  },
    { type: "notes",     label: "Notes",        w: 300, x: 12,   y: 500 },
    { type: "todo",      label: "Todo",         w: 300, x: 12,   y: 500 },
    { type: "weather",   label: "Weather",      w: 264, x: 1090, y: 360 },
    { type: "wallpaper", label: "Wallpaper",    w: 300, x: 1040, y: 480 },
    { type: "launcher",  label: "Quick launch", w: 314, x: 1040, y: 560 }
  ]

  function labelFor(type) {
    const c = root.catalog.find(c => c.type === type);
    return c ? c.label : type;
  }

  function presetFor(type) {
    return root.catalog.find(c => c.type === type) ?? { type: type, label: type, w: 300, x: 200, y: 200 };
  }

  function clone(w) {
    const c = {};
    for (const k in w) c[k] = w[k];
    return c;
  }

  function addWidget(type) {
    const p = root.presetFor(type);
    const n = adapter.widgets.length;
    adapter.widgets = adapter.widgets.concat([{
      uid: type + "-" + Date.now() + "-" + n,
      type: type,
      x: p.x + (n % 5) * 24,
      y: p.y + (n % 5) * 24,
      w: p.w,
      scale: 1,
      payload: ""
    }]);
  }

  function removeWidget(uid) {
    adapter.widgets = adapter.widgets.filter(w => w.uid !== uid);
  }

  function moveWidget(uid, x, y) {
    adapter.widgets = adapter.widgets.map(w => {
      if (w.uid !== uid) return w;
      const c = root.clone(w);
      c.x = Math.max(0, Math.round(x));
      c.y = Math.max(0, Math.round(y));
      return c;
    });
  }

  function setPayload(uid, payload) {
    adapter.widgets = adapter.widgets.map(w => {
      if (w.uid !== uid) return w;
      const c = root.clone(w);
      c.payload = payload;
      return c;
    });
  }

  function setScale(uid, s) {
    adapter.widgets = adapter.widgets.map(w => {
      if (w.uid !== uid) return w;
      const c = root.clone(w);
      c.scale = s;
      return c;
    });
  }

  function sizeLetter(s) {
    if (Math.abs(s - 0.8) < 0.01) return "S";
    if (Math.abs(s - 1.3) < 0.01) return "L";
    return "M";
  }

  function resetDefaults() {
    adapter.widgets = [
      { uid: "clock-0",     type: "clock",     x: 12,   y: 60,  w: 260, scale: 1, payload: "" },
      { uid: "sys-0",       type: "sys",       x: 12,   y: 250, w: 300, scale: 1, payload: "" },
      { uid: "notes-0",     type: "notes",     x: 12,   y: 500, w: 300, scale: 1, payload: "" },
      { uid: "calendar-0",  type: "calendar",  x: 1090, y: 60,  w: 264, scale: 1, payload: "" },
      { uid: "weather-0",   type: "weather",   x: 1090, y: 360, w: 264, scale: 1, payload: "" },
      { uid: "launcher-0",  type: "launcher",  x: 1040, y: 560, w: 314, scale: 1, payload: "" }
    ];
    adapter.editMode = false;
    adapter.glass = true;
    adapter.blur = false;
    adapter.visible = true;
  }

  Timer {
    id: writeTimer
    interval: 400
    repeat: false
    onTriggered: widgetsFile.writeAdapter()
  }

  FileView {
    id: widgetsFile
    path: Quickshell.env("HOME") + "/.config/quickshell/mybar/widgets.json"
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeTimer.restart()
    onLoadFailed: err => {
      if (err === FileViewError.FileNotFound) writeTimer.restart();
    }

    JsonAdapter {
      id: adapter
      property var widgets: [
        { uid: "clock-0",    type: "clock",    x: 12,   y: 60,  w: 260, scale: 1, payload: "" },
        { uid: "sys-0",      type: "sys",      x: 12,   y: 250, w: 300, scale: 1, payload: "" },
        { uid: "notes-0",    type: "notes",    x: 12,   y: 500, w: 300, scale: 1, payload: "" },
        { uid: "calendar-0", type: "calendar", x: 1090, y: 60,  w: 264, scale: 1, payload: "" },
        { uid: "weather-0",  type: "weather",  x: 1090, y: 360, w: 264, scale: 1, payload: "" },
        { uid: "launcher-0", type: "launcher", x: 1040, y: 560, w: 314, scale: 1, payload: "" }
      ]
      property bool editMode: false
      // liquid-glass effect + blur-behind for widget cards (toggled from dashboard)
      property bool glass: true
      property bool blur: false
      // master visibility for all desktop widgets (Focus tile)
      property bool visible: true
    }
  }
}
