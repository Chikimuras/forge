#!/usr/bin/env bash
# apparmor.sh — ensure AppArmor is installed and enforcing.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

section "AppArmor"
apt_install apparmor apparmor-utils apparmor-profiles
run sudo systemctl enable --now apparmor || true
if have aa-status; then
  run sudo aa-status --enabled && ok "AppArmor enabled" || warn "AppArmor present but not enabled."
fi
