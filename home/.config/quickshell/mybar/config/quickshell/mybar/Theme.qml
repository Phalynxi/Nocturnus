// ── THEME ───────────────────────────────────────────────────────────────────
// Wallpaper-adaptive palette, shared with the main shell. The adaptive
// colours live in ~/.local/state/quickshell/dynamic-colors.json (written by
// scripts/theme_manager.py); this singleton watches that file so a palette
// change repaints the bar without a restart.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"

    readonly property FileView file: FileView {
        path: root.stateDir + "/quickshell/dynamic-colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.read()
        onLoadFailed: root.colors = ({})
    }

    property var colors: ({})

    function read(): void {
        try {
            root.colors = JSON.parse(root.file.text())
        } catch (error) {
            console.warn("mybar: cannot parse dynamic-colors.json:", error)
            root.colors = ({})
        }
    }

    function col(name: string, fallback: string): color {
        const value = root.colors[name]
        return value ? value : fallback
    }

    // Previous built-in Catppuccin Mocha values as fallbacks, so the bar
    // still renders before the first extraction has run.
    readonly property color background: root.col("background", "#11111b")
    readonly property color surface:    root.col("surface",    "#1e1e2e")
    readonly property color text:       root.col("text",       "#cdd6f4")
    readonly property color textMuted:  root.col("textMuted",  "#a6adc8")
    readonly property color accent:     root.col("accent",     "#cba6f7")
    readonly property color red:        root.col("red",        "#f38ba8")
    readonly property color green:      root.col("green",      "#a6e3a1")
    readonly property color yellow:     root.col("yellow",     "#f9e2af")
    readonly property color blue:       root.col("blue",       "#89b4fa")

    // Background at a given alpha: panels used to be "#AA11111b" literals.
    function ground(alpha: real): color {
        return Qt.rgba(root.background.r, root.background.g, root.background.b, alpha)
    }

    function redA(alpha: real): color {
        return Qt.rgba(root.red.r, root.red.g, root.red.b, alpha)
    }
}
