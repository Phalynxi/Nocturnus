// macOS-style control center: connectivity + music tiles, toggle rounds,
// sliders, quick actions. Shown via bar popups as "controlcenter".
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Io
import Qt5Compat.GraphicalEffects

Column {
  id: root
  property var dockStore: null
  property var widgetStore: null
  width: parent.width
  spacing: 12

  property string wifiState: ""
  property string wifiName: "--"
  property string btState: ""
  property bool nightOn: false
  property int nightTemp: 4500

  function refreshWifi() { wifiProc.running = true; }
  function refreshBt() { btProc.running = true; }
  function refreshNight() { nightProc.running = true; }

  onVisibleChanged: {
    if (visible) { root.refreshWifi(); root.refreshBt(); root.refreshNight(); }
  }
  Timer { interval: 10000; running: root.visible; repeat: true; onTriggered: { root.refreshWifi(); root.refreshBt(); } }

  Process {
    id: wifiProc
    command: ["sh", "-c", "printf '%s|%s' \"$(nmcli networking 2>/dev/null)\" \"$(nmcli -t -f NAME connection show --active 2>/dev/null | head -n 1)\""]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = this.text.trim().split("|");
        root.wifiState = (parts[0] || "").trim();
        root.wifiName = ((parts[1] || "").trim() || "--");
      }
    }
  }
  Process {
    id: btProc
    command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -m1 'Powered:' | awk '{print $2}'"]
    stdout: StdioCollector {
      onStreamFinished: root.btState = this.text.trim()
    }
  }
  Process {
    id: nightProc
    command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo on || echo off"]
    stdout: StdioCollector {
      onStreamFinished: root.nightOn = this.text.trim() === "on"
    }
  }

  function toggleWifi() {
    const cmd = root.wifiState === "enabled" ? "off" : "on";
    Quickshell.execDetached(["sh", "-c", "nmcli networking " + cmd + " && sleep 1"]);
    root.wifiState = "";
    pollBack.restart();
  }
  function toggleBt() {
    const cmd = root.btState === "yes" ? "off" : "on";
    Quickshell.execDetached(["sh", "-c", "bluetoothctl power " + cmd + " && sleep 1"]);
    root.btState = "";
    pollBack.restart();
  }
  function toggleNight() {
    if (root.nightOn) Quickshell.execDetached(["sh", "-c", "pkill -x hyprsunset"]);
    else Quickshell.execDetached(["sh", "-c", "hyprsunset -t " + root.nightTemp + " &"]);
    root.nightOn = !root.nightOn;
  }
  function setNightTemp(k) {
    root.nightTemp = k;
    Quickshell.execDetached(["sh", "-c", "pkill -x hyprsunset; hyprsunset -t " + k + " &"]);
    root.nightOn = true;
  }
  Timer { id: pollBack; interval: 1500; onTriggered: { root.refreshWifi(); root.refreshBt(); } }

  // ── tiles: wifi + music ──
  Row {
    width: parent.width
    spacing: 12
    // wifi
    Rectangle {
      width: (parent.width - 12) / 2; height: 104
      radius: 18
      color: root.wifiState === "enabled" ? "#3f7de066" : Theme.ground(0x22/255)
      Row {
        anchors.fill: parent
        anchors.leftMargin: 12; anchors.rightMargin: 12
        spacing: 12
        Rectangle {
          width: 52; height: 52
          radius: 26
          anchors.verticalCenter: parent.verticalCenter
          color: "#33ffffff"
          Lucide { anchors.centerIn: parent; name: root.wifiState === "enabled" ? "wifi" : "wifi-off"; px: 22 }
        }
        Column {
          width: parent.width - 80
          anchors.verticalCenter: parent.verticalCenter
          spacing: 3
          Text {
            width: parent.width
            text: "Wi-Fi"
            color: "#ffffff"
            font.family: shellFont.family; font.pixelSize: 13; font.bold: true
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            text: root.wifiState === "" ? "…" : (root.wifiState === "enabled" ? root.wifiName : "Off")
            color: Theme.textMuted
            font.family: shellFont.family; font.pixelSize: 12
            elide: Text.ElideRight
          }
        }
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleWifi()
      }
    }
    // music
    Rectangle {
      width: (parent.width - 12) / 2; height: 104
      radius: 18
      color: Theme.ground(0x22/255)
      Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        Row {
          width: parent.width
          spacing: 10
          Item {
            width: 52; height: 52
            Image {
              id: ccArt
              anchors.fill: parent
              source: ccPlayer.player ? ccPlayer.player.trackArtUrl : ""
              fillMode: Image.PreserveAspectCrop
              smooth: true
              asynchronous: true
              cache: true
              visible: false
            }
            Rectangle {
              id: ccArtMask
              anchors.fill: parent
              radius: 14
              visible: false
            }
            OpacityMask {
              anchors.fill: parent
              source: ccArt
              maskSource: ccArtMask
              visible: ccArt.source !== ""
            }
            Rectangle {
              visible: ccArt.source === ""
              anchors.fill: parent
              radius: 14
              color: "#33ffffff"
              Lucide { anchors.centerIn: parent; name: "music"; px: 24 }
            }
          }
          Item {
            id: ccPlayer
            width: parent.width - 62
            height: 52
            function isVid(p) {
              const t = (p && p.trackTitle) || "";
              return /\.(mp4|mkv|webm|avi|mov|gif)$/i.test(t.trim());
            }
            property var player: {
              const all = Mpris.players.values;
              return all.find(p => p.isPlaying && !ccPlayer.isVid(p))
                  ?? all.find(p => !ccPlayer.isVid(p))
                  ?? null;
            }
            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              spacing: 3
              Text {
                width: parent.width
                text: ccPlayer.player ? (ccPlayer.player.trackTitle || "Unknown") : "Nothing playing"
                color: "#ffffff"
                font.family: shellFont.family; font.pixelSize: 13; font.bold: true
                elide: Text.ElideRight
              }
              Text {
                width: parent.width
                text: ccPlayer.player ? (ccPlayer.player.trackArtist || ccPlayer.player.identity || "") : "—"
                color: Theme.textMuted
                font.family: shellFont.family; font.pixelSize: 12
                elide: Text.ElideRight
              }
            }
          }
        }
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 10
          Item {
            width: 24; height: 24
            Rectangle { anchors.fill: parent; radius: 12; color: "#1effffff" }
            Lucide { anchors.centerIn: parent; name: "skip-back"; px: 18; opacity: trMa.containsMouse ? 0.9 : 0.45 }
            MouseArea { id: trMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (ccPlayer.player && ccPlayer.player.canGoPrevious) ccPlayer.player.previous(); } }
          }
          Item {
            width: 24; height: 24
            Rectangle { anchors.fill: parent; radius: 12; color: "#38ffffff" }
            Lucide { anchors.centerIn: parent; name: (ccPlayer.player && ccPlayer.player.isPlaying) ? "pause" : "play"; px: 20; opacity: tpMa.containsMouse ? 1 : 0.6 }
            MouseArea { id: tpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (ccPlayer.player) ccPlayer.player.togglePlaying(); } }
          }
          Item {
            width: 24; height: 24
            Rectangle { anchors.fill: parent; radius: 12; color: "#1effffff" }
            Lucide { anchors.centerIn: parent; name: "skip-forward"; px: 18; opacity: tnMa.containsMouse ? 0.9 : 0.45 }
            MouseArea { id: tnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (ccPlayer.player && ccPlayer.player.canGoNext) ccPlayer.player.next(); } }
          }
        }
      }
    }
  }

  // ── round toggles ──
  Row {
    width: parent.width
    spacing: (parent.width - 4 * 60) / 3
    // bluetooth
    Rectangle {
      width: 52; height: 52; radius: 26
      color: root.btState === "yes" ? "#3f7de066" : Theme.ground(0x22/255)
      Lucide { anchors.centerIn: parent; name: "bluetooth"; px: 22 }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleBt() }
    }
    // night light
    Rectangle {
      width: 52; height: 52; radius: 26
      color: root.nightOn ? "#3f7de066" : Theme.ground(0x22/255)
      Lucide { anchors.centerIn: parent; name: "moon"; px: 22 }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleNight() }
    }
    // gaming
    Rectangle {
      width: 52; height: 52; radius: 26
      color: (root.dockStore && root.dockStore.gamingMode) ? "#3f7de066" : Theme.ground(0x22/255)
      Lucide { anchors.centerIn: parent; name: "zap"; px: 22 }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { if (root.dockStore) root.dockStore.gamingMode = !root.dockStore.gamingMode; }
      }
    }
    // mute
    Rectangle {
      id: muteBtn
      property var sink: Pipewire.defaultAudioSink
      width: 52; height: 52; radius: 26
      color: (muteBtn.sink && muteBtn.sink.ready && muteBtn.sink.audio.muted) ? "#3f7de066" : Theme.ground(0x22/255)
      Lucide { anchors.centerIn: parent; name: (muteBtn.sink && muteBtn.sink.ready && muteBtn.sink.audio.muted) ? "volume-x" : "volume-2"; px: 22 }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          const s = Pipewire.defaultAudioSink;
          if (s && s.ready) s.audio.muted = !s.audio.muted;
        }
      }
    }
  }
  // focus (desktop widgets) — full-width pill
  Rectangle {
    width: parent.width; height: 52; radius: 26
    color: (root.widgetStore && !root.widgetStore.visible) ? "#3f7de066" : Theme.ground(0x22/255)
    Row {
      anchors.centerIn: parent
      spacing: 10
      Lucide { anchors.verticalCenter: parent.verticalCenter; name: (root.widgetStore && !root.widgetStore.visible) ? "eye-off" : "eye"; px: 24 }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
          text: "Focus"
          color: "#ffffff"
          font.family: shellFont.family; font.pixelSize: 13; font.bold: true
        }
        Text {
          text: (root.widgetStore && !root.widgetStore.visible) ? "Widgets hidden" : "Widgets shown"
          color: Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 10
        }
      }
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: { if (root.widgetStore) root.widgetStore.visible = !root.widgetStore.visible; }
    }
  }
  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

  // ── sliders: sound + night light ──
  Column {
    width: parent.width
    spacing: 8
    Rectangle {
      width: parent.width; height: 54
      radius: 18
      color: Theme.ground(0x22/255)
      Row {
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        spacing: 12
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Sound"
          color: Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 12
          width: 64
        }
        Lucide { anchors.verticalCenter: parent.verticalCenter; name: "volume-2"; px: 16 }
        MiniSlider {
          id: volSlider
          property var sink: Pipewire.defaultAudioSink
          width: parent.width - 64 - 26 - 40 - 20
          anchors.verticalCenter: parent.verticalCenter
          knob: false
          value: (sink && sink.ready) ? sink.audio.volume : 0
          onChanged: v => {
            const s = Pipewire.defaultAudioSink;
            if (s && s.ready) { s.audio.volume = v; if (v > 0) s.audio.muted = false; }
          }
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: 40
          horizontalAlignment: Text.AlignRight
          text: {
            const s = volSlider.sink;
            if (!s || !s.ready) return "--";
            return Math.round(s.audio.volume * 100);
          }
          color: "#ffffff"
          font.family: shellFont.family; font.pixelSize: 12
        }
      }
    }
    Rectangle {
      width: parent.width; height: 54
      radius: 18
      color: Theme.ground(0x22/255)
      Row {
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        spacing: 12
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Night"
          color: Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 12
          width: 64
        }
        Lucide { anchors.verticalCenter: parent.verticalCenter; name: "moon"; px: 16 }
        MiniSlider {
          width: parent.width - 64 - 26 - 40 - 20
          anchors.verticalCenter: parent.verticalCenter
          knob: false
          value: (root.nightTemp - 1000) / 5500
          onChanged: v => root.setNightTemp(Math.round(1000 + v * 5500))
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: 40
          horizontalAlignment: Text.AlignRight
          text: (root.nightTemp / 1000).toFixed(1) + "k"
          color: root.nightOn ? "#ffffff" : Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 12
        }
      }
    }
  }

  // ── quick actions ──
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 12
    Repeater {
      model: [
        { icon: "kitty", exec: "kitty" },
        { icon: "lucide:folder", exec: "dolphin" },
        { icon: "org.gnome.Calculator", exec: "gnome-calculator" },
        { icon: "lucide:camera", exec: "/home/octal/.local/bin/shot region" },
        { icon: "lucide:lock", exec: "hyprlock" }
      ]
      delegate: Rectangle {
        required property var modelData
        width: 52; height: 52; radius: 26
        color: Theme.ground(0x22/255)
        Image {
          visible: !modelData.icon.startsWith("lucide:")
          anchors.centerIn: parent
          width: 24; height: 24
          source: modelData.icon.startsWith("lucide:") ? "" : ("image://icon/" + modelData.icon)
          fillMode: Image.PreserveAspectFit
          smooth: true
          onStatusChanged: if (status === Image.Error) source = "image://icon/application-x-executable"
        }
        Lucide {
          visible: modelData.icon.startsWith("lucide:")
          anchors.centerIn: parent
          name: modelData.icon.startsWith("lucide:") ? modelData.icon.slice(7) : ""
          px: 22
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["sh", "-c", modelData.exec])
        }
      }
    }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: "Edit Controls"
    color: Theme.textMuted
    font.family: shellFont.family; font.pixelSize: 12
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: Quickshell.execDetached(["quickshell", "-p", "/home/octal/.config/quickshell/mybar/shell.qml", "ipc", "call", "dashboard", "page", "controls"])
    }
  }

  ShellFont { id: shellFont }
}
