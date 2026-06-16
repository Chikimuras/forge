# Passive git-repo visit tracker — feeds /eod end-of-day recap.
# Logs the toplevel of any git repo entered (via cd/zoxide/shell start) into
# ~/.eod/visited-YYYY-MM-DD.txt for later aggregation by ~/.eod/collect.sh.

_eod_log_repo() {
  emulate -L zsh
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  local logdir="$HOME/.eod"
  [[ -d "$logdir" ]] || mkdir -p "$logdir"
  local logfile="$logdir/visited-$(date +%F).txt"
  if [[ ! -f "$logfile" ]] || [[ "$(tail -n 1 "$logfile" 2>/dev/null)" != "$root" ]]; then
    print -r -- "$root" >> "$logfile"
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _eod_log_repo
_eod_log_repo
