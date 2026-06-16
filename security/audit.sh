#!/usr/bin/env bash
# audit.sh — run a Lynis security audit and surface the hardening index.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

section "Security audit (lynis)"
apt_install lynis

# Quiet, non-interactive audit; print the resulting hardening index.
run sudo lynis audit system --quick --no-colors 2>/dev/null | \
  grep -E 'Hardening index|Tests performed|Warnings|Suggestions' || true

info "Full report: /var/log/lynis.log  |  re-run anytime: sudo lynis audit system"
ok "audit complete"
