#!/usr/bin/env bash
# 90-security.sh — run the hardening suite. Thin wrapper over security/harden.sh
# so the phase can be skipped independently via bootstrap.sh --no-security.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

exec bash "$FORGE_DIR/security/harden.sh"
