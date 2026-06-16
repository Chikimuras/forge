#!/usr/bin/env bash
# 40-desktop.sh — Wayland tiling stack: sway + waybar + dunst + wl-clipboard,
# kitty terminal, Nerd Fonts. Mirrors the macOS aerospace/sketchybar setup.
# Guarded by bootstrap.sh (only runs when a GUI session is present).
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

log "Installing Wayland tiling stack"
apt_install \
  sway swaybg swayidle swaylock waybar \
  dunst wl-clipboard grim slurp \
  kitty \
  fonts-font-awesome \
  brightnessctl playerctl pavucontrol \
  wofi xdg-desktop-portal-wlr

# --- JetBrains Mono Nerd Font (for waybar/kitty glyphs) ----------------------
FONT_DIR="$HOME/.local/share/fonts"
if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
  log "Installing JetBrainsMono Nerd Font"
  mkdir -p "$FONT_DIR"
  tmp="$(mktemp -d)"
  if run bash -c "curl -fsSL 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip' -o '$tmp/jbm.zip'"; then
    run unzip -oq "$tmp/jbm.zip" -d "$FONT_DIR/JetBrainsMono"
    run fc-cache -f >/dev/null
  else
    warn "Nerd Font download failed; glyphs may be missing in waybar/kitty."
  fi
  rm -rf "$tmp"
fi

ok "desktop stack installed (log into a 'Sway' session from your display manager)"
