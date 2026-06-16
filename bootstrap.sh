#!/usr/bin/env bash
# bootstrap.sh — entrypoint. Provisions a fresh Ubuntu 24.04 desktop into
# Alexandre's workstation: CLI layer, dotfiles, Wayland tiling stack, hardening.
#
# Usage:
#   ./bootstrap.sh                 # full run (interactive prompts)
#   ./bootstrap.sh --yes           # non-interactive (assume yes)
#   ./bootstrap.sh --no-security   # skip the hardening phase
#   ./bootstrap.sh --no-desktop    # skip the GUI/Wayland phase (servers/WSL)
#   ./bootstrap.sh --dry-run       # print actions without executing
#   ./bootstrap.sh --only 30       # run a single install step by number
set -euo pipefail

FORGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FORGE_DIR
# shellcheck source=lib/common.sh
source "$FORGE_DIR/lib/common.sh"

# --- Flags -------------------------------------------------------------------
export FORGE_DRY_RUN=0
export FORGE_ASSUME_YES=0
DO_SECURITY=1
DO_DESKTOP=1
ONLY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)     FORGE_DRY_RUN=1 ;;
    --yes|-y)      FORGE_ASSUME_YES=1 ;;
    --no-security) DO_SECURITY=0 ;;
    --no-desktop)  DO_DESKTOP=0 ;;
    --only)        ONLY="${2:-}"; shift ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) die "unknown flag: $1" ;;
  esac
  shift
done

# --- Preconditions -----------------------------------------------------------
section "Forge — bootstrap"
is_ubuntu || die "this script targets Ubuntu (see /etc/os-release)."
[[ "$(id -u)" -ne 0 ]] || die "run as your normal user, not root (sudo is invoked where needed)."
have sudo || die "sudo is required."

info "Ubuntu codename: $(ubuntu_codename)"
info "GUI session:    $(has_gui && echo yes || echo no)"
[[ "$FORGE_DRY_RUN" == "1" ]] && warn "DRY-RUN: no changes will be made."

# Auto-skip desktop on headless boxes unless GUI explicitly available.
if [[ "$DO_DESKTOP" == "1" ]] && ! has_gui; then
  warn "no graphical session detected — skipping desktop phase (use --no-desktop to silence)."
  DO_DESKTOP=0
fi

# --- Step runner -------------------------------------------------------------
run_step() {
  local script="$1"
  local name
  name="$(basename "$script")"
  if [[ -n "$ONLY" && "$name" != "$ONLY"* ]]; then
    return 0
  fi
  section "step: $name"
  # shellcheck source=/dev/null
  bash "$script"
}

run_step "$FORGE_DIR/install/00-preflight.sh"
run_step "$FORGE_DIR/install/10-packages.sh"
run_step "$FORGE_DIR/install/20-shell.sh"
run_step "$FORGE_DIR/install/30-cli-tools.sh"
[[ "$DO_DESKTOP"  == "1" ]] && run_step "$FORGE_DIR/install/40-desktop.sh"
run_step "$FORGE_DIR/install/50-stow.sh"
[[ "$DO_SECURITY" == "1" ]] && run_step "$FORGE_DIR/install/90-security.sh"

section "done"
ok "Forge bootstrap complete."
cat <<'EOF'

Next steps:
  1. Copy your secrets:   cp ~/.zsh/secrets.zsh.example ~/.zsh/secrets.zsh  (then fill it)
  2. Restart your shell:  exec zsh
  3. tmux plugins:        tmux then prefix + I  (Ctrl-Space, then I)
  4. Review hardening:    sudo lynis audit system   (re-read security/ before exposing SSH)
EOF
