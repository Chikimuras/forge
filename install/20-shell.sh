#!/usr/bin/env bash
# 20-shell.sh — zsh + oh-my-zsh + plugins, set zsh as the default shell.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

require_cmd zsh "run 10-packages.sh first."

# --- oh-my-zsh (unattended) --------------------------------------------------
OMZ="$HOME/.oh-my-zsh"
if [[ ! -d "$OMZ" ]]; then
  log "Installing oh-my-zsh"
  run bash -c 'RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
else
  info "oh-my-zsh already present"
fi

# --- External plugins (not bundled with omz) ---------------------------------
ZCUSTOM="${ZSH_CUSTOM:-$OMZ/custom}"
clone_plugin() {
  local repo="$1" dest="$2"
  if [[ -d "$dest" ]]; then
    info "plugin present: $(basename "$dest")"
  else
    log "Cloning plugin $(basename "$dest")"
    run git clone --depth=1 "$repo" "$dest"
  fi
}
clone_plugin https://github.com/zsh-users/zsh-autosuggestions \
  "$ZCUSTOM/plugins/zsh-autosuggestions"
clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZCUSTOM/plugins/zsh-syntax-highlighting"

# --- Default shell -----------------------------------------------------------
zsh_path="$(command -v zsh)"
if [[ "${SHELL:-}" != "$zsh_path" ]]; then
  if confirm "Set zsh as your default login shell?"; then
    run sudo chsh -s "$zsh_path" "$USER" || warn "chsh failed; set it manually with: chsh -s $zsh_path"
  fi
fi

ok "shell configured"
