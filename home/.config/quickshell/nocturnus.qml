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
import "lock"
import "services"

// The new shell: a bar, a dock, a launcher and a wallpaper switcher, all
// painted from Theme, so whatever wallpaper is up repaints every piece.
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

    // The lock: a full surface over the desk with the island look, driven by
    // IdleService for idle, SleeveService for sleep.
    LockScreen {}

    // Global shortcuts: keybinds.lua binds a key to the name, and the action
    // lives here, so a new panel needs no compositor config.
    GlobalShortcut {
        id: launcherShortcut
        name: "launcher"
        description: "Open the launcher"
        onPressed: launcher.toggle()
    }

    GlobalShortcut {
        id: wallpapersShortcut
        name: "wallpapers"
        description: "Open the wallpaper switcher"
        onPressed: wallGrid.toggle()
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
}
