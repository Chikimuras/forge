#!/usr/bin/env bash
# harden.sh — orchestrates the full hardening suite. Each sub-script is
# idempotent and prints what it changes.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

SEC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

section "Security hardening"
warn "This changes SSH, firewall and kernel settings. Review the scripts first."
if ! confirm "Proceed with full hardening?"; then
  warn "hardening skipped by user."
  exit 0
fi

bash "$SEC_DIR/ssh.sh"
bash "$SEC_DIR/firewall.sh"
bash "$SEC_DIR/fail2ban.sh"
bash "$SEC_DIR/unattended-upgrades.sh"
bash "$SEC_DIR/sysctl.sh"
bash "$SEC_DIR/apparmor.sh"
bash "$SEC_DIR/audit.sh"

ok "hardening complete — review 'sudo lynis audit system' output above."
