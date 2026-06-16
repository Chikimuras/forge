#!/usr/bin/env bash
# ssh.sh — harden the SSH server via a drop-in. Keys-only, no root, modern crypto.
# CRITICAL anti-lockout guard: password auth is only disabled when at least one
# authorized key exists for the current user. Otherwise we keep passwords and warn.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

section "SSH hardening"

# If sshd isn't installed, there's nothing exposed — skip cleanly.
if ! dpkg -s openssh-server >/dev/null 2>&1; then
  info "openssh-server not installed — skipping SSH hardening (no remote surface)."
  exit 0
fi

# --- Anti-lockout: detect an authorized key ----------------------------------
keyfile="$HOME/.ssh/authorized_keys"
has_key=0
if [[ -s "$keyfile" ]] && grep -qE '^(ssh-(ed25519|rsa)|ecdsa-)' "$keyfile"; then
  has_key=1
fi

password_auth="no"
if [[ "$has_key" -eq 0 ]]; then
  warn "No authorized SSH key found in $keyfile."
  warn "Keeping PasswordAuthentication=yes to avoid locking you out."
  warn "Add a key (ssh-copy-id) then re-run, and password auth will be disabled."
  password_auth="yes"
fi

write_root_file /etc/ssh/sshd_config.d/99-forge-hardening.conf <<EOF
# Managed by forge — SSH hardening. Edit security/ssh.sh, not this file.
PermitRootLogin no
PasswordAuthentication ${password_auth}
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
MaxSessions 4
LoginGraceTime 20
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
Protocol 2

# Modern, safe crypto only.
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
EOF

# Validate before reloading so a bad config never bricks the SSH service.
if run sudo sshd -t; then
  if systemctl list-unit-files 2>/dev/null | grep -q '^ssh\.service'; then
    run sudo systemctl reload ssh || run sudo systemctl restart ssh
  fi
  ok "sshd hardened (password auth: ${password_auth})"
else
  err "sshd config test failed — drop-in left in place but service NOT reloaded."
  exit 1
fi
