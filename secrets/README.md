# Secrets — local only, never committed

This repo is **public-safe**: no credentials live in git. Real secrets stay on
your machine in git-ignored files. Templates (`*.example`) ship in the repo.

## What you need to create after `bootstrap.sh`

| Secret file | Created from | Holds |
|-------------|--------------|-------|
| `~/.zsh/secrets.zsh` | `~/.zsh/secrets.zsh.example` | `JIRA_USER`, `JIRA_API_TOKEN`, `RESCUETIME_API_KEY`, `DISCORD_WEBHOOK_URL` |
| `~/.config/aerc/accounts.conf` | `~/.config/aerc/accounts.conf.example` | Proton Bridge IMAP/SMTP credentials |

```bash
cp ~/.zsh/secrets.zsh.example ~/.zsh/secrets.zsh && chmod 600 ~/.zsh/secrets.zsh
cp ~/.config/aerc/accounts.conf.example ~/.config/aerc/accounts.conf && chmod 600 ~/.config/aerc/accounts.conf
$EDITOR ~/.zsh/secrets.zsh
```

## SSH keys

The hardening step disables SSH password auth **only if** an authorized key
exists (`~/.ssh/authorized_keys`). Generate and install a key first:

```bash
ssh-keygen -t ed25519 -C "$(hostname)"
# then copy your public key to any box you connect to:  ssh-copy-id user@host
```

## If you ever leak a secret

The original macOS `.zshrc` had live tokens inline. Those were **not** carried
into this repo. If a token ever lands in git history, rotate it immediately
(Jira: revoke the API token; Discord: delete the webhook) — rotation beats
trying to scrub history.
