#!/usr/bin/env python3
# ╭──────────────────────────────────────────────────────────────────────────╮
# │                                                                          │
# │   G H   I N B O X                                                        │
# │   GitHub notifications through gh · list, and mark read                  │
# │                                                                          │
# │   github.com/Phalynxi/Nocturnus                                      │
# │                                                                          │
# ╰──────────────────────────────────────────────────────────────────────────╯

# `gh_inbox.py list` prints the unread notifications as JSON:
#   {"available": true, "items": [{id, repo, title, kind, reason, url}]}
# with `url` the page to open in a browser. `gh_inbox.py read [ID]` marks one
# thread read, or every one without an ID. Uses gh's own login, so there is
# no token to keep here. Prints {"available": false} when gh is missing or
# signed out; a widget must never take the shell down.

import json
import re
import subprocess
import sys

# What each kind of subject is called on the card.
KINDS = {
    "PullRequest": "Pull request",
    "Issue": "Issue",
    "CheckSuite": "Checks",
    "Release": "Release",
    "Discussion": "Discussion",
    "Commit": "Commit",
}


def gh(*args):
    return subprocess.run(["gh", *args], capture_output=True, text=True, check=True).stdout


def page_of(note):
    """The browser page for a notification. The API gives API urls, and none
    at all for checks, so they are rewritten or fall back to the repo."""
    repo = note["repository"]["full_name"]
    subject = note["subject"]
    url = subject.get("url") or ""
    match = re.match(r"https://api\.github\.com/repos/([^/]+/[^/]+)/(pulls|issues|commits|releases)/(.+)", url)
    if match:
        place, kind, rest = match.groups()
        kind = {"pulls": "pull", "issues": "issues", "commits": "commit", "releases": "releases"}[kind]
        if kind == "releases":
            return f"https://github.com/{place}/releases"
        return f"https://github.com/{place}/{kind}/{rest}"
    if subject.get("type") == "CheckSuite":
        return f"https://github.com/{repo}/actions"
    return f"https://github.com/{repo}"


def listing():
    notes = json.loads(gh("api", "notifications", "--paginate"))
    items = [
        {
            "id": note["id"],
            "repo": note["repository"]["full_name"],
            "title": note["subject"]["title"],
            "kind": KINDS.get(note["subject"]["type"], note["subject"]["type"]),
            "reason": note["reason"].replace("_", " "),
            "url": page_of(note),
        }
        for note in notes if note.get("unread")
    ]
    return {"available": True, "items": items}


def mark(thread):
    if thread:
        gh("api", "-X", "PATCH", f"notifications/threads/{thread}")
    else:
        gh("api", "-X", "PUT", "notifications", "-F", "read=true")
    return {"ok": True}


if __name__ == "__main__":
    verb = sys.argv[1] if len(sys.argv) > 1 else "list"
    try:
        result = listing() if verb == "list" else mark(sys.argv[2] if len(sys.argv) > 2 else "")
        print(json.dumps(result))
    except Exception as error:
        sys.stderr.write(f"gh_inbox: {error}\n")
        print(json.dumps({"available": False}))
