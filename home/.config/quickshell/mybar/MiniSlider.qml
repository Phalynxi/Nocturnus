// Minimal borderless slider for the mixer.
import QtQuick

Item {
  id: root
  property real value: 0.5
  property bool vertical: false
  property bool knob: true
  signal changed(real v)

  implicitHeight: 22

  QtObject { id: d; property bool drag: false }

  function setFromX(x) {
    changed(Math.max(0, Math.min(1, x / root.width)));
  }
  function setFromY(y) {
    changed(Math.max(0, Math.min(1, 1 - y / root.height)));
  }

  // track
  Rectangle {
    anchors.centerIn: parent
    width: root.vertical ? 22 : parent.width
    height: root.vertical ? parent.height : 4
    radius: root.vertical ? 11 : 2
    color: "#22ffffff"
  }
  // fill
  Rectangle {
    x: root.vertical ? (parent.width - 22) / 2 : 0
    y: root.vertical ? parent.height - height : (parent.height - 4) / 2
    width: root.vertical ? 22 : root.value * root.width
    height: root.vertical ? root.value * root.height : 4
    radius: root.vertical ? 11 : 2
    color: Theme.text
  }
  // knob (horizontal with knob enabled only)
  Rectangle {
    visible: !root.vertical && root.knob
    anchors.verticalCenter: parent.verticalCenter
    x: root.value * (root.width - 12)
    width: 12; height: 12; radius: 6
    color: "#ffffff"
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onPressed: mouse => { d.drag = true; root.vertical ? root.setFromY(mouse.y) : root.setFromX(mouse.x); }
    onReleased: d.drag = false
    onPositionChanged: mouse => { if (d.drag) { root.vertical ? root.setFromY(mouse.y) : root.setFromX(mouse.x); } }
    onWheel: wheel => root.changed(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
  }
}
