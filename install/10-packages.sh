#!/usr/bin/env bash
# 10-packages.sh — install all CLI tooling. apt where the version is fine,
# upstream repos / binaries where Ubuntu's is stale or absent.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

ARCH="$(dpkg --print-architecture)"   # amd64 / arm64

# --- 1. Tools available cleanly from the Ubuntu repos ------------------------
log "Core CLI tools from apt"
apt_install \
  zsh tmux neovim ripgrep fd-find bat jq tree htop btop \
  fzf zoxide direnv trash-cli unrar p7zip-full unzip \
  ffmpeg poppler-utils imagemagick \
  fonts-firacode

# Ubuntu ships fd as `fdfind` and bat as `batcat`; expose the canonical names.
mkdir -p "$HOME/.local/bin"
[[ -e /usr/bin/fdfind ]] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
[[ -e /usr/bin/batcat ]] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"

# --- 2. eza (modern ls) — official keyring repo ------------------------------
if ! have eza; then
  log "Installing eza (gierens repo)"
  run sudo mkdir -p /etc/apt/keyrings
  run bash -c 'wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | gpg --dearmor | sudo tee /etc/apt/keyrings/gierens.gpg >/dev/null'
  run bash -c 'echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null'
  run sudo apt-get update -y
  apt_install eza
fi

# --- 3. GitHub CLI -----------------------------------------------------------
if ! have gh; then
  log "Installing GitHub CLI"
  run bash -c 'wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null'
  run sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  run bash -c "echo \"deb [arch=$ARCH signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null"
  run sudo apt-get update -y
  apt_install gh
fi

# --- 4. GitLab CLI (glab) — release binary -----------------------------------
if ! have glab; then
  log "Installing glab (GitLab CLI)"
  GLAB_VER="1.50.0"
  case "$ARCH" in
    amd64) GLAB_ARCH="x86_64" ;;
    arm64) GLAB_ARCH="arm64" ;;
    *) GLAB_ARCH="$ARCH" ;;
  esac
  tmp="$(mktemp -d)"
  run bash -c "curl -fsSL 'https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VER}/downloads/glab_${GLAB_VER}_linux_${GLAB_ARCH}.tar.gz' -o '$tmp/glab.tar.gz'"
  run tar -xzf "$tmp/glab.tar.gz" -C "$tmp"
  run install -m 0755 "$tmp/bin/glab" "$HOME/.local/bin/glab"
  rm -rf "$tmp"
fi

# --- 5. lazygit — release binary ---------------------------------------------
if ! have lazygit; then
  log "Installing lazygit"
  LG_VER="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep -Po '"tag_name": *"v\K[^"]*' || echo '0.44.1')"
  case "$ARCH" in amd64) LG_ARCH="x86_64" ;; arm64) LG_ARCH="arm64" ;; *) LG_ARCH="$ARCH" ;; esac
  tmp="$(mktemp -d)"
  run bash -c "curl -fsSL 'https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_${LG_ARCH}.tar.gz' -o '$tmp/lg.tar.gz'"
  run tar -xzf "$tmp/lg.tar.gz" -C "$tmp" lazygit
  run install -m 0755 "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  rm -rf "$tmp"
fi

# --- 6. Starship prompt ------------------------------------------------------
if ! have starship; then
  log "Installing starship"
  run bash -c 'curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"'
fi

# --- 7. mise (runtime version manager) ---------------------------------------
if ! have mise; then
  log "Installing mise"
  run bash -c 'curl -fsSL https://mise.run | sh'
fi

# --- 8. tldr (tealdeer) ------------------------------------------------------
apt_install tealdeer || warn "tealdeer not in repos; skip (optional)"

# --- 9. yazi (TUI file manager) — release binary -----------------------------
# Not packaged for Ubuntu 24.04, so we take the upstream zip. It ships two
# binaries (yazi + ya, the plugin/package manager) nested in a versioned dir.
# The image previews need ffmpeg / poppler / imagemagick from section 1, plus
# `allow-passthrough on` in tmux — see dotfiles/tmux.
if ! have yazi; then
  log "Installing yazi"
  YAZI_VER="$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest \
    | grep -Po '"tag_name": *"v\K[^"]*' || echo '26.9.1')"
  case "$ARCH" in
    amd64) YAZI_ARCH="x86_64" ;;
    arm64) YAZI_ARCH="aarch64" ;;
    *) YAZI_ARCH="$ARCH" ;;
  esac
  tmp="$(mktemp -d)"
  if run bash -c "curl -fsSL 'https://github.com/sxyazi/yazi/releases/download/v${YAZI_VER}/yazi-${YAZI_ARCH}-unknown-linux-gnu.zip' -o '$tmp/yazi.zip'"; then
    run unzip -q "$tmp/yazi.zip" -d "$tmp"
    for b in yazi ya; do
      bin="$(find "$tmp" -type f -name "$b" | head -n1)"
      if [[ -n "$bin" ]]; then
        run install -m 0755 "$bin" "$HOME/.local/bin/$b"
      elif [[ "${FORGE_DRY_RUN:-0}" != "1" ]]; then
        # Under --dry-run nothing was downloaded or unzipped, so an empty find
        # is expected and warning about it would be a false alarm.
        warn "yazi archive did not contain '$b'; check the upstream layout."
      fi
    done
  else
    warn "yazi download failed; install manually later."
  fi
  rm -rf "$tmp"
fi

ok "packages installed"
