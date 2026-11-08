// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W A T C H   S E R V I C E                                              │
// │   the machine kept an eye on · one word when something runs too far      │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell

// Reads `StatsService` at every sample and says so, once, when the processor
// runs hot, memory nearly fills or the system disk is nearly full. Each
// watch has a line to cross and a lower one to fall back under before it can
// speak again, so a reading that hovers at the line does not repeat itself;
// the heat and the memory must also stay over for a few samples, so a
// moment's spike says nothing. The word goes out as a notification, which the
// shell is the daemon for: it takes the island. The heat is critical and gets
// through do-not-disturb, gaming mode's included.
Singleton {
    id: root

    // Read in `shell.qml` so the watch runs from boot.
    readonly property bool ready: true

    readonly property var rootDisk: (StatsService.disks ?? []).find(disk => disk.target === "/") ?? null

    //   id       what is watched
    //   value    the reading, a fraction (heat in hundreds of degrees)
    //   over     the line that raises it
    //   under    the line it must fall back under before it can raise again
    //   hold     samples it must stay over first
    //   urgency  notify-send's
    readonly property var watches: [
        { id: "heat", value: StatsService.temperature ? StatsService.temperature.celsius / 100 : 0,
          over: 0.90, under: 0.80, hold: 3, urgency: "critical",
          title: "Running hot",
          body: () => `The processor is at ${Math.round(StatsService.temperature.celsius)} °C.` },
        { id: "memory", value: StatsService.memoryFraction,
          over: 0.92, under: 0.85, hold: 3, urgency: "normal",
          title: "Memory nearly full",
          body: () => `${Math.round(StatsService.memoryFraction * 100)}% of memory is in use.` },
        { id: "disk", value: root.rootDisk ? root.rootDisk.used / root.rootDisk.total : 0,
          over: 0.95, under: 0.92, hold: 1, urgency: "normal",
          title: "System disk nearly full",
          body: () => `/ is ${Math.round(100 * root.rootDisk.used / root.rootDisk.total)}% full.` }
    ]

    // Per watch: samples spent over the line, and whether it has spoken.
    property var streak: ({})
    property var raised: ({})

    function check(): void {
        const streak = Object.assign({}, root.streak)
        const raised = Object.assign({}, root.raised)
        for (const watch of root.watches) {
            if (watch.value >= watch.over) {
                streak[watch.id] = (streak[watch.id] ?? 0) + 1
                if (!raised[watch.id] && streak[watch.id] >= watch.hold) {
                    raised[watch.id] = true
                    Quickshell.execDetached(["notify-send", "-a", "Nocturnus",
                        "-u", watch.urgency, "-i", "dialog-warning",
                        watch.title, watch.body()])
                }
            } else {
                streak[watch.id] = 0
                if (watch.value < watch.under)
                    raised[watch.id] = false
            }
        }
        root.streak = streak
        root.raised = raised
    }

    // One check per sample, after the sample has landed.
    Connections {
        target: StatsService

        function onCpuHistoryChanged(): void {
            Qt.callLater(root.check)
        }
    }
}
