#!/bin/bash
# exit 0 si tu regardes ce pane : sa fenêtre est active dans une session attachée ET kitty a le focus sway.
[ -n "$TMUX_PANE" ] || exit 1
[ "$(tmux display -p -t "$TMUX_PANE" '#{&&:#{window_active},#{session_attached}}')" = 1 ] || exit 1
# Hors sway (SSH, TTY) on ne peut pas savoir : la fenêtre tmux active suffit.
[ -n "${SWAYSOCK:-}" ] || exit 0
swaymsg -t get_tree | jq -e '.. | objects | select(.focused == true and .app_id == "kitty")' >/dev/null
