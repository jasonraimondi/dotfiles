---
name: dotfiles
description: Change Jason's macOS dotfiles in ~/dotfiles. Use when asked to add or change a shell alias, function, env var, PATH entry, tool init, Homebrew package, mise tool version, git alias or setting, macOS default, Dock app, or an app config under ~/.config (herdr, zed, karabiner, mise), or to add a script to bin.
---

# Dotfiles

`~/dotfiles` is linked into `$HOME` by Home Manager. `nix/links.nix` lists every link as `"path in $HOME" = "path in the repo"`, where a repo file named `dot-foo` lands as `~/.foo`. Edit the file in the repo, never the symlink target in `$HOME`.

## Steps

1. **Route.** Pick the file from the table below. One concern, one file. When the change fits no row, say so and propose the file before editing.
2. **Edit** in `~/dotfiles`. Match the neighbouring style. Add a tool init as a `_source_cached` line the way `02-setup.zsh` does.
3. **Verify** with the command for that row. Done when it exits 0 and the new thing resolves.
4. **Apply.** An edit to an existing file needs nothing, and neither does a new file inside a directory `nix/links.nix` links whole (`zsh/dot-zsh/`, `config/mise/`); tell the user `exec zsh` for shell changes. Any other new file needs its own line in `nix/links.nix`, then `bash setup-home.sh -n` and `bash setup-home.sh`. A run that stops on an existing file means a real file sits where a symlink belongs: report it and leave it in place.
5. **Commit** to `macos` as `type(scope): description`. Scope is the package directory, or the app name under `config/`. `git status --short` first, and stage only your change.

## Routing

| Change | File | Verify |
|---|---|---|
| general alias | `zsh/dot-zsh/03-aliases.zsh` | `zsh -i -c 'whence -w NAME'` reports `alias` |
| macOS alias | `zsh/dot-zsh/03-aliases-macos.zsh` | same |
| dev or AI tool alias (`sonnet`, `opus`, `fable` live here) | `zsh/dot-zsh/03-aliases-programming.zsh` | same |
| function | `zsh/dot-zsh/05-functions.zsh`; git ones in `05-functions-git.zsh` | `whence -w` reports `function`; `return`, never `exit` |
| env var | `zsh/dot-zsh/01-exports.zsh` | `zsh -i -c 'echo $NAME'` |
| PATH entry | the `path=( … )` array in `zprezto/dot-zprofile` | `zsh -l -c 'echo $PATH'` |
| tool init (`_source_cached x init zsh`) | `zsh/dot-zsh/02-setup.zsh` | `zsh -i -c exit` exits 0 |
| script | `bin/NAME`, `#!/usr/bin/env bash`, `set -euo pipefail`, `chmod +x` | `shellcheck bin/NAME` |
| CLI formula | `brew/Brewfile` | `brew info NAME` resolves |
| GUI app | `brew/Caskfile`; hobby or optional apps in `CaskfileExtended` (manual install only) | `brew info --cask NAME` |
| font | `brew/Fontfile` | same |
| Mac App Store app | `brew/Macfile` | `mas search NAME` |
| language or tool version | `config/mise/config.toml` | `mise ls` |
| default npm or gem package | `mise/dot-default-npm-packages`, `mise/dot-default-gems` | file read |
| git alias or setting | `git/dot-gitconfig` | `git config --get KEY` |
| global gitignore | `git/dot-gitignore` | `git check-ignore -v PATH` |
| Herdr, Zed, Karabiner | `config/APP/` | app reload |
| macOS default | `setup-systemprefs.sh` with the `run` wrapper | `bash setup-systemprefs.sh -n` |
| Dock app | `setup-dock.sh` | `bash setup-dock.sh` |
| tmux, vim | `tmux/dot-tmux.conf`, `vim/dot-vimrc` | `tmux source-file`, `vim -c q` |
| new package | new directory plus its lines in `nix/links.nix` | `bash setup-home.sh -n` |
| Claude or Pi setting | `claude/`, `pi/` | `bash setup-home.sh -n` |
| agent skill, global agent instructions | `skills/PACKAGE/NAME/`, `GLOBAL_AGENTS.md`; a new skill is linked by `bash setup-home.sh` | `bash setup-home.sh -n` |
| prezto or dracula vim theme version | `nix flake update prezto` or `dracula-vim`, which rewrites `flake.lock` | `bash setup-home.sh -n` |

Shell files load alphabetically, so `03-aliases-*.zsh` run before `03-aliases.zsh` and an alias defined later wins over an earlier function of the same name. Check `whence -w` after every alias or function.

Mise is not activated in the shell: its shims directory leads PATH (`zprezto/dot-zprofile`) and only its completions load. A tool added to `config/mise/config.toml` resolves through its shim once `mise install` has run.

## Private files

`zsh/dot-zsh/99-custom.zsh` and `01.5-custom.zsh` are gitignored per-machine files. Edit them only when asked for a private or local change, and skip the commit step.

Never read, edit, or print `zsh/dot-zsh/00-SECRETS.zsh`, `git/dot-git-user`, `aws/dot-aws/*`, `ssh/config`, or any `.gpg` file.
