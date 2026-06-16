# 20-fzf-widgets.zsh — fzf-powered file/dir/branch pickers (portable).
# macOS Spotlight (mdfind) widgets are reimplemented with plocate/fd on Linux.

# fzf file opener with preview, opens in nvim
ffp() {
  # ffp            -> fuzzy file from current dir
  # ffp ~          -> fuzzy file under $HOME
  # ffp ~/Documents-> fuzzy file under a specific dir
  local search_dir="${1:-.}"
  local file
  file="$(fd --type f --hidden --exclude .git . "$search_dir" \
          | fzf --preview 'bat --style=numbers --color=always --line-range=:300 {}' \
                --bind 'ctrl-/:change-preview-window(down|hidden|)' )" || return
  [ -n "$file" ] && nvim "$file"
}

# floc: fuzzy-find a file anywhere on the machine (indexed via plocate, fast).
# Replaces macOS `fmac`. Falls back to fd over $HOME if plocate is absent.
floc() {
  local query="${1:-}"
  local file
  if command -v plocate >/dev/null || command -v locate >/dev/null; then
    file=$( { command -v plocate >/dev/null && plocate "${query:-/}" || locate "${query:-/}"; } 2>/dev/null \
          | fzf --query="$query" \
                --preview 'bat --color=always --line-range=:300 {} 2>/dev/null || file {}' \
                --bind 'ctrl-/:change-preview-window(down|hidden|)') || return
  else
    file=$(fd --type f --hidden --exclude .git . "$HOME" \
          | fzf --query="$query" --preview 'bat --color=always --line-range=:300 {}') || return
  fi
  [ -n "$file" ] && nvim "$file"
}
alias fmac=floc   # muscle-memory alias from the macOS setup

# fzf cd into directories
cdf() {
  # cdf            -> fuzzy cd from current dir
  # cdf ~          -> fuzzy cd anywhere under $HOME
  local search_dir="${1:-.}"
  local dir
  dir="$(fd . --type d --hidden --exclude .git "$search_dir" | fzf)" || return
  cd "$dir" || return
}

# cdloc: fuzzy cd anywhere on the machine via the locate index. Replaces `cdmac`.
cdloc() {
  local query="${1:-}"
  local dir
  if command -v plocate >/dev/null || command -v locate >/dev/null; then
    dir=$( { command -v plocate >/dev/null && plocate "${query:-/}" || locate "${query:-/}"; } 2>/dev/null \
         | while IFS= read -r p; do [ -d "$p" ] && echo "$p"; done | fzf --query="$query") || return
  else
    dir=$(fd . --type d --hidden --exclude .git "$HOME" | fzf --query="$query") || return
  fi
  cd "$dir" || return
}
alias cdmac=cdloc

# ripgrep + fzf to open at line
rgf() {
  local q="${1:-}"
  local sel file line
  sel=$(
    rg --line-number --no-heading --color=never --smart-case -- "$q" \
    | fzf --delimiter ':' \
          --preview 'bat --color=always --style=numbers --line-range {2}: {1}'
  ) || return
  IFS=':' read -r file line _ <<<"$sel"
  [ -n "$file" ] && [ -n "$line" ] || return 1
  nvim "+${line}" "$file"
}

# git branch switcher (fuzzy, incl. remotes)
gbswitch() {
  local sel branch
  sel="$(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes \
      | grep -v '/HEAD$' \
      | sort -u | fzf)" || return
  if git show-ref --verify --quiet "refs/remotes/$sel"; then
    branch="${sel#*/}"
  else
    branch="$sel"
  fi
  git switch "$branch"
}

# prefix history search on Ctrl-P / Ctrl-N
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^P' up-line-or-beginning-search
bindkey '^N' down-line-or-beginning-search

setopt extendedglob
