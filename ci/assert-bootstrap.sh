#!/usr/bin/env bash
# ci/assert-bootstrap.sh — post-conditions for a REAL bootstrap run.
#
# Run inside the CI container right after:
#   ./bootstrap.sh --yes --no-desktop --no-security
#
# bootstrap.sh only proves it ran without erroring; this proves it *landed*:
# every tool the install steps promise is on PATH, the zsh plugin checkouts
# exist, the dotfiles are live symlinks into the repo (not silently backed up),
# and the resulting .zshrc actually loads.
#
# Deliberately no `set -e`: we want the full list of what's missing in one CI
# run, not just the first failure.
set -uo pipefail

FORGE_DIR="${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$FORGE_DIR/lib/common.sh"

# Same PATH the stowed .zshrc sets up: forge drops binaries in ~/.local/bin.
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

failures=0
fail() { err "$*"; failures=$((failures + 1)); }

check_cmd() {
  if have "$1"; then
    info "cmd   $1 → $(command -v "$1")"
  else
    fail "missing command: $1"
  fi
}

check_dir() {
  if [[ -d "$1" ]]; then
    info "dir   $1"
  else
    fail "missing directory: $1"
  fi
}

# A dotfile must resolve back into the repo. Anything else means stow skipped
# it (conflict) or backed it up, leaving a dead copy: the config is not live.
#
# We test the resolved path, not `-L` on the leaf: stow folds trees, so a whole
# package can be linked at a parent (~/.zsh -> ../forge/dotfiles/zsh/.zsh) and
# the files inside it are then plain files reached through that symlink.
check_link() {
  local target="$1" dest
  if [[ ! -e "$target" ]]; then
    fail "missing (stow did not link it): $target"
    return
  fi
  dest="$(readlink -f "$target")"
  case "$dest" in
    "$FORGE_DIR"/dotfiles/*) info "link  $target → $dest" ;;
    *) fail "$target is not linked into the repo (resolves to: $dest)" ;;
  esac
}

section "assert: commands on PATH"
# Only tools the install steps install unconditionally. Optional ones
# (aerc, tealdeer, jira-cli) are skipped: their absence is tolerated by design.
for cmd in zsh tmux nvim rg fd bat jq tree htop fzf zoxide direnv \
           eza gh glab lazygit starship mise stow git; do
  check_cmd "$cmd"
done

section "assert: shell environment"
check_dir "$HOME/.oh-my-zsh"
check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
check_dir "$HOME/.config/tmux/plugins/tpm"

section "assert: dotfiles are stowed"
check_link "$HOME/.zshrc"
check_link "$HOME/.zsh/rc.d/10-aliases.zsh"
check_link "$HOME/.zsh/functions/20-git.zsh"
check_link "$HOME/.gitconfig"
check_link "$HOME/.config/starship.toml"
check_link "$HOME/.config/tmux/tmux.conf"

section "assert: the zsh config loads"
# -i so oh-my-zsh, the rc.d/ split, compinit, zoxide/direnv/mise/starship hooks
# all get sourced. timeout guards against any prompt sneaking in.
if timeout 60 zsh -i -c 'exit 0' </dev/null; then
  ok "zsh -i starts cleanly"
else
  fail "zsh -i failed to start (exit $?) — see output above"
fi

section "assert: summary"
if (( failures > 0 )); then
  die "$failures assertion(s) failed"
fi
ok "bootstrap post-conditions verified"
