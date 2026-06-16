# jira-cli aliases — workflow TW
# Sourced from ~/.zshrc

# Cache user email at shell startup (évite jira me à chaque appel).
# Set JIRA_USER in ~/.zsh/secrets.zsh (not committed). Placeholder fallback below.
export JIRA_USER="${JIRA_USER:-you@example.com}"

# Statuts du workflow TW (ordre = pipeline)
_JIRA_STATUSES=(
  "A ATTRIBUER"
  "Selected for Development"
  "En cours - dev actif"
  "Review en attente"
  "WAITING - A déployer"
  "Preprod - produit"
  "MEP"
  "Abandonné"
)

# jm : MES tickets en cours de dev (défaut)
jm() {
  jira issue list -a"$JIRA_USER" -s"En cours - dev actif" "$@"
}

# jt : MES tickets pas encore commencés (To Do + à attribuer)
jt() {
  jira issue list -a"$JIRA_USER" -s"Selected for Development" -s"A ATTRIBUER" "$@"
}

# jml [query] : MES tickets, status sélectionné via fzf
# - jml         → menu fzf complet
# - jml dev     → fzf préfiltré sur "dev" (Enter pour valider)
jml() {
  local jstatus
  jstatus=$(printf '%s\n' "${_JIRA_STATUSES[@]}" \
    | fzf --prompt="Status > " --height=40% --reverse --query="${1:-}" --select-1)
  [[ -z "$jstatus" ]] && return 1
  jira issue list -a"$JIRA_USER" -s"$jstatus"
}

# jms : MES tickets dans le sprint courant
jms() {
  jira sprint list --current -a"$JIRA_USER"
}

# jv KEY : view un ticket en terminal
jv() {
  jira issue view "$1"
}

# jo KEY : ouvre un ticket dans le navigateur
jo() {
  jira open "$1"
}

# jmv KEY [status] : move ticket (interactif si pas de status, fzf préfiltré sinon)
jmv() {
  local key="$1"
  [[ -z "$key" ]] && { echo "Usage: jmv KEY [status]"; return 1; }
  if [[ -n "$2" ]]; then
    local jstatus
    jstatus=$(printf '%s\n' "${_JIRA_STATUSES[@]}" \
      | fzf --prompt="Move to > " --height=40% --reverse --query="$2" --select-1)
    [[ -z "$jstatus" ]] && return 1
    jira issue move "$key" "$jstatus"
  else
    jira issue move "$key"
  fi
}

# jc KEY [message] : ajoute un commentaire (interactif si pas de message)
jc() {
  local key="$1"
  [[ -z "$key" ]] && { echo "Usage: jc KEY [message]"; return 1; }
  shift
  if [[ $# -gt 0 ]]; then
    jira issue comment add "$key" "$*"
  else
    jira issue comment add "$key"
  fi
}

# ja KEY : self-assign un ticket
ja() {
  [[ -z "$1" ]] && { echo "Usage: ja KEY"; return 1; }
  jira issue assign "$1" "$JIRA_USER"
}
