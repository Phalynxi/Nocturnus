// Month calendar: arrows to move, click title for today.
import QtQuick

Column {
  ShellFont { id: shellFont }
  id: root
  width: parent.width
  spacing: 8

  property date now: new Date()
  property int viewYear: now.getFullYear()
  property int viewMonth: now.getMonth() // 0-11
  property var cells: []

  readonly property var monthNames: ["January","February","March","April","May","June","July","August","September","October","November","December"]

  function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate(); }
  function leadBlanks(y, m) { return (new Date(y, m, 1).getDay() + 6) % 7; } // Monday-first

  function rebuild() {
    const y = root.viewYear, m = root.viewMonth;
    const t = new Date();
    const out = [];
    for (let i = 0; i < root.leadBlanks(y, m); i++) out.push({ day: 0, today: false });
    const n = root.daysInMonth(y, m);
    for (let d = 1; d <= n; d++)
      out.push({ day: d, today: d === t.getDate() && m === t.getMonth() && y === t.getFullYear() });
    root.cells = out;
  }

  function shift(k) {
    let m = root.viewMonth + k, y = root.viewYear;
    while (m < 0) { m += 12; y--; }
    while (m > 11) { m -= 12; y++; }
    root.viewMonth = m; root.viewYear = y;
    root.rebuild();
  }

  function goToday() {
    const t = new Date();
    root.viewYear = t.getFullYear(); root.viewMonth = t.getMonth();
    root.rebuild();
  }

  Row {
    width: parent.width
    Item {
      width: 30; height: 22
      Lucide { anchors.centerIn: parent; name: "chevron-left"; px: 16; opacity: prevMa.containsMouse ? 1 : 0.6 }
      MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.shift(-1) }
    }
    Text {
      text: root.monthNames[root.viewMonth] + " " + root.viewYear
      color: "#ffffff"
      font.family: shellFont.family; font.pixelSize: 13; font.bold: true
      width: parent.width - 60
      horizontalAlignment: Text.AlignHCenter
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.goToday() }
    }
    Item {
      width: 30; height: 22
      Lucide { anchors.centerIn: parent; name: "chevron-right"; px: 16; opacity: nextMa.containsMouse ? 1 : 0.6 }
      MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.shift(1) }
    }
  }

  Grid {
    width: parent.width
    columns: 7
    Repeater {
      model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
      delegate: Text {
        required property var modelData
        text: modelData
        color: Theme.textMuted
        font.family: shellFont.family; font.pixelSize: 11
        width: root.width / 7
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }

  Grid {
    width: parent.width
    columns: 7
    Repeater {
      model: root.cells
      delegate: Item {
        required property var modelData
        width: root.width / 7; height: 26
        Text {
          anchors.centerIn: parent
          text: modelData.day === 0 ? "" : modelData.day
          color: modelData.today ? "#ffffff" : Theme.text
          font.family: shellFont.family; font.pixelSize: 12
          font.bold: modelData.today
        }
        Rectangle {
          visible: modelData.today
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 3
          width: 4; height: 4; radius: 2
          color: "#ffffff"; opacity: 0.8
        }
      }
    }
  }

  Component.onCompleted: root.rebuild()
}
