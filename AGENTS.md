# AGENTS.md

This file provides guidance to coding agents working with code in this repository.

## Overview

macOS development environment linked into `$HOME` by [Home Manager](https://github.com/nix-community/home-manager). `flake.nix` and `nix/` declare every link, and `setup-home.sh` builds and activates them. `misc/` is not linked and holds files kept for reference, like the OBS overlays. `skills/` holds agent skills; `GLOBAL_AGENTS.md` is the global agent instructions file, linked to `~/.claude/CLAUDE.md`, while this file covers only this repository.

## Key Commands

```bash
bash setup.sh                    # Full setup (requires sudo)
bash setup-home.sh               # Re-apply all symlinks (dotfiles, agent skills, GLOBAL_AGENTS.md)
bash setup-home.sh -n            # Build, then print what activating would do
bash setup-home.sh -D            # Delete all symlinks
bash tests/setup-home.test.sh    # Activate into throwaway homes and check the links
brew bundle --file brew/Brewfile  # Install a specific Brewfile category
mise install --yes && mise reshim # Install/update language versions
nix flake update prezto          # Move a pinned dependency (prezto, dracula-vim, nixpkgs, home-manager)
bin/secrets-sync                 # Render 00-SECRETS.zsh from 1Password (--check validates only)
```

## Architecture

### Home Manager Links

`nix/links.nix` is the manifest: one `"path in $HOME" = "path in this repository"` line per link. Nothing is linked by convention, so a new file or directory needs its own line there, then `bash setup-home.sh`.

- **Live links.** Every file written in this repository links to the checkout, not to a copy in the Nix store. Editing an already-linked file needs no rebuild, and apps can write their settings back.
- **Private files** sit in the `private` set of `nix/links.nix` and are linked only where they exist. Keep them out of the Nix store, which every user on the machine can read.
- **Store links.** Only third-party content comes from the store: prezto (`~/.zprezto`) and the vim dracula theme, pinned in `flake.lock`, and the `vendor/` and `vendor-auto/` skills.
- **Impure by design.** The username, home directory and checkout path come from `$USER`, `$HOME` and `$DOTFILES_HOME`, so no machine's values are committed. `setup-home.sh` sets `DOTFILES_HOME` to its own checkout and passes `--impure`.
- **Tracked files only.** A flake sees only files git tracks. `git add` a new file under `nix/`, `skills/vendor/` or `skills/vendor-auto/` before running `setup-home.sh`.
- **A real file in the way stops the run.** Home Manager names it and links nothing. Move it aside and re-run.

### Agent Skills

Each directory under `skills/` is a package of skills, one folder per skill. `nix/skills.nix` links every skill in the installed packages into `~/.claude/skills` and `~/.agents/skills`, and a skill name present in two packages fails the build:
- `personal/`, `work/` — written here, linked live
- `vendor/` — third-party, user-invoked only: the store copy gets `disable-model-invocation: true` in each `SKILL.md`, and the tracked file stays as it is
- `vendor-auto/` — third-party, model-invoked: the store copy has that key stripped
- `vendor-mattpocock/` — synced from upstream by the repo-level `sync-mattpocock-skills` skill in `.claude/skills/`, linked live with its frontmatter as written
- `pending/`, `vendor-pending/` — parked, not installed

A change to a `vendor/` or `vendor-auto/` skill reaches `$HOME` on the next `bash setup-home.sh`.

### Shell (ZSH)

`zsh/dot-zsh/` files are sourced by glob in numeric order:
- `00-SECRETS.zsh` — credentials rendered from the committed `00-secrets.tpl` (1Password `op://` references) by a manual `bin/secrets-sync` run; `bin/secrets-sync --check` validates the references without writing (never read or edit `00-SECRETS.zsh`)
- `01-*` — base config, exports
- `02-*` — framework setup, plus atuin/direnv/mise init cached under `~/.cache/zsh`
- `03-*` — aliases (general, macOS, programming)
- `04-*` — prompt tweaks
- `05-*` — utility functions
- `98-agent-shell.zsh` — when `$AI_AGENT` or `$CLAUDECODE` is set, drops the `rm`/`cp`/`mv` aliases and relaxes clobber, nomatch, correct and equals, so agent-run commands don't hang or abort
- `01.5-custom.zsh`, `99-custom.zsh` — private, git-ignored

PATH, `DOTFILES_HOME` and `brew shellenv` live in `zprezto/dot-zprofile`, which login shells source; non-login shells source it through `zprezto/dot-zshenv` when `DOTFILES_HOME` is unset.

### Homebrew

Separated Brewfiles in `brew/`: `Requirefile` (essentials installed first), `Brewfile`, `Caskfile`, `CaskfileQuicklook`, `Fontfile`, `Macfile`. `CaskfileExtended` holds optional apps and is installed manually.

### Pinned Dependencies

prezto and the vim dracula theme are flake inputs, pinned by commit in `flake.lock`.

## Conventions

- **Public repo**: Every commit is published on GitHub. Before committing, read the staged diff for anything not meant for release: secrets and credentials, private hostnames or IPs, email addresses, and any text about work (employer, coworkers, clients, internal tools or repos), other people, or private life. If any appear, refuse to commit and report what you found. Sensitive values belong in the git-ignored private files or 1Password; terms that must never appear go in the git-ignored `.gitleaks.private.toml`, which the pre-commit hook enforces and which extends the committed `.gitleaks.toml`.
- **Bash scripts**: Always `#!/usr/bin/env bash` + `set -euo pipefail`
- **Dotfile names**: Use `dot-` prefix for dotfiles, never create raw `.` files in packages
- **Commits**: Conventional format — `type(scope): description` (scopes: tool/component names)
- **Changelog**: A breaking change gets a dated entry at the top of `CHANGELOG.md` in the same PR. Breaking means a machine that is already set up needs action after pulling, or a path, script, alias or link target it relies on was moved, renamed or removed. The entry lists what changed and the commands to migrate.
- **Private files**: `01.5-custom.zsh`, `99-custom.zsh`, `dot-git-user`, `00-SECRETS.zsh` are git-ignored
- **New scripts**: Add to `bin/` — automatically on `$PATH` via `$DOTFILES_HOME/bin`
