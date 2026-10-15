#!/bin/bash
# Pose l'état Claude (run|wait|done) sur la fenêtre tmux du pane ; sans argument = efface.
# "done" sous tes yeux = rien à signaler, donc on efface (le vert veut dire "fini, pas encore vu").
[ -n "$TMUX_PANE" ] || exit 0
[ "$1" = "done" ] && ~/.claude/hooks/is-watched.sh && set --
if [ -n "$1" ]; then tmux set -w -t "$TMUX_PANE" @claude "$1"; else tmux set -wu -t "$TMUX_PANE" @claude; fi
tmux refresh-client -S 2>/dev/null
exit 0
