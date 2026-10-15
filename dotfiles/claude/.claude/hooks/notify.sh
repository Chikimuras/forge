#!/bin/bash
# Hook Notification : notif desktop (dunst) avec projet + tmux ; action "Aller" = retour sur le bon pane.
input=$(cat)
~/.claude/hooks/is-watched.sh && exit 0   # tu regardes déjà ce pane : pas de notif
command -v notify-send >/dev/null || exit 0
msg=$(jq -r '.message // "Claude attend ton input"' <<<"$input")
proj=$(basename "$(jq -r '.cwd // empty' <<<"$input")")
title="Claude · ${proj:-?}"
if [ -z "$TMUX_PANE" ]; then notify-send -a Claude "$title" "$msg"; exit 0; fi
where=$(tmux display -p -t "$TMUX_PANE" '#S:#I #W')
# --wait bloque jusqu'au clic : on détache pour ne pas bloquer Claude.
(
  [ "$(notify-send -a Claude -A jump=Aller --wait "$title" "$msg"$'\n'"tmux $where")" = jump ] || exit 0
  tmux switch-client -t "$TMUX_PANE"; tmux select-window -t "$TMUX_PANE"; tmux select-pane -t "$TMUX_PANE"
  [ -n "${SWAYSOCK:-}" ] && swaymsg '[app_id="kitty"] focus'
) >/dev/null 2>&1 &
exit 0
