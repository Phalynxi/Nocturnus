-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │                                                                          │
-- │   G A M I N G                                                            │
-- │   blur off for FPS · fades slowly · SUPER + SHIFT + G                    │
-- │                                                                          │
-- │   github.com/Phalynxi/Nocturnus                                      │
-- │                                                                          │
-- ╰──────────────────────────────────────────────────────────────────────────╯

-- Blur is the most expensive decoration. Gaming mode fades it away — size
-- and passes step down to zero, then the blur is disabled — and fades it
-- back the same way, so the change is never a hard cut. `enabled = false`
-- gates both window and layer (bar/dock/widgets) blur.
--
-- Turned on by SUPER + SHIFT + G, or automatically when Roblox (Sober) is
-- fullscreen for `delay` ms. The auto trigger only switches the mode off
-- again once the game closes — a manual toggle silences it until then.
-- Thorium games are manual-only: Thorium is also used for fullscreen video,
-- so auto-triggering on its class would misfire.

local SIZE  = 1   -- matches modules/look.lua
local PASSES = 2   -- matches modules/look.lua

local FADE_MS  = 900  -- length of the fade
local STEPS    = 22    -- blur steps per fade
local DELAY_MS = 4000 -- auto trigger delay

local on          = false -- settled state: true = blur is off
local auto        = false -- the auto trigger turned it on
local timer       = nil   -- fade timer
local delay_timer = nil   -- auto trigger delay timer
local fading_to   = nil   -- in-progress fade target, nil when idle
local suppress_auto = false -- manual toggle silences auto until the game exits
local cur_size, cur_passes = SIZE, PASSES

local function stop_fade()
    if timer then
        timer:set_enabled(false)
        timer = nil
    end
    fading_to = nil
end

local function fade_to(want)
    if fading_to == want then
        return
    end
    if fading_to == nil and want == on then
        return
    end
    stop_fade()
    fading_to = want
    cur_size, cur_passes = want and 0 or SIZE, want and 0 or PASSES
    local conf = want
        and { decoration = { blur = { enabled = false } } }
        or { decoration = { blur = { enabled = true, size = SIZE, passes = PASSES } } }
    hl.config(conf)
    -- Liquid glass too: hyprglass owns the blur when it is on, so gaming
    -- mode dismisses it rather than paying its refraction mid-fight. On the
    -- way back the window-glass setting's choice is restored (true while
    -- Appearance has it on; CompositorService corrects it on any change).
    if hl.plugin.hyprglass ~= nil then
        hl.plugin.hyprglass.config({ enabled = not want })
    end
    on = want
    fading_to = nil
end

local function set(on_, source)
    auto = on_ and source == "auto"
    fade_to(on_)
end

-- Auto-trigger only when a real game is fullscreen, never while you are just
-- using a window. Add your game classes here.
local GAMES = {
    ["org.vinegarhq.Sober"] = true, -- Roblox via Sober
    -- Thorium is used for both games and fullscreen video; it would misfire,
    -- so it stays manual (Super+Shift+G) rather than auto.
}

local function condition()
    for _, w in ipairs(hl.get_windows() or {}) do
        if w.fullscreen and w.fullscreen ~= 0 and GAMES[w.class] then
            return true
        end
    end
    return false
end

local function stop_delay()
    if delay_timer then
        delay_timer:set_enabled(false)
        delay_timer = nil
    end
end

local function kick()
    stop_delay()
    if condition() then
        if suppress_auto then
            return
        end
        delay_timer = hl.timer(function()
            delay_timer = nil
            set(true, "auto")
        end, { timeout = DELAY_MS, type = "oneshot" })
    else
        suppress_auto = false
        if auto then
            set(false, "auto")
        end
    end
end

hl.on("window.fullscreen", kick)
hl.on("window.active", kick)
hl.on("window.close", kick)
kick()

return {
    toggle = function()
        local want = fading_to ~= nil and not fading_to or not on
        set(want, "manual")
        suppress_auto = true -- manual input wins until the current game closes
    end,
}
