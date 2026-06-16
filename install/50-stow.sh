#!/usr/bin/env bash
# 50-stow.sh — symlink dotfiles into $HOME via GNU stow.
# Existing real files at any target are backed up (timestamped) before linking,
# so the operation is safe and re-runnable.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

require_cmd stow "run 00-preflight.sh."

DOTFILES="$FORGE_DIR/dotfiles"
[[ -d "$DOTFILES" ]] || die "missing $DOTFILES"

# Desktop packages only stow when a GUI is present.
PACKAGES=(zsh starship git tmux kitty aerc jira)
if has_gui; then
  PACKAGES+=(sway waybar dunst)
fi
# nvim package is optional (only if it was vendored into the repo).
[[ -d "$DOTFILES/nvim" ]] && PACKAGES+=(nvim)

# Back up any existing real (non-symlink) target file that stow would clobber.
backup_conflicts() {
  local pkg="$1"
  local pkgdir="$DOTFILES/$pkg"
  local f rel target
  while IFS= read -r -d '' f; do
    rel="${f#"$pkgdir"/}"
    target="$HOME/$rel"
    if [[ -e "$target" && ! -L "$target" ]]; then
      backup_path "$target"
    fi
  done < <(find "$pkgdir" -type f -print0)
}

for pkg in "${PACKAGES[@]}"; do
  [[ -d "$DOTFILES/$pkg" ]] || { warn "package missing, skipping: $pkg"; continue; }
  log "stow: $pkg"
  backup_conflicts "$pkg"
  run stow --dir "$DOTFILES" --target "$HOME" --restow "$pkg"
done

ok "dotfiles linked"
