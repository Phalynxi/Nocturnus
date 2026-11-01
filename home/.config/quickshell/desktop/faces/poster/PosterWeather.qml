// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P O S T E R   W E A T H E R                                            │
// │   now, the hours ahead, and the days · on the widget's capsule           │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import "../../../theme"
import "../../../services"

// The place over the temperature, the sky and the day's range beside it;
// then a row of the next hours, and on the large face a line per day with
// its range drawn against the week's.
Item {
    id: root

    property string family: "4x4"
    property var ink: DesktopService.inkFor(null)

    readonly property bool known: WeatherService.available
    readonly property bool large: root.family === "4x4"
    readonly property int pad: 20

    // Now, then wttr.in's three-hour blocks still to come.
    readonly property var hours: {
        const hour = WeatherService.clock.date.getHours()
        const later = (WeatherService.hourly ?? [])
            .filter(block => block.tomorrow || block.hour > hour)
            .slice(0, 5)
        return [{ label: "Now", glyph: WeatherService.glyph, temperature: WeatherService.temperature }]
            .concat(later.map(block => ({
                label: `${String(block.hour).padStart(2, "0")}:00`,
                glyph: block.glyph,
                temperature: block.temperature
            })))
    }

    readonly property var days: WeatherService.daily ?? []
    readonly property int floor: Math.min(...root.days.map(day => day.low), 99)
    readonly property int ceiling: Math.max(...root.days.map(day => day.high), -99)

    function dayName(day: var, index: int): string {
        return index === 0 ? "Today"
            : Qt.formatDate(new Date(`${day.date}T12:00:00`), "ddd")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 12

        // ── NOW ─────────────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.known
                        ? [WeatherService.place, WeatherService.region].filter(part => part).join(", ")
                        : "No reading"
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall + 2
                    font.weight: Font.DemiBold
                    color: root.ink.text
                }

                Text {
                    text: root.known ? `${WeatherService.temperature}°` : "—"
                    font.family: Theme.fontDisplay
                    font.pixelSize: 52
                    font.weight: Font.Bold
                    color: root.ink.text
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignBottom
                spacing: 2

                Text {
                    text: root.known ? WeatherService.glyph : "󰖐"
                    font.family: Theme.fontMono
                    font.pixelSize: 28
                    color: root.ink.text
                }

                Text {
                    text: WeatherService.description
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall + 1
                    font.weight: Font.DemiBold
                    color: root.ink.text
                }

                Text {
                    visible: root.known
                    text: `H:${WeatherService.high}°  L:${WeatherService.low}°`
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.ink.muted
                }
            }
        }

        // ── HOURS ───────────────────────────────────────────────────────────

        // Equal columns set by hand: a layout shares out only what is left
        // after the labels, and squeezed them into each other.
        Row {
            id: hourRow

            Layout.fillWidth: true
            visible: root.known

            Repeater {
                model: root.hours

                Column {
                    required property var modelData

                    width: hourRow.width / Math.max(1, root.hours.length)
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: root.ink.muted
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.glyph
                        font.family: Theme.fontMono
                        font.pixelSize: 22
                        color: root.ink.text
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: `${modelData.temperature}°`
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall + 1
                        font.weight: Font.DemiBold
                        color: root.ink.text
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ── DETAILS ─────────────────────────────────────────────────────────
        //
        // The large face only: what the air is like beyond the temperature.
        Row {
            id: detailRow

            Layout.fillWidth: true
            visible: root.large && root.known

            Repeater {
                model: [
                    { label: "Feels like", value: `${WeatherService.feelsLike}°` },
                    { label: "Humidity", value: `${WeatherService.humidity}%` },
                    { label: "Wind", value: `${WeatherService.wind} km/h` }
                ]

                Column {
                    required property var modelData

                    width: detailRow.width / 3
                    spacing: 2

                    Text {
                        text: modelData.label
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.ink.muted
                    }

                    Text {
                        text: modelData.value
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall + 4
                        font.weight: Font.DemiBold
                        color: root.ink.text
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            visible: root.large && root.days.length > 0
            color: root.ink.border
        }

        // ── DAYS ────────────────────────────────────────────────────────────

        Repeater {
            model: root.large ? root.days : []

            RowLayout {
                id: day

                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.preferredWidth: 48
                    text: root.dayName(day.modelData, day.index)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall + 1
                    font.weight: Font.DemiBold
                    color: root.ink.text
                }

                Text {
                    text: day.modelData.glyph
                    font.family: Theme.fontMono
                    font.pixelSize: 18
                    color: root.ink.text
                }

                Text {
                    Layout.preferredWidth: 28
                    horizontalAlignment: Text.AlignRight
                    text: `${day.modelData.low}°`
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall + 1
                    color: root.ink.muted
                }

                // The day's range against the coolest and warmest of all.
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5

                    readonly property real span: Math.max(1, root.ceiling - root.floor)

                    Rectangle {
                        anchors.fill: parent
                        radius: 2.5
                        color: root.ink.raised
                    }

                    Rectangle {
                        x: parent.width * (day.modelData.low - root.floor) / parent.span
                        width: Math.max(parent.height,
                            parent.width * (day.modelData.high - day.modelData.low) / parent.span)
                        height: parent.height
                        radius: 2.5
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Qt.tint(root.ink.accent, Qt.rgba(1, 1, 1, 0.45)) }
                            GradientStop { position: 1; color: root.ink.yellow }
                        }
                    }
                }

                Text {
                    Layout.preferredWidth: 28
                    text: `${day.modelData.high}°`
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall + 1
                    font.weight: Font.DemiBold
                    color: root.ink.text
                }
            }
        }
    }
}
