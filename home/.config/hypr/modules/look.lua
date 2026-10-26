-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │                                                                          │
-- │   L O O K                                                                │
-- │   appearance · gaps, borders, blur, layouts                              │
-- │                                                                          │
-- │   github.com/Phalynxi/Nocturnus                                      │
-- │                                                                          │
-- ╰──────────────────────────────────────────────────────────────────────────╯

-- ── GENERAL ─────────────────────────────────────────────────────────────────

hl.config({
    general = {
        -- gaps_out matches the bar's edge margin (Bar.edgeMargin). gaps_in
        -- applies to each side, so 7 gives 14 px between windows.
        gaps_in  = 7,
        gaps_out = 18,

        -- No borders, hence no col.*_border: the gaps and rounding separate
        -- windows.
        border_size = 0,

        -- Snap floating windows to the same gaps tiled ones get.
        snap = {
            enabled        = true,
            window_gap     = 14,
            monitor_gap    = 18,
            border_overlap = false,
        },

        resize_on_border = true,
        allow_tearing    = false,

        layout = "dwindle",
    },
})


-- ── DECORATION ──────────────────────────────────────────────────────────────

hl.config({
    decoration = {
        -- rounding_power 2 is a circular arc, like a QML Rectangle's corner.
        rounding       = 22,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        -- Toggled from Settings → Appearance: CompositorService.applyShadow
        -- pushes it at startup and on `configreloaded`, using the values in
        -- Theme.qml (shared with the bar's capsules). Off without the shell.
        shadow = {
            enabled      = false,
            range        = 14,
            render_power = 3,
        },

        blur = {
            enabled           = true,
            size              = 6,
            passes            = 2,
            ignore_opacity    = true,
            new_optimizations = true,
            xray              = true,
        },
    },
})


-- ── GLASS ───────────────────────────────────────────────────────────────────

-- hyprglass (built by `./setup plugins`): refracted blur behind windows. The
-- guard skips the block on the first parse, before the plugin is loaded.
--
-- Off without the shell; toggled from Settings → Appearance and pushed by
-- CompositorService like the shadow.
--
-- Tuned for kitty at 0.90 opacity, where the defaults flatten the background
-- into a wash: less blur, no dimming or tone mapping, a lighter tint and a
-- stronger edge. Only values that differ from the defaults are listed. Layers
-- stay off (the default).
if hl.plugin.hyprglass ~= nil then
    hl.plugin.hyprglass.config({
        enabled = false,

        -- Glass on layer surfaces too: the bar's pills, the dock, the deck
        -- and the launcher all refract the desk under them, not just blur
        -- it. `mask_threshold` is per layer, set by `hg.layer` calls below.
        layers = { enabled = true },

        blur_strength        = 0.7,    -- default 2.0

        -- Edge effects, all raised so the pane still reads at 0.90 opacity.
        refraction_strength  = 1.0,
        chromatic_aberration = 0.6,
        fresnel_strength     = 1.0,
        specular_strength    = 1.0,
        edge_thickness       = 0.10,

        -- Less magnification; it smears at this blur level.
        lens_distortion      = 0.3,

        -- Default tint at half alpha.
        tint_color           = 0x8899aa11,

        -- Tone mapping off: the dark preset dims and flattens an already
        -- dark wallpaper.
        dark = {
            brightness   = 1.0,
            contrast     = 1.0,
            saturation   = 0.9,
            adaptive_dim = 0.0,
        },
    })

    -- The layers given glass, named one by one so the rest — the wallpaper
    -- daemon's underlay above all — keep Hyprland's blur. The threshold sits
    -- between the grounds (0.60 on the bar, 0.86 in the dock) and the pill
    -- shadows (0.50), so the shadows stay matte instead of turning into
    -- lenses of their own. The bar itself stays out: its refraction pulled
    -- the tops of open windows into the notch — the wash grew with every
    -- window behind it — and its own blur rule paints the ground well.
    hl.plugin.hyprglass.layer("nocturnus-bar",        { exclude = true })
    hl.plugin.hyprglass.layer("nocturnus-dock",       { mask_threshold = 0.55 })
    hl.plugin.hyprglass.layer("nocturnus-desktop",    { mask_threshold = 0.55 })
    hl.plugin.hyprglass.layer("nocturnus-deck",       { mask_threshold = 0.55 })
    hl.plugin.hyprglass.layer("nocturnus-launcher",   { mask_threshold = 0.55 })
    hl.plugin.hyprglass.layer("nocturnus-wallpapers", { mask_threshold = 0.55 })
    -- The notification toast: a pill of its own in the glass family.
    hl.plugin.hyprglass.layer("nocturnus-toast",      { mask_threshold = 0.55 })
end


-- ── LAYOUTS ─────────────────────────────────────────────────────────────────

hl.config({
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },

    -- No update news or donation popups.
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})
