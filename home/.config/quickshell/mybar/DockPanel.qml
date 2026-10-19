// Dock customization page for the dashboard.
// Expects `dockStore` (DockSettings instance) passed in from shell.qml.
import QtQuick
import Quickshell

Column {
  ShellFont { id: shellFont }
  id: root
  property var dockStore: null
  width: parent.width
  spacing: 12

  readonly property var modes: [
    { id: "show", label: "Always show" },
    { id: "auto", label: "Auto-hide" },
    { id: "hide", label: "Hover only" }
  ]

  Text {
    text: "Dock"
    color: "#ffffff"
    font.family: shellFont.family; font.pixelSize: 13; font.bold: true
  }

  // ── behavior ──
  Text {
    text: "Behavior"
    color: Theme.textMuted
    font.family: shellFont.family; font.pixelSize: 11
  }
  Row {
    width: parent.width
    spacing: 8
    Repeater {
      model: root.modes
      delegate: Rectangle {
        required property var modelData
        width: (root.width - 16) / 3; height: 30
        radius: 10
        color: (root.dockStore && root.dockStore.autohide === modelData.id) ? "#40ffffff" : Theme.ground(0x22/255)
        Text {
          anchors.centerIn: parent
          text: modelData.label
          color: (root.dockStore && root.dockStore.autohide === modelData.id) ? "#ffffff" : Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 12
          elide: Text.ElideRight
          width: parent.width - 12
          horizontalAlignment: Text.AlignHCenter
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: { if (root.dockStore) root.dockStore.autohide = modelData.id; }
        }
      }
    }
  }

  // ── glass blur (same blur-behind as notification cards) ──
  Text {
    text: "Background blur"
    color: Theme.textMuted
    font.family: shellFont.family; font.pixelSize: 11
  }
  Column {
    width: parent.width
    spacing: 8
    Repeater {
      model: [
        { key: "barBlur", label: "Top bar" },
        { key: "dockBlur", label: "Dock" }
      ]
      delegate: Item {
        required property var modelData
        width: root.width; height: 22
        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.label
          color: Theme.text
          font.family: shellFont.family; font.pixelSize: 12
        }
        Rectangle {
          property bool on: root.dockStore ? root.dockStore[modelData.key] : false
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: 38; height: 20; radius: 10
          color: on ? Theme.text : "#22ffffff"
          Rectangle {
            x: parent.on ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 14; height: 14; radius: 7
            color: parent.on ? Theme.background : Theme.textMuted
            Behavior on x { NumberAnimation { duration: 150 } }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { if (root.dockStore) root.dockStore[modelData.key] = !parent.on; }
          }
        }
      }
    }
  }

  // ── top bar style ──
  Text {
    text: "Top bar"
    color: Theme.textMuted
    font.family: shellFont.family; font.pixelSize: 11
  }
  Row {
    width: parent.width
    spacing: 8
    Repeater {
      model: [
        { id: "full", label: "Full slab" },
        { id: "islands", label: "Islands" }
      ]
      delegate: Rectangle {
        required property var modelData
        width: (root.width - 8) / 2; height: 30
        radius: 10
        color: (root.dockStore && root.dockStore.barStyle === modelData.id) ? "#40ffffff" : Theme.ground(0x22/255)
        Text {
          anchors.centerIn: parent
          text: modelData.label
          color: (root.dockStore && root.dockStore.barStyle === modelData.id) ? "#ffffff" : Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 12
          font.bold: root.dockStore && root.dockStore.barStyle === modelData.id
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: { if (root.dockStore) root.dockStore.barStyle = modelData.id; }
        }
      }
    }
  }
  // ── shell font ──
  Text {
    text: "Shell font"
    color: Theme.textMuted
    font.family: shellFont.family; font.pixelSize: 11
  }
  Grid {
    width: parent.width
    columns: 2
    columnSpacing: 8
    rowSpacing: 8
    Repeater {
      model: [
        "JetBrains Mono",
        "CaskaydiaCove Nerd Font Mono",
        "JetBrainsMono Nerd Font Mono",
        "Hack",
        "MesloLGM Nerd Font Mono",
        "DejaVu Sans Mono",
        "Adwaita Mono",
        "Liberation Mono",
        "JetBrains Mono ExtraBold",
        "Inter Black",
        "Roboto Black",
        "Rubik",
        "Caveat",
        "Grape Nuts",
        "OpenDyslexic",
        "Virgil 3 YOFF"
      ]
      delegate: Rectangle {
        required property var modelData
        width: (root.width - 8) / 2; height: 34
        radius: 10
        color: shellFont.family === modelData ? "#40ffffff" : Theme.ground(0x22/255)
        border.width: 1
        border.color: shellFont.family === modelData ? "#88ffffff" : "transparent"
        Text {
          anchors.centerIn: parent
          width: parent.width - 16
          horizontalAlignment: Text.AlignHCenter
          text: (shellFont.family === modelData ? "● " : "") + modelData
          color: Theme.text
          font.family: modelData
          font.pixelSize: 12
          elide: Text.ElideRight
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: shellFont.setFamily(modelData)
        }
      }
    }
  }
  Item {
    visible: root.dockStore && root.dockStore.barStyle === "islands"
    width: parent.width; height: 22
    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "Hide player island when nothing plays"
      color: Theme.text
      font.family: shellFont.family; font.pixelSize: 12
    }
    Rectangle {
      property bool on: root.dockStore ? root.dockStore.hidePlayerIdle : true
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 38; height: 20; radius: 10
      color: on ? Theme.text : "#22ffffff"
      Rectangle {
        x: parent.on ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 14; height: 14; radius: 7
        color: parent.on ? Theme.background : Theme.textMuted
        Behavior on x { NumberAnimation { duration: 150 } }
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { if (root.dockStore) root.dockStore.hidePlayerIdle = !parent.on; }
      }
    }
  }

  // ── look: roundness + liquid glass ──
  Row {
    width: parent.width
    spacing: 16
    Column {
      width: (parent.width - 16) / 2
      spacing: 3
      Text {
        text: "Roundness  ·  " + (root.dockStore ? root.dockStore.rounding : "--")
        color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12
      }
      MiniSlider {
        width: parent.width
        knob: false
        value: root.dockStore ? root.dockStore.rounding / 24 : 0.66
        onChanged: v => { if (root.dockStore) root.dockStore.rounding = Math.round(v * 24); }
      }
    }
    Column {
      width: (parent.width - 16) / 2
      spacing: 3
      Text {
        text: "Glass  ·  " + (root.dockStore ? root.dockStore.glassLevel : "--") + "%"
        color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12
      }
      MiniSlider {
        width: parent.width
        knob: false
        value: root.dockStore ? root.dockStore.glassLevel / 100 : 0.5
        onChanged: v => { if (root.dockStore) root.dockStore.glassLevel = Math.round(v * 100); }
      }
    }
  }

  // ── sizes ──
  Row {
    width: parent.width
    spacing: 16
    Column {
      width: (parent.width - 16) / 2
      spacing: 3
      Text {
        text: "Icon size  ·  " + (root.dockStore ? root.dockStore.iconBase : "--")
        color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12
      }
      MiniSlider {
        width: parent.width
        knob: false
        value: root.dockStore ? (root.dockStore.iconBase - 20) / 28 : 0.3
        onChanged: v => { if (root.dockStore) root.dockStore.iconBase = Math.round(20 + v * 28); }
      }
    }
    Column {
      width: (parent.width - 16) / 2
      spacing: 3
      Text {
        text: "Magnify  ·  " + (root.dockStore ? root.dockStore.iconMax : "--")
        color: Theme.textMuted; font.family: shellFont.family; font.pixelSize: 12
      }
      MiniSlider {
        width: parent.width
        knob: false
        value: root.dockStore ? (root.dockStore.iconMax - 28) / 44 : 0.3
        onChanged: v => { if (root.dockStore) root.dockStore.iconMax = Math.max((root.dockStore ? root.dockStore.iconBase : 28) + 4, Math.round(28 + v * 44)); }
      }
    }
  }

  // ── pinned apps ──
  Row {
    width: parent.width
    Text {
      width: parent.width - 70
      text: "Pinned apps"
      color: Theme.textMuted
      font.family: shellFont.family; font.pixelSize: 11
    }
    Text {
      width: 70
      text: "Reset"
      color: Theme.textMuted
      font.family: shellFont.family; font.pixelSize: 11
      horizontalAlignment: Text.AlignRight
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { if (root.dockStore) root.dockStore.resetDefaults(); }
      }
    }
  }

  Column {
    width: parent.width
    spacing: 4
    Repeater {
      model: root.dockStore ? root.dockStore.pinned : []
      delegate: Item {
        required property var modelData
        required property int index
        width: root.width; height: 30
        Row {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 96
          spacing: 10
          // icon preview
          Item {
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter
            Image {
              visible: !(modelData.icon || "").startsWith("lucide:")
              anchors.centerIn: parent
              width: 20; height: 20
              source: "image://icon/" + (modelData.icon || "application-x-executable")
              fillMode: Image.PreserveAspectFit
              smooth: true
              onStatusChanged: if (status === Image.Error) source = "image://icon/application-x-executable"
            }
            Lucide {
              visible: (modelData.icon || "").startsWith("lucide:")
              anchors.centerIn: parent
              name: (modelData.icon || "").startsWith("lucide:") ? (modelData.icon || "").slice(7) : ""
              px: 16
            }
          }
          Text {
            width: parent.width - 32
            anchors.verticalCenter: parent.verticalCenter
            text: (modelData.id || "?") + "  ·  " + (modelData.exec || "")
            color: Theme.text
            font.family: shellFont.family; font.pixelSize: 12
            elide: Text.ElideRight
          }
        }
        // reorder + remove
        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 12
          Text {
            text: "↑"; color: upMa.containsMouse ? "#ffffff" : Theme.textMuted
            font.family: shellFont.family; font.pixelSize: 13
            MouseArea { id: upMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dockStore.move(index, -1) }
          }
          Text {
            text: "↓"; color: downMa.containsMouse ? "#ffffff" : Theme.textMuted
            font.family: shellFont.family; font.pixelSize: 13
            MouseArea { id: downMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dockStore.move(index, 1) }
          }
          Text {
            text: "✕"; color: delMa.containsMouse ? Theme.red : Theme.textMuted
            font.family: shellFont.family; font.pixelSize: 13
            MouseArea { id: delMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dockStore.removeAt(index) }
          }
        }
      }
    }
  }

  // ── add new ──
  Column {
    width: parent.width
    spacing: 6
    Text {
      text: "Add app  (id · exec · icon)"
      color: Theme.textMuted
      font.family: shellFont.family; font.pixelSize: 11
    }
    Row {
      width: parent.width
      spacing: 8
      Repeater {
        model: ["id", "exec", "icon"]
        delegate: Rectangle {
          required property var modelData
          property string key: modelData
          width: (root.width - 66) / 3; height: 30
          radius: 9
          color: Theme.ground(0x22/255)
          TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 10
            verticalAlignment: Text.AlignVCenter
            color: "#ffffff"
            font.family: shellFont.family; font.pixelSize: 12
            clip: true
          }
          Text {
            visible: field.text === ""
            anchors.fill: parent
            anchors.leftMargin: 10
            verticalAlignment: Text.AlignVCenter
            text: parent.key
            color: Theme.textMuted
            font.family: shellFont.family; font.pixelSize: 12
          }
        }
      }
      Rectangle {
        width: 50; height: 30
        radius: 9
        color: "#40ffffff"
        Text {
          anchors.centerIn: parent
          text: "Add"
          color: "#ffffff"
          font.family: shellFont.family; font.pixelSize: 12; font.bold: true
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            // fields are the 3 Repeater delegates (each child's first kid is its TextInput)
            const row = parent.parent;
            const id = row.children[0].children[0].text.trim();
            const exec = row.children[1].children[0].text.trim();
            const icon = row.children[2].children[0].text.trim() || id;
            if (id === "" || exec === "") return;
            root.dockStore.addApp(id, exec, icon);
            row.children[0].children[0].text = "";
            row.children[1].children[0].text = "";
            row.children[2].children[0].text = "";
          }
        }
      }
    }
  }
}
