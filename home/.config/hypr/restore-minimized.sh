#!/bin/bash
# List windows hidden on special:minimized and restore the picked one to the
# current workspace. Shown via wofi's dmenu mode.
set -u

list=$(hyprctl clients -j | jq -r \
    '.[] | select(.workspace.name == "special:minimized") | "\(.address)  \(.class) — \(.title)"')

if [ -z "${list:-}" ]; then
    notify-send "Minimise" "No minimised windows" 2>/dev/null || true
    exit 0
fi

picked=$(printf '%s\n' "$list" | wofi --dmenu --prompt 'Restore window')
[ -z "${picked:-}" ] && exit 0

addr=${picked%%  *}
target=$(hyprctl activeworkspace -j | jq '.id')
hyprctl dispatch "hl.dsp.window.move({ workspace = $target, window = \"address:$addr\" })"
