#!/usr/bin/env bash
# 30-cli-tools.sh — tools that need a post-install step beyond a package:
# tmux plugin manager, neovim provider deps, aerc, jira-cli.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

# --- tmux plugin manager (TPM) ----------------------------------------------
TPM="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM" ]]; then
  log "Installing tmux plugin manager (tpm)"
  run git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM"
else
  info "tpm already present"
fi

# --- aerc (terminal mail) ----------------------------------------------------
apt_install aerc || warn "aerc not available via apt on this release (optional)."

# --- jira-cli ----------------------------------------------------------------
if ! have jira; then
  log "Installing jira-cli"
  JIRA_VER="1.6.0"
  ARCH="$(dpkg --print-architecture)"
  case "$ARCH" in amd64) JA="x86_64" ;; arm64) JA="arm64" ;; *) JA="$ARCH" ;; esac
  tmp="$(mktemp -d)"
  if run bash -c "curl -fsSL 'https://github.com/ankitpokhrel/jira-cli/releases/download/v${JIRA_VER}/jira_${JIRA_VER}_linux_${JA}.tar.gz' -o '$tmp/jira.tar.gz'"; then
    run tar -xzf "$tmp/jira.tar.gz" -C "$tmp"
    bin="$(find "$tmp" -type f -name jira | head -n1)"
    [[ -n "$bin" ]] && run install -m 0755 "$bin" "$HOME/.local/bin/jira"
  else
    warn "jira-cli download failed; install manually later."
  fi
  rm -rf "$tmp"
fi

# --- neovim health deps (optional but nice for LazyVim) ----------------------
apt_install python3-pynvim luarocks || true

ok "cli tools configured"
