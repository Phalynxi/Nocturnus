// Lucide SVG icon (pre-tinted #e6e6e6, see icons/).
import QtQuick

Image {
  property string name: ""
  property real px: 16
  source: name !== "" ? "icons/" + name + ".svg" : ""
  width: px; height: px
  fillMode: Image.PreserveAspectFit
  smooth: true
}
