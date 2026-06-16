# 00-os.zsh — portability shim. Defines clipboard/open/notify in OS-agnostic
# terms so the rest of the config (and tmux/aerc) works on Linux and macOS.
# Loaded first (numbered 00) so later files can rely on these.

case "$OSTYPE" in
  linux*)
    # Prefer Wayland; fall back to X11; last resort: no-op with a warning.
    if command -v wl-copy >/dev/null; then
      _clip_copy()  { wl-copy; }
      _clip_paste() { wl-paste; }
    elif command -v xclip >/dev/null; then
      _clip_copy()  { xclip -selection clipboard; }
      _clip_paste() { xclip -selection clipboard -o; }
    elif command -v clip.exe >/dev/null; then            # WSL
      _clip_copy()  { clip.exe; }
      _clip_paste() { powershell.exe -NoProfile -Command Get-Clipboard 2>/dev/null | sed 's/\r$//'; }
    else
      _clip_copy()  { cat >/dev/null; print -u2 "clip: install wl-clipboard or xclip"; }
      _clip_paste() { print -u2 "unclip: install wl-clipboard or xclip"; }
    fi
    _open() { xdg-open "$@" >/dev/null 2>&1 & }
    _notify() { command -v notify-send >/dev/null && notify-send "Terminal" "${1:-Job finished}"; }
    ;;
  darwin*)
    _clip_copy()  { pbcopy; }
    _clip_paste() { pbpaste; }
    _open() { open "$@"; }
    _notify() { osascript -e "display notification \"${1:-Job finished}\" with title \"Terminal\""; }
    ;;
esac

# Public aliases/functions built on the shim.
alias oo='_open .'
notify() { _notify "$@"; }
