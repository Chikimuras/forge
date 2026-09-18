# y: yazi wrapper that leaves you in the directory you quit from.
# Yazi runs in its own process, so a plain `yazi` call can't change the shell's
# cwd — it dumps the last directory into --cwd-file and we cd there ourselves.
y() {
  # Usage: y [path]
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
  yazi --cwd-file="$tmp" "$@"
  cwd="$(<"$tmp")"
  # `command rm`: bare rm is aliased to trash here, and zsh expands aliases when
  # the function is *defined*, which would litter the trash with every cwd file.
  command rm -f -- "$tmp"
  # Quitting with Q (instead of q) writes nothing, which keeps you put on purpose.
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
}
