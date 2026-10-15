#!/usr/bin/env bash
# 60-claude.sh — register the Claude Code hooks (stowed in ~/.claude/hooks) in
# ~/.claude/settings.json. That file is owned by Claude Code (permissions, model…),
# so it is merged rather than stowed: each hook is added only if its command is
# not already present, which keeps the step idempotent.
set -euo pipefail
# shellcheck source=../lib/common.sh
source "${FORGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"

require_cmd jq "run 10-packages.sh."

SETTINGS="$HOME/.claude/settings.json"
# shellcheck disable=SC2088  # literal on purpose: expanded later by the shell Claude Code runs hooks with
H='~/.claude/hooks'

if [[ "${FORGE_DRY_RUN:-0}" == "1" ]]; then
  printf '%s\n' "${C_YELLOW}[dry-run]${C_RESET} merge Claude hooks into $SETTINGS"
  exit 0
fi

mkdir -p "$(dirname "$SETTINGS")"
[[ -s "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

# jq fails on invalid JSON before anything is written, so the original stays intact.
jq --arg h "$H" '
  def add(ev; cmd; extra):
    if any(.hooks[ev][]?.hooks[]?; .command == cmd) then .
    else .hooks[ev] += [{hooks: [{type: "command", command: cmd}]} + extra] end;
  add("UserPromptSubmit"; "\($h)/tmux-state.sh run"; {})
  | add("PostToolUse";    "\($h)/tmux-state.sh run"; {})
  | add("Notification";   "\($h)/tmux-state.sh wait"; {matcher: "permission_prompt|elicitation_dialog"})
  | add("Notification";   "\($h)/notify.sh"; {})
  | add("Stop";           "\($h)/tmux-state.sh done"; {})
  | add("SessionEnd";     "\($h)/tmux-state.sh"; {})
' "$SETTINGS" > "$SETTINGS.tmp" || { rm -f "$SETTINGS.tmp"; die "invalid JSON in $SETTINGS, left untouched"; }
mv -f "$SETTINGS.tmp" "$SETTINGS"

ok "Claude hooks registered in $SETTINGS"
