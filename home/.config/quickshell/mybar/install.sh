#!/usr/bin/env bash
# mybar-share installer — run from inside the shared folder.
# Expected layout next to this script:
#   config/quickshell/mybar/  config/hypr/  local/bin/  wallpapers/ (optional)
# Installs packages (Arch), backs up existing configs, copies files,
# rewrites the previous owner's home path, makes helpers executable.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST_HOME="$HOME"
STAMP="$(date +%Y%m%d_%H%M%S)"

log() { printf '==> %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

if [[ ! -d "$SRC/config/quickshell/mybar" ]]; then
  echo "error: run me from the shared folder (config/quickshell/mybar missing)" >&2
  exit 1
fi

# --- packages (Arch) ---------------------------------------------------------
REPO_PKGS=(hyprland quickshell mpvpaper hyprlock hypridle hyprsunset
  pipewire wireplumber networkmanager upower playerctl brightnessctl
  grim slurp jq wl-clipboard btop curl ffmpeg libnotify
  ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd ttf-hack
  ttf-dejavu ttf-liberation inter-font adwaita-fonts gnu-free-fonts noto-fonts
  kitty dolphin firefox code)
AUR_PKGS=(awww hyprliquid)

if have pacman; then
  log "installing repo packages…"
  sudo pacman -Syu --needed --noconfirm "${REPO_PKGS[@]}" || log "some packages failed — continuing"
else
  log "no pacman found — install these yourself: ${REPO_PKGS[*]} + AUR: ${AUR_PKGS[*]}"
fi

if [[ "${#AUR_PKGS[@]}" -gt 0 ]]; then
  if have yay; then
    log "installing AUR packages (yay)…"
    yay -S --needed --noconfirm "${AUR_PKGS[@]}" || log "AUR install failed — continuing"
  elif have paru; then
    log "installing AUR packages (paru)…"
    paru -S --needed --noconfirm "${AUR_PKGS[@]}" || log "AUR install failed — continuing"
  else
    log "no yay/paru — install from AUR yourself: ${AUR_PKGS[*]}"
  fi
fi

# --- copy --------------------------------------------------------------------
log "copying configs…"
mkdir -p "$DEST_HOME/.config/quickshell" "$DEST_HOME/.config" "$DEST_HOME/.local/bin" "$DEST_HOME/WALLPAPERS"
cp -r "$SRC/config/quickshell/mybar" "$DEST_HOME/.config/quickshell/mybar"
# drop personal state so the shell boots with factory defaults
rm -f "$DEST_HOME/.config/quickshell/mybar"/{dock,widgets,fonts}.json
cp -r "$SRC/config/hypr" "$DEST_HOME/.config/hypr"
for f in sysstat shot wp wallborders lockart locktrack rec; do
  [[ -f "$SRC/local/bin/$f" ]] && cp "$SRC/local/bin/$f" "$DEST_HOME/.local/bin/$f"
done
chmod +x "$DEST_HOME/.local/bin"/{sysstat,shot,wp,wallborders,lockart,locktrack,rec} 2>/dev/null || true
if ls "$SRC/wallpapers" >/dev/null 2>&1; then
  log "copying wallpapers…"
  cp -n "$SRC"/wallpapers/* "$DEST_HOME/WALLPAPERS/" 2>/dev/null || true
fi

# --- rewrite previous owner's home path --------------------------------------
log "rewriting home paths to $DEST_HOME…"
grep -rl "/home/octal" "$DEST_HOME/.config/quickshell/mybar" \
  "$DEST_HOME/.config/hypr" 2>/dev/null | while read -r f; do
  sed -i "s|/home/octal|$DEST_HOME|g" "$f"
done
grep -rl "/home/octal" "$DEST_HOME/.local/bin"/{sysstat,shot,wp,wallborders,lockart,locktrack,rec} 2>/dev/null | while read -r f; do
  sed -i "s|/home/octal|$DEST_HOME|g" "$f"
done || true

log "done. Next steps:"
echo "  1. If your monitor is not named HDMI-A-1, fix it in: ~/.local/bin/wp (mpvpaper line) and ~/.local/bin/rec"
echo "  2. hyprctl reload"
echo "  3. quickshell -p ~/.config/quickshell/mybar/shell.qml"
echo "  4. Super+D → Dock / Widgets to restyle; re-pin your apps in the Dock page."
