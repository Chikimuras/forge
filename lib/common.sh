#!/usr/bin/env bash
# lib/common.sh — shared helpers for forge install scripts.
# Sourced by bootstrap.sh and every install/security script.
# All functions are idempotent-friendly and safe to re-run.

# --- Logging -----------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_RED=$'\033[31m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""
fi

log()   { printf '%s\n' "${C_BLUE}::${C_RESET} $*"; }
info()  { printf '%s\n' "   $*"; }
ok()    { printf '%s\n' "${C_GREEN}✔${C_RESET} $*"; }
warn()  { printf '%s\n' "${C_YELLOW}⚠${C_RESET}  $*" >&2; }
err()   { printf '%s\n' "${C_RED}✖${C_RESET} $*" >&2; }
die()   { err "$*"; exit 1; }
section() { printf '\n%s\n' "${C_BOLD}${C_BLUE}━━ $* ━━${C_RESET}"; }

# --- Dry-run aware runner ----------------------------------------------------
# Usage: run sudo apt-get install -y foo
# Honours FORGE_DRY_RUN=1 (set by --dry-run) by printing instead of executing.
run() {
  if [[ "${FORGE_DRY_RUN:-0}" == "1" ]]; then
    printf '%s\n' "${C_YELLOW}[dry-run]${C_RESET} $*"
    return 0
  fi
  "$@"
}

# --- Confirmation ------------------------------------------------------------
# Returns 0 if user agrees. Auto-yes when FORGE_ASSUME_YES=1 (--yes).
confirm() {
  local prompt="${1:-Continue?}"
  if [[ "${FORGE_ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi
  local reply
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# --- OS detection ------------------------------------------------------------
is_ubuntu() {
  [[ -r /etc/os-release ]] || return 1
  grep -qiE '^ID=ubuntu' /etc/os-release
}

ubuntu_codename() {
  [[ -r /etc/os-release ]] || { echo "unknown"; return 1; }
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "${VERSION_CODENAME:-unknown}"
}

# True when a graphical session is available (used to guard desktop install).
has_gui() {
  [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" || -n "${XDG_SESSION_TYPE:-}" ]] \
    || systemctl list-units --type=target 2>/dev/null | grep -q graphical.target
}

# --- Package / binary helpers ------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

# Install apt packages, skipping any already present (idempotent + quiet).
apt_install() {
  local to_install=()
  local pkg
  for pkg in "$@"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      continue
    fi
    to_install+=("$pkg")
  done
  if [[ ${#to_install[@]} -eq 0 ]]; then
    info "apt: already installed: $*"
    return 0
  fi
  log "apt install: ${to_install[*]}"
  run sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${to_install[@]}"
}

# --- File helpers ------------------------------------------------------------
# Timestamped backup of a path if it exists and is not already a symlink we own.
backup_path() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  local backup="${target}.forge-backup.${stamp}"
  warn "backing up existing $target → $backup"
  run mv "$target" "$backup"
}

# Write a root-owned config file from stdin (idempotent: only if changed).
# Usage: write_root_file /etc/foo/bar.conf <<'EOF' ... EOF
write_root_file() {
  local dest="$1"
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  if [[ -f "$dest" ]] && cmp -s "$tmp" "$dest"; then
    info "unchanged: $dest"
    rm -f "$tmp"
    return 0
  fi
  log "writing $dest"
  run sudo install -D -m 0644 "$tmp" "$dest"
  rm -f "$tmp"
}

# Resolve the repo root regardless of where a script is sourced from.
forge_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}
