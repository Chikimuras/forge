#!/usr/bin/env bash
# 00-preflight.sh — sanity checks + base apt refresh and build essentials.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

is_ubuntu || die "not Ubuntu."

log "Refreshing apt and installing base tooling"
run sudo apt-get update -y
apt_install ca-certificates curl wget gnupg lsb-release software-properties-common \
  build-essential git stow unzip

ok "preflight complete"
