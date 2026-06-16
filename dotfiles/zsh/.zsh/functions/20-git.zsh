# git-default-branch: detect the repo's main branch (main / master / develop / ...)
# Strategy:
#   1. Use origin/HEAD if configured (most reliable, set by `git remote set-head origin --auto`)
#   2. Fallback: pick the first existing remote branch among main, master, develop
#   3. Fallback: same check on local branches
#   4. Last resort: print "main" and return error
git-default-branch() {
  local ref
  ref=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null)
  if [ -n "$ref" ]; then
    echo "${ref#refs/remotes/origin/}"
    return 0
  fi

  local candidate
  for candidate in main master develop trunk; do
    if git show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
      echo "$candidate"
      return 0
    fi
  done
  for candidate in main master develop trunk; do
    if git show-ref --verify --quiet "refs/heads/$candidate"; then
      echo "$candidate"
      return 0
    fi
  done

  echo "main"
  return 1
}

# git-clean-merged: delete local branches already merged in the default branch
git-clean-merged() {
  # Usage: git-clean-merged [base]   (default: auto-detected main/master)
  local base="${1:-$(git-default-branch)}"
  git fetch -p
  git branch --merged "$base" \
    | grep -vE "^\*|$base" \
    | xargs -r -n 1 git branch -d
}

# git-sync: bring the current branch up to date with its remote tracking branch.
# Defaults to @{upstream} so feature branches stay aligned with their own remote
# (avoids the trap of rebasing on master when the branch tracks itself).
# Pass an explicit base to rebase on origin/<base> (e.g. `git-sync master`).
git-sync() {
  # Usage:
  #   git-sync          # rebase on @{u}; fallback: origin/<default-branch>
  #   git-sync master   # rebase on origin/master explicitly
  local target
  if [[ -n "$1" ]]; then
    target="origin/$1"
  elif git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    target="@{u}"
  else
    target="origin/$(git-default-branch)"
  fi

  # Stash only when the working tree is actually dirty (avoids noisy empty stashes).
  local stashed=0
  if ! git diff --quiet --ignore-submodules HEAD 2>/dev/null \
      || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
    git stash push -u -m "auto-sync $(date +%s)" || return 1
    stashed=1
  fi

  if ! git fetch -p; then
    (( stashed )) && git stash pop
    return 1
  fi

  if ! git rebase "$target"; then
    echo "git-sync: rebase failed — resolve conflicts then 'git rebase --continue'." >&2
    (( stashed )) && echo "git-sync: your work is stashed; run 'git stash pop' after the rebase finishes." >&2
    return 1
  fi

  (( stashed )) && git stash pop
}

# git-merge-base: merge origin/<base> into the current branch (default: auto-detect)
git-merge-base() {
  # Usage: git-merge-base [base]   (default: auto-detected main/master)
  local base="${1:-$(git-default-branch)}"
  echo "Merging origin/$base into $(git rev-parse --abbrev-ref HEAD)..."
  git fetch origin "$base" && git merge "origin/$base"
}

# git-rerun: empty commit + push, to retrigger CI without changing code (universal fallback)
git-rerun() {
  # Usage:
  #   git-rerun                          # default message: "ci: retrigger pipeline"
  #   git-rerun "ci: retry flaky test"   # custom message
  local msg="${1:-ci: retrigger pipeline}"
  git commit --allow-empty -m "$msg" && git push
}

# git-pipeline-run: trigger a fresh CI pipeline on the current branch (via glab, GitLab only)
git-pipeline-run() {
  # Usage: git-pipeline-run [branch]   (default: current branch)
  local branch="${1:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null)}"
  [ -n "$branch" ] || { echo "git-pipeline-run: not in a git repo" >&2; return 1; }

  if ! command -v glab >/dev/null; then
    echo "git-pipeline-run: glab non installé (brew install glab). Utilise 'gci' à la place." >&2
    return 1
  fi

  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null)
  if [[ "$remote_url" == *github.com* ]]; then
    echo "git-pipeline-run: GitHub détecté — glab ne s'applique pas. Utilise 'gci' ou 'gh run rerun'." >&2
    return 1
  fi

  echo "Triggering new pipeline on '$branch'..."
  glab ci run -b "$branch"
}

# git-pipeline-status: show current pipeline status on the current branch
git-pipeline-status() {
  command -v glab >/dev/null || { echo "glab non installé" >&2; return 1; }
  glab ci status
}

# git-fixup: create fixup against last commit touching a path
git-fixup() {
  # Usage: git-fixup path/to/file
  local f="$1"
  [ -n "$f" ] || { echo "usage: git-fixup <file>" >&2; return 1; }
  local target
  target="$(git rev-list -n 1 HEAD -- "$f")"
  git commit -a --fixup "$target"
  echo "Now run: git rebase -i --autosquash origin/$(git-default-branch)"
}
