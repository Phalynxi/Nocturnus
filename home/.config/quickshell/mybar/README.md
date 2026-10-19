# mybar — Hyprland + Quickshell glass setup

A complete Hyprland desktop: liquid-glass top bar (full slab or floating islands),
draggable desktop widgets, a morphing mini media player, a spring-loaded toolbox
ball, glass tray menus, a macOS-style control center, wallpaper-reactive window
borders, a styled lockscreen, gaming mode, and a dashboard for everything.

## What your friend needs

**System:** Arch Linux (installer uses `pacman` + `yay`/`paru`; other distros:
match the package list below to your package manager), Hyprland session,
Internet for the downloads.

**Must-have versions** — older releases will break:

| What | Why | Min version |
|---|---|---|
| [Hyprland](https://hypr.land) | `hyprland.lua` uses the `hl.*` Lua API | **0.56+** |
| [Quickshell](https://quickshell.org) | Bar, widgets, dashboard, menus | **0.3+** |
| Qt6 + `qt6-5compat` | `Qt5Compat.GraphicalEffects` (rounded album art) | — |
| [hyprliquid](https://github.com/zaregototsukai/hyprliquid) | Liquid-glass materials (needs `stb` to build; installer pulls it from AUR, and `hyprland.lua` tries `~/.local/lib/`, then `/usr/lib/`) | 0.2.0 |

**Packages** (all in `install.sh`):

```text
repo: hyprland quickshell mpvpaper hyprlock hypridle hyprsunset
      pipewire wireplumber networkmanager upower playerctl brightnessctl
      grim slurp jq wl-clipboard btop curl ffmpeg libnotify
      ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd
      ttf-hack ttf-dejavu ttf-liberation inter-font adwaita-fonts
      gnu-free-fonts noto-fonts kitty dolphin firefox code
AUR : awww hyprliquid
```

What each backend powers: `awww`/`mpvpaper` image/video wallpapers ·
PipeWire+`wpctl` volume/mixer · `nmcli`/`upower` wifi/battery · `playerctl`
media keys + now-playing + lockscreen art · `brightnessctl` keys ·
`grim`/`slurp`/`jq`/`wl-clipboard` screenshots · `hyprlock`/`hypridle`
lock + idle lock · `hyprsunset` night light · `btop` system tile ·
`curl` weather · `ffmpeg` video-wallpaper frames · `libnotify` popups.
Everything degrades gracefully if a backend is missing — the shell still starts.

**Files to share** (this folder):

```text
mybar-share/
├── README.md                  ← you are here
├── install.sh                 ← run this on the friend's machine
├── config/quickshell/mybar/   ← the entire shell (QML + bundled Lucide icons)
├── config/hypr/               ← hyprland.lua, hyprlock.conf, hypridle.conf
├── local/bin/                 ← sysstat, shot, wp, wallborders, lockart,
│                                 locktrack, rec
└── wallpapers/ (optional)     ← drop .png/.jpg/.gif/.mp4 here to share them
```

Do **not** copy `dock.json`, `widgets.json`, `fonts.json` — the installer deletes
them so the shell boots with factory defaults and recreates them on first run.

## Tutorial (for your friend)

```sh
# 1. copy this folder to the new machine, then:
cd mybar-share
./install.sh        # installs packages, backs up old configs, copies files,
                    # rewrites /home/<olduser> → your $HOME, chmod +x helpers

# 2. monitor name: if `hyprctl monitors` shows something other than HDMI-A-1,
#    fix the two mpvpaper lines in ~/.local/bin/wp and ~/.local/bin/rec

# 3. reload + launch
hyprctl reload
quickshell -p ~/.config/quickshell/mybar/shell.qml

# 4. recommended autostart (exec-once in Hyprland config):
#    awww-daemon, quickshell -p ~/.config/quickshell/mybar/shell.qml, hypridle
#    (lockart starts itself from hyprland.lua)
```

Then: `Super+D` → Dock page (bar style, roundness, glass %, fonts, pinned apps),
Widgets page (add/move/scale desktop cards), Controls page (gaming mode).

## Keybinds (Super = main)

| Keys | Action |
|---|---|
| `Q` / `C` / `E` | kitty / close window / dolphin |
| `V` | toggle float (`Super+drag` moves, `Super+right-drag` resizes) |
| `R` / `W` / `D` | launcher / wallpaper gallery / dashboard |
| `G` / `T` | widget edit mode / toolbox ball |
| `Alt+G` | gaming mode (kills glass + blur) |
| `L` | lock |
| `S` / `Shift+Print` / `Print` | screenshot region / full / window |
| `P` / `F` / `J` | pseudo-tile / fullscreen / togglesplit |
| `1–0`, arrows, wheel | workspaces, focus |
| Media/brightness keys | `playerctl` / `wpctl` / `brightnessctl` |

## Highlights

- **Bar**: full slab or three floating islands (Dashboard → Dock), glass + blur,
  roundness and glass-intensity sliders, 16-font picker, tray icons with real
  glass context menus, macOS-style control center (wifi, music, toggles,
  sliders, quick actions).
- **Center island**: mini player that morphs into a full player (art, transport,
  waveform seekbar); auto-hides when idle.
- **Toolbox ball** (`Super+T`): springs open next to the player into Shot / Full /
  screen-record / color-picker orbs; red blinking dot while recording.
- **Widgets** (`Super+G`): clock, system, media, calendar, notes, todo, weather,
  wallpaper, quick-launch, now-playing — drag, S/M/L scale, all persisted.
- **Gaming mode** (`Super+Alt+G`): kills all liquid glass + blur for max FPS.
- **Wallpaper-reactive borders**: border gradient follows the wallpaper on every
  switch, images and video.
- **Lockscreen** (`Super+L`): blurred wallpaper, clock, now-playing, album-art
  sync daemon, idle auto-lock after 10 min.

## Troubleshooting

- **Bar doesn't appear**: read the quickshell output; needs Quickshell 0.3+ and
  Hyprland 0.56+ (Lua API).
- **Flat cards, no glass**: `hyprctl plugin list` must show hyprliquid; Glass %
  slider re-applies thickness + corner radius live.
- **`hyprctl keyword` fails**: normal — this setup is Lua-configured, everything
  goes through `hyprctl eval`.
- **CLI `hyprctl dispatch …` errors**: known quirk of the Lua build; in-config
  binds (`hl.dsp.*`) and Quickshell dispatches work fine.
- **No wallpaper on fresh login**: `awww-daemon` must autostart; videos need
  `mpvpaper` + the right monitor name in `wp`/`rec`.
- **Tray icon has no menu**: the app must expose one over StatusNotifier;
  Vesktop/Electron apps on Wayland often don't — that's app-side.
- **Wrong monitor / leftover paths**: `grep -r <olduser> ~/.config/quickshell
  ~/.config/hypr ~/.local/bin` — `install.sh` already rewrites these.
