# Notebook maintenance

Three chores keep the vault honest: **lint** finds drift, **compile** folds notes into their pages, **archive** retires finished topics. Paths are relative to `$NOTEBOOK`, resolved as in the notebook skill.

## Lint

`notebook-lint` ships in this skill's `scripts/` and runs on Python's standard library:

```sh
LINT="$HOME/.claude/skills/notebook/scripts/notebook-lint"
python3 -I "$LINT" --root "$NOTEBOOK"                     # full check, findings on stdout
python3 -I "$LINT" --root "$NOTEBOOK" --report lint.md    # also rewrite lint.md
python3 -I "$LINT" --root "$NOTEBOOK" --staged            # staged paths only; prints each rejected path
```

Exit 0 means no errors, 1 means errors; warnings never fail. Everything under `archive/` is skipped. The vault's pre-commit hook runs `--staged`, and the hourly sync runs `--report lint.md`, unstages the paths the hook rejects, and commits the rest. A rejected path keeps showing in `lint.md` until it is fixed.

Errors:

| Code | Means | Fix |
|---|---|---|
| `E-size` | File over 1 MB, or binary, under `topics/` or `inbox/` | Move it to `_bulk/<slug>/<stamp>-<name>/` and link that path |
| `E-raw` | `.req`, `.hdr`, `.body`, `.tokens`, `mdlr-cache/` or `.DS_Store` tracked anywhere | Move it to `_bulk/`, or delete it |
| `E-name` | Note not named `<stamp>-<kind>-<desc>.md` in kebab-case, or `<kind>` outside the type enum | Rename with `git mv` and rewrite links to the old stem |
| `E-front` | `type`, `topic` or `status` missing or invalid, `topic` not the folder name, or kind segment not the `type` | Correct the frontmatter or the name |
| `E-link` | A `[[stem]]` or vault path (including `_bulk/...`) that resolves to nothing; fenced code is skipped | Point it at the real stem or path, or remove it |
| `E-page` | `topics/<slug>/` without `<slug>.md`, or a page missing State, Decisions, Open or Sources | Create the page or add the section |
| `E-root` | Unexpected entry at the vault root | File it into a topic, `inbox/` or `_bulk/` |

Warnings:

| Code | Means | Fix |
|---|---|---|
| `W-sources` | Note in `topics/<slug>/` not in its page's Sources | Compile it |
| `W-resume` | Topic has handoffs, but Resume is not the newest non-superseded one | Repoint Resume; mark older handoffs `superseded` |
| `W-index` | Page missing from `index.md`, index line to a missing page, or line over 120 characters | Add, remove or shorten the line |
| `W-inbox` | Two inbox notes share a slug | Promote them into a topic folder |
| `W-archive` | Topic at `status: done`, or no new note for 30 days | Propose archiving (see Archive) |

On request, run the full check, fix every error, and work the warnings until each is fixed or reported back as a judgment call. Report the counts before and after.

## Compile

Compile folds notes into their topic page. It runs when asked, and as the last step of a fleet lead.

1. Collect the notes to ingest: every `W-sources` finding, plus notes in the topic folder newer than the topic's last ingest in `log.md`.
2. For each note, oldest first, revise the page: replace State claims the note supersedes or contradicts, add its decisions, close Open questions it answers and add the ones it raises, and add it to Sources. A handoff also moves the Resume line.
3. Check the page against its neighbours: a State claim contradicted by another topic's page gets an Open line on both.
4. Append one line per note to `log.md`:

   ```text
   ## [2026-11-16 10:30] ingest | 2026-11-16-1016-handoff-queue-drain-plan → eng-1006-stuck-jobs
   ```

   Take the time from `date '+%Y-%m-%d %H:%M'`.
5. Keep the topic's `index.md` line true to what the topic is.

Compile is done when lint reports no `W-sources` or `W-resume` for the topics touched. Report each page touched and what changed.

## Archive

Lint proposes, the user decides. Archive only on explicit approval of each topic.

1. Set the page to `status: done`.
2. `git mv topics/<slug> archive/topics/<slug>`, in one move.
3. Move its `index.md` line under Recently archived.

Wikilinks keep resolving, since they name stems, not paths. `_bulk/<slug>/` stays where it is. To revive a topic, move the folder back and set the page to `active`.
