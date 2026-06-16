#!/usr/bin/env bash
# unattended-upgrades.sh — automatic security updates.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

section "Unattended security upgrades"
apt_install unattended-upgrades apt-listchanges

write_root_file /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

write_root_file /etc/apt/apt.conf.d/52forge-unattended <<'EOF'
// Managed by forge. Security pocket auto-applied; auto-reboot off by default.
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

run sudo systemctl enable --now unattended-upgrades || true
ok "unattended-upgrades enabled (security pocket)"
