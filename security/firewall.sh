#!/usr/bin/env bash
# firewall.sh — ufw: deny incoming, allow outgoing, SSH rate-limited.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

section "Firewall (ufw)"
apt_install ufw

run sudo ufw default deny incoming
run sudo ufw default allow outgoing

# Rate-limit SSH only if an SSH server is present (avoids opening a closed port).
if dpkg -s openssh-server >/dev/null 2>&1; then
  run sudo ufw limit OpenSSH || run sudo ufw limit 22/tcp
  info "SSH allowed (rate-limited)"
fi

# Enable non-interactively (the --force avoids the y/n prompt that breaks scripts).
run bash -c 'yes | sudo ufw --force enable'
run sudo ufw status verbose || true
ok "firewall active"
