#!/usr/bin/env bash
# fail2ban.sh — ban hosts after repeated SSH auth failures.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

section "fail2ban"
apt_install fail2ban

write_root_file /etc/fail2ban/jail.d/forge-sshd.local <<'EOF'
# Managed by forge.
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled = true
EOF

run sudo systemctl enable --now fail2ban
run sudo systemctl restart fail2ban
ok "fail2ban active (sshd jail)"
