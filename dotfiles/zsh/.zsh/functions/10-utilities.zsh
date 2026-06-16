# 10-utilities.zsh — custom helpers (portable). clipboard/ports adapted to Linux.

# mkcd: create a directory and cd into it
mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }

# take: mkcd + git init + README + first commit
take() {
  mkcd "$1" || return
  git init -q
  echo "# $1" > README.md
  git add README.md >/dev/null 2>&1
  git commit -m "chore: init" >/dev/null 2>&1
}

# extract: extract almost any archive
extract() {
  local file="$1"
  [ -f "$file" ] || { echo "File not found: $file" >&2; return 1; }
  case "$file" in
    *.tar.bz2) tar xjf "$file" ;;
    *.tar.gz)  tar xzf "$file" ;;
    *.tar.xz)  tar xJf "$file" ;;
    *.bz2)     bunzip2 "$file" ;;
    *.rar)     unrar x "$file" ;;
    *.gz)      gunzip "$file" ;;
    *.tar)     tar xf "$file" ;;
    *.tbz2)    tar xjf "$file" ;;
    *.tgz)     tar xzf "$file" ;;
    *.zip)     unzip "$file" ;;
    *.Z)       uncompress "$file" ;;
    *.7z)      7z x "$file" ;;
    *)         echo "Don't know how to extract '$file'" ;;
  esac
}

# swap: quick file swap
swap() {
  local A="$1" B="$2" TMP
  TMP=$(mktemp)
  mv "$A" "$TMP" && mv "$B" "$A" && mv "$TMP" "$B"
}

# tmpfile: create a temp file with optional extension and open it
tmpfile() {
  local ext="${1:-}"
  local f; f="$(mktemp "/tmp/tmp.XXXXXXXXXX${ext}")"
  echo "$f"
  ${EDITOR:-vi} "$f"
}

# bk: timestamped backup (keeps file attributes)
bk() {
  local f="$1"
  [ -e "$f" ] || { echo "Not found: $f" >&2; return 1; }
  cp -a "$f" "${f}.$(date +%Y%m%d-%H%M%S).bak"
}

# path-append: add a folder to PATH if it exists and not already there
path-append() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

# ports: list listening ports (Linux: ss)
ports() {
  # Usage: ports | rg 3000
  sudo ss -tulpnH 2>/dev/null || ss -tulpn
}

# myip: public IP
myip() { curl -s https://ifconfig.me; echo; }

# jsonpp: pretty-print JSON
jsonpp() { jq .; }

# clip / unclip: clipboard via the 00-os.zsh shim (wl-copy/xclip/pbcopy)
clip() {
  if [ $# -eq 0 ]; then _clip_copy; else cat "$@" | _clip_copy; fi
}
unclip() { _clip_paste; }
