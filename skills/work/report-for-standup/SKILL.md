---
name: report-for-standup
description: Turn recent work into Jason's async standup post or end-of-day stakeholder update, formatted for Slack and copied to the clipboard.
disable-model-invocation: true
---

# Report for standup

Jason pastes this into the async standup thread in Slack. Teammates skim it between their own posts, so it reads like one of theirs: a few terse bullets, in Jason's own voice. The samples at the bottom are the spec; the rules only name what they show.

## Audience

Pick the audience from Jason's request before writing a word:

- **Engineers** (the default): the standup thread. Follow Shape through Samples below.
- **Stakeholders**: any ask for non-technical readers, an end-of-day update, or an update for product, CS or leadership. Read [`STAKEHOLDERS.md`](STAKEHOLDERS.md); its shape replaces Shape, Casing and Samples here. Source and Deliver still apply.

Take the date and weekday from `date "+%A %b %-d"`, and use them verbatim wherever the post names the day.

## Source

Sweep the window Jason names ("today" means since local midnight), else the last 24 hours, from all four sources, whatever the conversation holds; the conversation is one input, not the whole picture:

- Commits: `git log --all --author="Jason Raimondi" --since="24 hours ago"`. Group by ticket or scope into workstreams.
- PRs: `gh pr list --author @me --state all --search "updated:>=<24h ago>"` for merged, open, and draft. Merged is shipped, open or draft is in hand.
- Notebook: files changed in the window under `$AI_NOTEBOOK_PATH` (`find -L "$AI_NOTEBOOK_PATH" -name '*.md' -newermt "$(date +%F)"` for today, skipping `.git`, `.obsidian` and run-artifact folders). Skim the head of each; the topic `wiki/` pages' State and Open sections are the fastest digest of where a ticket stands. On agent-heavy days most work lives here on unpushed branches, so the notebook is often the main source.
- Conversation: work done in this session.

Open PRs untouched for the window have no bullet. Meeting prep and handoffs count as a workstream when a notebook file shows them.

Distill by ticket: a ticket's plans, fleet reports, reviews, triage and handoffs fold into one workstream that says what changed for it. Reviews, audits and agent runs are legwork; report what they found, decided or unblocked. Personal repos (dotfiles, skills) stay out unless Jason asks for them.

## Shape

One `•` bullet per workstream, two or three in all. Every line, headline or sub-bullet, is 3 to 8 words; a link label doesn't count. Cut a line to fit rather than split it. Order: shipped, then in hand, then next up or a blocker. Each bullet starts on the verb, subject dropped.

The `•` line is a headline: what changed and why anyone cares, in plain words ("Replaced babel react-compiler with native rust port, frontend builds faster"). Library names, counts, and status go underneath as indented `-` sub-bullets, one fact each. A workstream with only one thing to say stays a single `•` line. When a post feels long, cut sub-bullets before cutting workstreams.

Link a PR or ticket only where a reader would click it: the open PR you want reviewed, the ticket you're blocked on. Shipped chores need no link.

- **Shipped**: past tense. "Deployed out …", "Fixed …", "Merged …". When the fix touches customers or admins, say the effect in their words ("they should no longer be borked").
- **In hand**: "Working on …", "Finalizing …", "Bringing … to the finish line". Say where it stands ("in review now", "testing on dev-5") and hedge the ETA ("should have a PR up shortly", "trying to get it ready for merge soon!").
- **Next or blocker**: "After that, …" or "I'm going to look at … after". A blocker is a plain ask naming what is missing ("Going to need additional context on …", "just have a quick question for Hannah about it").

Product terms stay as the team says them (`GLOSSARY.md` if present); jargon is fine, the readers are engineers. At most one emoji, and only where Jason would wince or hope: `:see_no_evil:` after a confession, `:crossed_fingers:` on a long shot.

Personal logistics are one more bullet with the time window and who covers: "OOO after 2pm, Brandi is taking over shift after 2."

## Casing and punctuation

- Every bullet starts with a capital letter.
- A headline is a terse clause and can end bare. A sub-bullet is a full sentence ending in a period; a second thought is a second sentence.
- Contractions keep their apostrophes ("couldn't", "I'm").
- Capitalize only proper nouns and product names. A role is lowercase ("admins", not "Admin's").
- A trailing link is a bare URL ending the line: `… date picker tests https://linear.app/…/ENG-1002`
- An emoji sits after the sentence it reacts to, then the next sentence starts: `… the day the sub ends. :see_no_evil: Trying to …`

## Slack formatting

The post is Slack mrkdwn, pasted as plain text into the message box:

- One `•` headline per line, its sub-bullets on the lines under it as `  - ` (two-space indent). Nothing before or after the list.
- Links are bare URLs. Slack's message box doesn't parse `<url|label>` when pasted as plain text; it turns the whole string into one broken link. A ticket is its bare Linear URL, a PR its bare GitHub URL.
- Emoji are `:shortcode:`.
- Emphasis, if any, is Slack's `*bold*` and `_italic_`, never Markdown headers or `**double asterisks**`.

## Deliver

Copy the post to the clipboard, then show it in the reply so Jason can check it before pasting. One Bash call, single-quoted heredoc with a fresh random sentinel so `<`, `|`, and `:` pass through literally:

```bash
pbcopy <<'CLIP_a93b2f'
• Replaced babel react-compiler with native rust port, frontend builds faster
  - Swapped the eslint-plugin-react-compiler rc for eslint-plugin-react-hooks.
• Working on improved search indexing https://linear.app/acme/issue/ENG-1001
CLIP_a93b2f
```

The reply is the post in a fenced block followed by one line: "Copied to clipboard." If `pbcopy` is missing, say so and show the post anyway.

## Samples

From Jason's past posts, with casing and punctuation normalized to the rules above. The first is the most recent and the closest to how he writes now.

```
• Replaced babel react-compiler with native rust port, frontend builds faster
  - Swapped the eslint-plugin-react-compiler rc for eslint-plugin-react-hooks.
• Atlas staff admin work into one stack PR https://github.com/acme-org/app/pull/1234
  - Sessions now show who started them plus their models and tokens next to cost, and you can filter by person and background runs.
  - Finishing QA fixes on frontend conventions now, trying to get it ready for merge soon!
```

```
• Deployed out a fix for trialing shops that uninstall and then reinstall. They should no longer be borked.
• Working on final QA and testing of allowing a scheduled subscription change from a legacy subscription to a modular sub. This is for admins b/c right now on brands that are moving over, they need to remember to make the manual change on the day the sub ends. :see_no_evil: Trying to get this merged out today ideally.
```

```
• Fixed the onboarding stepper header issue, in review now.
• Working on the general support request page now. I have the full page and form loading already. One small issue that I'm going to start a new thread about.
```

```
• Deployed PR for date picker tests https://linear.app/acme/issue/ENG-1002
• Working on improved search indexing https://linear.app/acme/issue/ENG-1001
• Going to need additional context on the next ticket. I tried to go spelunking but couldn't quite figure it out: https://linear.app/acme/issue/ENG-1003
```

```
• Fixed sticky header content overlay & out of viewport billing upgrade CTA https://github.com/acme-org/app/pull/1234
• Working on Account settings redesign, coming along nicely so far. Doing the first rounds of testing on dev-5.
```

Done when the post sits inside its audience's shape, the day it names matches `date`, every piece of work from all four sources either has a bullet or was dropped on purpose, and the post is on the clipboard.
