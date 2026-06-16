# ~/.zshrc — managed by forge (https://github.com/<you>/forge)
# Ubuntu desktop. Portable layer; macOS-isms live behind the 00-os.zsh shim.

export ZDOTDIR="$HOME"
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less -R"
export LESS="-RFX"
export BAT_THEME="TwoDark"

# fzf defaults (fd is symlinked into ~/.local/bin by forge on Ubuntu)
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_CTRL_T_COMMAND="fd --hidden --follow --exclude .git"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"

# PATH: user-local bins first (forge installs glab/lazygit/jira/starship here)
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# --- oh-my-zsh ---------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""                       # prompt is handled by starship (see end of file)
DEFAULT_USER="$(whoami)"
plugins=(
  git
  fzf
  colored-man-pages
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source "$ZSH/oh-my-zsh.sh"

# --- Tool init ---------------------------------------------------------------
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# --- Split config ------------------------------------------------------------
for f in ~/.zsh/rc.d/*.zsh; do
  [ -r "$f" ] && source "$f"
done
for f in ~/.zsh/functions/*.zsh; do
  [ -r "$f" ] && source "$f"
done

# --- Completions -------------------------------------------------------------
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit

# --- Quick aliases -----------------------------------------------------------
alias h="cd $HOME"
alias c="clear"
alias o="nvim"

# --- jira-cli aliases (workflow TW) ------------------------------------------
[ -f ~/.config/jira-cli/aliases.sh ] && source ~/.config/jira-cli/aliases.sh

# --- mise (runtime versions per project) — keep near the end -----------------
command -v mise >/dev/null && eval "$(mise activate zsh)"

# --- Secrets (NOT in git) ----------------------------------------------------
# Tokens & webhooks live here; create from ~/.zsh/secrets.zsh.example
[ -r ~/.zsh/secrets.zsh ] && source ~/.zsh/secrets.zsh

# --- Prompt: starship (last, so nothing overrides it) ------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"
