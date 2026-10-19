// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N O C T U R N U S                                                      │
// │   quickshell entry point · the new desk shell                            │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

// Greyscale text: subpixel edges assume an opaque ground and fringe on a
// transparent surface.
//@ pragma Env QSG_DISTANCEFIELD_ANTIALIASING=gray

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

import "noct"
import "desktop"
import "lock"
import "settings"
import "capture"
import "services"

// The new shell: a bar, a dock, a launcher, a wallpaper switcher and a deck
// for every panel, all painted from Theme, so whatever wallpaper is up
// repaints every piece. The ghost island keeps the notifications, the OSD
// and the module details coming.
ShellRoot {
    id: root

    // Singletons are built on first use. Each of these has to be running from
    // boot, not from the moment a panel first reads it — kept from the old
    // shell so the desk behaves the same.
    Component.onCompleted: {
        void ThemeService.activeId
        void LauncherService.applications
        void CompositorService.animationPreset
        void MonitorService.loaded
        void ShortcutService.catalogue
        void AccountService.user
        void PickerService.available
        void ClipboardService.count
        void RecorderService.available
        void SunsetService.available
        void IdleService.lockAfter
        void SessionService.sleepPending
        void ProfileService.arrived
    }

    Bar {
        id: bar
        onLauncherRequested: launcher.show()
        onWallpapersRequested: wallGrid.show()
    }

    Dock {
        id: dock
        onLauncherRequested: launcher.show()
    }

    Launcher {
        id: launcher
    }

    Wallpapers {
        id: wallGrid
    }

    // Every island panel except the pet, which is gone.
    PanelDeck {
        id: deck
        onSettingsRequested: settingsWindow.toggle()
    }

    // Notifications, the OSD and the module details. Composite windows of
    // their own, not panels.
    Ghost {
        id: ghost
    }

    // The widget shelf on the desk's ground, one per screen.
    Variants {
        model: Quickshell.screens

        Desktop {
            required property var modelData

            screen: modelData
        }
    }

    SettingsWindow {
        id: settingsWindow
        onPanelRequested: panel => deck.openPanel(panel)
    }

    // A normal window rather than a deck panel, so the desk stays visible.
    CaptureOverlay {}

    Connections {
        target: DesktopService

        function onSettingsRequested(): void {
            deck.close()
            settingsWindow.open()
        }
    }

    // The lock is up before the keyboard needs it: nothing else to wait for.
    Binding {
        target: LockService
        property: "shellQuiet"
        value: true
    }

    // The compositor reaches in here: `qs -p <this file> ipc call <target>`.
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            launcher.toggle()
        }

        function close(): void {
            launcher.close()
        }
    }

    IpcHandler {
        target: "wallpapers"

        function toggle(): void {
            wallGrid.toggle()
        }

        function close(): void {
            wallGrid.close()
        }
    }

    IpcHandler {
        target: "panels"

        function open(name: string): string {
            if (!name)
                return "usage: qs -p <config> ipc call panels open <name>"
            deck.openPanel(name)
            return name
        }
    }

    // Global shortcuts: keybinds.lua binds a key to the name, and the action
    // lives here, so a new panel needs no compositor config.
    GlobalShortcut {
        name: "launcher"
        description: "Open the launcher"
        onPressed: launcher.toggle()
    }

    GlobalShortcut {
        name: "wallpapers"
        description: "Open the wallpaper switcher"
        onPressed: wallGrid.toggle()
    }

    GlobalShortcut {
        name: "controls"
        description: "Open the quick controls"
        onPressed: deck.toggle("controls")
    }

    GlobalShortcut {
        name: "overview"
        description: "Open the workspace overview"
        onPressed: deck.toggle("overview")
    }

    GlobalShortcut {
        name: "settings"
        description: "Open the settings window"
        onPressed: settingsWindow.toggle()
    }

    GlobalShortcut {
        name: "appearance"
        description: "Open the appearance panel"
        onPressed: deck.toggle("appearance")
    }

    // Same panel, on the palette strip. Each name only closes from its own
    // strip.
    GlobalShortcut {
        name: "palette"
        description: "Open the appearance panel on the palettes"
        onPressed: deck.toggle("palette")
    }

    GlobalShortcut {
        name: "stats"
        description: "Open system statistics"
        onPressed: deck.toggle("stats")
    }

    GlobalShortcut {
        name: "games"
        description: "Open the games"
        onPressed: deck.toggle("games")
    }

    GlobalShortcut {
        name: "notes"
        description: "Open the notes"
        onPressed: deck.toggle("notes")
    }

    GlobalShortcut {
        name: "board"
        description: "Open the task board"
        onPressed: deck.toggle("board")
    }

    GlobalShortcut {
        name: "capture"
        description: "Open the capture surface"
        onPressed: CaptureService.open("", "", "", 0)
    }
}
