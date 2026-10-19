-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │                                                                          │
-- │   H Y P R L A N D                                                        │
-- │   wayland compositor · entry point                                       │
-- │                                                                          │
-- │   github.com/Phalynxi/Nocturnus                                      │
-- │                                                                          │
-- ╰──────────────────────────────────────────────────────────────────────────╯

-- Lua config (Hyprland 0.55+); hyprlang is deprecated.
-- https://wiki.hypr.land/Configuring/Start/
--
-- This file only loads the modules in modules/, in order. Hyprland runs each
-- require in its own scope: an error in one module will not break the rest.

require("modules.monitors")
require("modules.autostart")
require("modules.env")
require("modules.look")
require("modules.animations")
require("modules.input")
require("modules.keybinds")
require("modules.windowrules")
require("modules.plugins")

-- Tide Island shortcuts: begin (managed by Tide Island Config App).
-- Empty shortcuts are disabled and intentionally omitted.
hl.bind("SUPER + bracketleft", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call island toggle"))
-- Tide Island shortcuts: end.
