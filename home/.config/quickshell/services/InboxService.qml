// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I N B O X   S E R V I C E                                              │
// │   GitHub notifications · unread, opened, marked read                     │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The GitHub notifications still unread, through `gh_inbox.py`, which uses
// gh's own login. Polled every two minutes while the inbox is on the bar.
// Opening one marks it read, as the website does.
Singleton {
    id: root

    // Two minutes.
    readonly property int pollInterval: 120000

    property int watchers: 0
    property bool available: false
    property bool checking: false

    // `{ id, repo, title, kind, reason, url }`, newest first.
    property var items: []
    readonly property int count: root.items.length

    // Query on construction: the bar only builds the module once `available`
    // is known, and reading it is what constructs the singleton.
    Component.onCompleted: root.refresh()

    function subscribe(): void {
        root.watchers += 1
    }

    function release(): void {
        root.watchers = Math.max(0, root.watchers - 1)
    }

    function refresh(): void {
        if (root.checking)
            return
        root.checking = true
        root.query.running = true
    }

    // Opens the page and drops the row at once; the mark follows in the
    // background, and the next poll agrees with it.
    function open(item: var): void {
        Quickshell.execDetached(["xdg-open", item.url])
        root.items = root.items.filter(other => other.id !== item.id)
        Quickshell.execDetached([root.script, "read", item.id])
    }

    function openUrl(url: string): void {
        Quickshell.execDetached(["xdg-open", url])
    }

    function markAllRead(): void {
        root.items = []
        root.marker.running = true
    }

    readonly property string script: Quickshell.shellPath("scripts/gh_inbox.py")

    readonly property Timer poller: Timer {
        interval: root.pollInterval
        repeat: true
        running: root.watchers > 0
        onTriggered: root.refresh()
    }

    readonly property Process marker: Process {
        command: [root.script, "read"]
        onExited: root.refresh()
    }

    readonly property Process query: Process {
        command: [root.script, "list"]
        onExited: root.checking = false
        stdout: StdioCollector {
            // Per stream, never per chunk: JSON.parse on half a document
            // throws, and the collector fires as the pipe fills.
            onStreamFinished: {
                let report = null
                try {
                    report = JSON.parse(text)
                } catch (error) {
                    console.warn("Cannot parse the GitHub inbox:", error)
                    return
                }
                root.available = report.available === true
                if (root.available)
                    root.items = report.items ?? []
            }
        }
    }
}
