# Changelog

## 2026-11-13: the skills repo now lives in dotfiles

The separate `jasonraimondi/skills` repo was merged into this one under `skills/`, with its full history. The old repo is archived and read-only, and its README points here.

### Changed

- Everything from the skills repo sits under `skills/`: the skill packages (`skills/skills`, `skills-for-work`, `vendor`, `vendor-auto`, `vendor-mattpocock`, plus the two `-pending` ones), the Claude and Pi settings (`skills/claude`, `skills/pi`), the global `skills/AGENTS.md`, `skills/setup.sh` and `skills/add-skill.sh`.
- `bash setup.sh` runs `skills/setup.sh` right after `setup-stow.sh`. `setup-stow.sh` itself leaves `skills/` alone, so re-linking agent config is `bash skills/setup.sh` (`-n` dry-run, `-D` delete).
- The `skills` shell alias runs `$DOTFILES_HOME/skills/add-skill.sh`.
- The Claude auto-mode settings name `~/dotfiles` and `jasonraimondi/dotfiles` as the trusted repo, with `macos` as the default branch.
- Skill changes are committed to `macos` in this repo.

### Added

- `skills/setup.sh` links `skills/AGENTS.md` to `~/.config/opencode/AGENTS.md`. opencode already reads `~/.claude/skills` and `~/.agents/skills`, so its skills need no extra links.

### Removed

- `skills/setup.sh` no longer links `AGENTS.md` for Cursor, Windsurf or Junie. `AGENTS.md` is linked for Claude, opencode and Pi.
- The Mixpanel tool allowlist in `skills/claude/settings.json`.

### Reading the old history

The 331 skills commits keep their original hashes, and their paths have no `skills/` prefix. `git blame` and `git log --follow -- <file>` trace a file back through the merge. `git log -- skills/<directory>` only reaches back to the merge.

### Migrating a machine

For a machine that still has its own clone of the skills repo. A machine that never had one only needs `git pull` and `bash skills/setup.sh`.

Run the steps in order. The old clone's `setup.sh -D` is the only thing that cleanly removes the old links, so it has to run before the clone is deleted.

1. **Find the old clone.**

   ```bash
   OLD="$(dirname "$(readlink ~/.claude/CLAUDE.md)")"
   echo "$OLD"
   ```

   Done when `$OLD` is the skills clone and `$OLD/setup.sh` exists. If it already prints a path ending in `dotfiles/skills`, this machine is migrated and there is nothing to do.

2. **Carry over local-only work.** The old repo is archived, so nothing can be pushed to it.

   ```bash
   git -C "$OLD" fetch
   git -C "$OLD" status --short
   git -C "$OLD" log --oneline origin/main..HEAD
   git -C "$OLD" stash list
   git -C "$OLD" worktree list
   ```

   Save anything those show before going further:

   ```bash
   git -C "$OLD" format-patch origin/main --stdout > /tmp/skills-commits.patch
   git -C "$OLD" diff > /tmp/skills-wip.patch
   ```

   Two git-ignored files exist only on disk; keep them if they matter on this machine: `claude/settings.json.bak` and `.serena/project.local.yml`. Remove any extra worktree with `git -C "$OLD" worktree remove <path>` once its work is saved, because deleting the clone orphans it.

   Done when every line of output above is either saved to a patch or known to be disposable.

3. **Update dotfiles.**

   ```bash
   git -C ~/dotfiles checkout macos && git -C ~/dotfiles pull
   ```

   Done when `~/dotfiles/skills/setup.sh` exists.

4. **Apply the saved work**, if step 2 produced any.

   ```bash
   cd ~/dotfiles
   [ -s /tmp/skills-commits.patch ] && git am --directory=skills /tmp/skills-commits.patch
   [ -s /tmp/skills-wip.patch ] && git apply --directory=skills /tmp/skills-wip.patch
   ```

   Done when `git status` shows the carried-over changes under `skills/`.

5. **Switch the links.**

   ```bash
   bash "$OLD/setup.sh" -D
   bash ~/dotfiles/skills/setup.sh -n
   bash ~/dotfiles/skills/setup.sh
   ```

   A conflict in the dry run means a real file sits where a link belongs. Stop and look at that file; `--adopt` would overwrite the repo copy with it. If the new setup fails after the old links are gone, `bash "$OLD/setup.sh"` puts them back.

   Done when the last command exits 0.

6. **Reinstall the Pi extension dependencies**, on machines that use Pi. `node_modules` is git-ignored, so it does not come with the pull.

   ```bash
   cd ~/dotfiles/skills/pi/extensions/pi-peer && npm ci
   ```

7. **Verify.**

   ```bash
   readlink ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.config/opencode/AGENTS.md
   find ~/.claude ~/.agents ~/.pi ~/.config/opencode -maxdepth 3 -type l -lname "*${OLD#"$HOME"/}*" 2>/dev/null
   find ~/.claude/skills ~/.agents/skills -maxdepth 1 -type l ! -exec test -e {} \; -print
   zsh -i -c 'alias skills'
   ```

   Done when the three links resolve into `dotfiles/skills`, both `find` commands print nothing, and the alias points at `dotfiles/skills/add-skill.sh`.

8. **Delete the old clone**, from the same shell that set `$OLD` in step 1.

   ```bash
   echo "$OLD" && rm -rf "$OLD"
   ```

   Open shells keep the old alias until restarted with `exec zsh`.

9. **Clear leftovers from dropped tools**, where those tools are not installed: `~/.junie`, `~/.cursor` and `~/.codeium` held only links from older setups. Look inside before deleting; on a machine that uses Cursor or Windsurf they hold live config.
