#!/bin/bash
# Saute à la prochaine fenêtre Claude rouge (wait), sinon verte (done), en tournant à partir de la fenêtre courante.
# Usage (depuis tmux) : claude-next.sh <client_name> <session:window courant>
client=$1 cur=$2
t=$(tmux list-windows -a -F "#{session_name}:#{window_index}	#{@claude}" | awk -F'\t' -v cur="$cur" '
  { id[NR]=$1; st[NR]=$2; if ($1==cur) c=NR }
  END { n=split("wait done", want, " ")
        for (w=1; w<=n; w++) for (i=1; i<=NR; i++) { j=(c+i-1)%NR+1; if (st[j]==want[w]) { print id[j]; exit } } }')
if [ -n "$t" ]; then tmux switch-client -c "$client" -t "$t"; else tmux display -c "$client" "Aucune session Claude ne t'attend"; fi
