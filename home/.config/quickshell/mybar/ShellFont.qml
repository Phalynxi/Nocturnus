// Shell-wide font family with JSON persistence (fonts.json).
// Instantiate anywhere a font is used: ShellFont { id: shellFont }
// then bind: font.family: shellFont.family
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  property alias family: adapter.family

  function setFamily(name) {
    if (name) adapter.family = name;
  }

  Timer {
    id: writeTimer
    interval: 400
    repeat: false
    onTriggered: fontsFile.writeAdapter()
  }

  FileView {
    id: fontsFile
    path: Quickshell.env("HOME") + "/.config/quickshell/mybar/fonts.json"
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeTimer.restart()
    onLoadFailed: err => {
      if (err === FileViewError.FileNotFound) writeTimer.restart();
    }

    JsonAdapter {
      id: adapter
      property string family: "JetBrains Mono"
    }
  }
}
