# Nocturnus

> A Hyprland shell whose colours come from a painting.
> One black island that changes shape, a desk of widgets under the windows,
> and every program around it repainted by whatever wallpaper is up.

My personal desk, built on top of
[impasto](https://github.com/andreumassanet/impasto) by
Andreu Massanet — the dynamic-island Quickshell shell this repository began
as, under the GPL-3.0 (see [LICENSE](LICENSE)).

- **Compositor:** Arch Linux + Hyprland (Lua config in `home/.config/hypr/`)
- **Shell:** Quickshell — the island, the bar, the dock, notes, games
  (`home/.config/quickshell/`)
- **Palette:** pick a wallpaper and everything follows it — the terminal, the
  prompt, the monitor, the widgets, even Spotify
- **Everything else, in a table:**

| | | |
|---|---|---|
| 🪟 | Compositor | Hyprland |
| 🐚 | Desktop shell | Quickshell |
| 🖼️ | Wallpaper daemon | awww |
| 🖥️ | Terminal | kitty |
| ⌨️ | Interactive shell | fish |
| ❯ | Prompt | starship |
| 🎨 | Greeting | fastfetch |
| 📊 | System monitor | btop |
| 🎵 | Audio visualiser | cava |
| 🌐 | Browser | Thorium |
| 📁 | File manager | Nautilus |
| ✏️ | Editor | VSCodium |
| 💬 | Chat | Vesktop |
| 🎧 | Player | Spotify · spicetify |
| 🔑 | Login screen | SDDM |
| 👤 | Face unlock | howdy-next |

## Install

```bash
git clone https://github.com/Phalynxi/Nocturnus.git ~/nocturnus
cd ~/nocturnus
./setup install
```

Arch Linux, Hyprland 0.56+ configured in Lua. `./setup` lists every verb;
`./setup update` re-syncs the desk after a `git pull`.

lore on keys, palettes and profiles lives inside the Settings app
(`SUPER + H` floats over the island).

## Credits

- [impasto](https://github.com/andreumassanet/impasto) — Andreu Massanet's
  original shell, whose code and paintings carry this project (GPL-3.0)
- [Quickshell](https://quickshell.org) and
  [Hyprland](https://hypr.land), which it is built on
- The pointer is [Bibata](https://github.com/ful1e5/Bibata_Cursor), the
  folders are [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme),
  and the type is Inter + JetBrains Mono
- Six of the palettes: Catppuccin, Tokyo Night, Gruvbox, Nord, Rosé Pine

## License

GPL-3.0 — same as impasto. Copyright of the upstream shell belongs to Andreu
Massanet; my changes are mine.
