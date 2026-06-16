# Forge — Design (config Ubuntu desktop, durcie & reproductible)

**Date:** 2026-06-16
**Statut:** approuvé (décisions verrouillées via brainstorming)

## Objectif

Un repo GitHub public-safe qui transforme une **Ubuntu 24.04 LTS desktop** fraîche en
la workstation complète d'Alexandre via **une seule commande idempotente**. Il porte
sa couche CLI macOS actuelle vers Linux, ajoute un durcissement sécurité complet, et
traduit sa stack tiling macOS (aerospace/sketchybar) vers des équivalents Wayland (sway/waybar).

## Décisions (brainstorming)

| Axe | Choix |
|-----|-------|
| Cible | Ubuntu 24.04 LTS desktop (workstation) |
| Provisioning | Script bootstrap idempotent + symlinks via GNU stow |
| Sécurité | Hardening complet (SSH, ufw, fail2ban, unattended-upgrades, sysctl, lynis, AppArmor) |
| Couche GUI | Port vers Wayland : sway + waybar + dunst + wl-clipboard |
| Prompt | Starship (oh-my-zsh conservé pour ses plugins) |
| Secrets | Hors repo : templates `.example` + `.gitignore` |
| Nom | `forge` |

## Architecture

```
forge/
├── bootstrap.sh              # orchestrateur idempotent (--no-security, --no-desktop, --dry-run, --yes)
├── lib/common.sh             # logging, detect OS, helpers idempotents, backup, confirm
├── install/
│   ├── 00-preflight.sh       # vérifie Ubuntu, sudo, apt update, détecte session GUI
│   ├── 10-packages.sh        # apt + dépôts externes (eza, gh, glab, lazygit, mise, starship)
│   ├── 20-shell.sh           # zsh + oh-my-zsh + plugins + chsh
│   ├── 30-cli-tools.sh       # fzf, tmux/tpm, neovim, aerc, jira-cli, etc.
│   ├── 40-desktop.sh         # [guardé] sway, waybar, dunst, wl-clipboard, kitty, fonts
│   ├── 50-stow.sh            # symlink des dotfiles (backup auto de l'existant)
│   └── 90-security.sh        # → security/harden.sh
├── security/                 # ssh.sh, firewall.sh, fail2ban.sh, unattended-upgrades.sh, sysctl.sh, audit.sh
├── dotfiles/                 # paquets stow (1 dossier = 1 paquet)
└── .github/workflows/ci.yml  # shellcheck + smoke test conteneur ubuntu:24.04
```

## Couche zsh portable

Shim `00-os.zsh` qui définit `clip`/`unclip` (wl-copy/xclip), `open` (xdg-open), `notify`
(notify-send), `ports` (ss), selon l'OS. Les alias/fonctions cross-platform (git, fzf,
nav, docker, jira, utilitaires) sont repris à l'identique. Starship remplace robbyrussell.
Les secrets (`JIRA_API_TOKEN`, `DISCORD_WEBHOOK_URL`, `RESCUETIME_API_KEY`) sont sourcés
depuis `~/.zsh/secrets.zsh` (gitignoré), jamais commités.

## Tiling : aerospace → sway, sketchybar → waybar

Reproduit le mapping actuel adapté **AZERTY** : workspaces `Alt+&é"'(...`, focus vim
`Alt+h/j/k/l`, déplacement `Alt+Shift+…`, fullscreen `Alt+f`, reload `Alt+Shift+c`.
waybar reprend l'esprit sketchybar (workspaces + horloge + système + média).

## Hardening

- **SSH** drop-in `99-hardening.conf` : clés only, no root, MaxAuthTries 3, X11Forwarding off,
  ciphers/KEX/MACs modernes. **Garde-fou anti-lockout** : refuse de couper l'auth password
  si aucune clé autorisée n'est présente.
- **ufw** : deny incoming, allow outgoing, SSH rate-limited.
- **fail2ban** : jail sshd.
- **unattended-upgrades** : patches sécurité auto.
- **sysctl** : durcissement réseau/kernel.
- **lynis** : audit + score. **AppArmor** activé.

## Sécurité du repo

Aucun secret commité. `accounts.conf`, tokens → templates `.example`, vrais fichiers
dans `.gitignore`. `secrets/README.md` documente le placement local. CI shellcheck +
smoke test headless en conteneur.

## Garanties

- Idempotent et re-jouable.
- Backup horodaté de tout dotfile existant avant symlink.
- Flags pour skip security/desktop (réutilisable sur un serveur).
- `set -euo pipefail` partout, shellcheck-clean.
