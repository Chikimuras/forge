# 10-aliases.zsh — aliases (portable). macOS-only bits moved to 00-os.zsh.

# --- Safer core ---
alias rm="trash-put"                # send to trash (trash-cli) instead of deleting
alias mv="mv -i"                    # prompt before overwrite
alias cp="cp -i"                    # prompt before overwrite

# --- Modern ls/cat ---
alias ls="eza --group-directories-first --icons"
alias ll="eza -lah --git --icons --group-directories-first"
alias la="eza -a --icons"
alias lt="eza -T --level=2 --icons"

alias cat="bat -pp"                 # pretty-print without pager
alias pcat="bat"                    # with pager

# --- Git shortcuts (battle-tested) ---
alias gs="git status -sb"
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gp="git push"
alias gpl="git pull --rebase --autostash"
alias gl="git log --oneline --graph --decorate"
alias gfix="git commit --fixup"
alias grebase="git rebase -i --autosquash"
alias grs="git restore --staged ."
alias gwt="git worktree"
alias gmm="git-merge-base"
alias gci="git-rerun"
alias gpr="git-pipeline-run"
alias gps="git-pipeline-status"

# --- Grep/find modern ---
alias rgp="rg --hidden --glob '!.git' -n"
alias ff="fd --type f"
alias fda="fd --hidden --follow --exclude .git"

# --- Dirs & nav ---
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# --- Docker quickies ---
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcl="docker compose logs -f --tail=200"
alias dcb="docker compose build"

# --- Misc ---
alias lg="lazygit"
alias please='sudo $(fc -ln -1)'    # re-run last command with sudo
alias tldr="tldr --platform linux"
