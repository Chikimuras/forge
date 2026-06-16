# forge 🔨

> Turn a fresh **Ubuntu 24.04 desktop** into a hardened, fully-loaded terminal
> workstation with one command. CLI tooling, dotfiles, a Wayland tiling stack,
> and a complete security hardening pass — idempotent and re-runnable.

```bash
git clone https://github.com/<you>/forge.git
cd forge
./bootstrap.sh
```

## What you get

| Layer | Tools |
|-------|-------|
| **Shell** | zsh + oh-my-zsh, **starship** prompt, autosuggestions, syntax-highlighting |
| **CLI** | eza, bat, fd, ripgrep, fzf, zoxide, lazygit, tmux (+tpm), neovim (LazyVim), direnv, mise, gh, glab, jira-cli, aerc |
| **Desktop** | **sway** (Wayland tiling) + **waybar** + **dunst** + wl-clipboard + kitty + Nerd Font |
| **Security** | hardened SSH, ufw, fail2ban, unattended-upgrades, sysctl hardening, AppArmor, Lynis audit |

All of Alexandre's aliases and functions are carried over verbatim where portable;
macOS-only bits (clipboard, `open`, `notify`, Spotlight pickers) are reimplemented
for Linux behind a portability shim (`~/.zsh/rc.d/00-os.zsh`).

## Usage

```bash
./bootstrap.sh                 # full interactive run
./bootstrap.sh --yes           # non-interactive
./bootstrap.sh --no-desktop    # servers / WSL (skip the GUI stack)
./bootstrap.sh --no-security   # skip hardening
./bootstrap.sh --dry-run       # show what would happen, change nothing
./bootstrap.sh --only 30       # run a single numbered step
```

The desktop phase auto-skips on headless machines.

## Layout

```
bootstrap.sh        # orchestrator
lib/common.sh       # logging, OS detection, idempotent helpers, backups
install/            # 00-preflight → 10-packages → 20-shell → 30-cli-tools
                    # → 40-desktop → 50-stow → 90-security
security/           # ssh, firewall, fail2ban, unattended-upgrades, sysctl, apparmor, audit
dotfiles/           # GNU stow packages (one dir per app)
secrets/            # how to place local secrets (none are committed)
docs/               # design spec
```

## Security model

- **No secrets in git.** Tokens and mail credentials stay in git-ignored files;
  templates ship as `*.example`. See [`secrets/README.md`](secrets/README.md).
- **Anti-lockout SSH.** Password auth is only disabled once an authorized key
  is present, and the config is `sshd -t`-validated before any reload.
- **Idempotent.** Every script is safe to re-run; existing dotfiles are backed
  up (timestamped) before symlinking.

## After install

1. `cp ~/.zsh/secrets.zsh.example ~/.zsh/secrets.zsh` and fill it in
2. `exec zsh`
3. In tmux: `prefix + I` (Ctrl-Space, then I) to install plugins
4. Log into a **Sway** session from your display manager
5. `sudo lynis audit system` to review the hardening index

## License

MIT
