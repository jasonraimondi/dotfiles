---
name: report-for-standup
description: Turn recent work into Jason's async standup post, formatted for Slack and copied to the clipboard.
disable-model-invocation: true
---

# Report for standup

Jason pastes this into the async standup thread in Slack. Teammates skim it between their own posts, so it reads like one of theirs: a few terse bullets, in Jason's own voice. The samples at the bottom are the spec; the rules only name what they show.

Source: the work in this conversation. If the conversation carries none, use `git log --author=jason --since=yesterday` across the repo.

## Shape

One `•` bullet per workstream, two or three in all, usually 30 to 60 words. Order: shipped, then in hand, then next up or a blocker. Each bullet starts on the verb, subject dropped.

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
- A trailing link sits inside the sentence, before the period: `… date picker tests <url|ENG-1002>.`
- An emoji sits after the sentence it reacts to, then the next sentence starts: `… the day the sub ends. :see_no_evil: Trying to …`

## Slack formatting

The post is Slack mrkdwn, pasted as plain text into the message box:

- One `•` headline per line, its sub-bullets on the lines under it as `  - ` (two-space indent). Nothing before or after the list.
- Links are `<url|label>`: a ticket is its Linear link labelled with the ID, `<url|ENG-1001>`, or the ID with its title, `<url|ENG-1004: Account settings redesign>`. A PR is `<url|pr>` or the bare GitHub URL.
- Emoji are `:shortcode:`.
- Emphasis, if any, is Slack's `*bold*` and `_italic_`, never Markdown headers or `**double asterisks**`.

## Deliver

Copy the post to the clipboard, then show it in the reply so Jason can check it before pasting. One Bash call, single-quoted heredoc with a fresh random sentinel so `<`, `|`, and `:` pass through literally:

```bash
pbcopy <<'CLIP_a93b2f'
• Replaced babel react-compiler with native rust port, frontend builds faster
  - Swapped the eslint-plugin-react-compiler rc for eslint-plugin-react-hooks.
• Working on improved search indexing <url|ENG-1001>.
CLIP_a93b2f
```

The reply is the post in a fenced block followed by one line: "Copied to clipboard." If `pbcopy` is missing, say so and show the post anyway.

## Samples

From Jason's past posts, with casing and punctuation normalized to the rules above. The first is the most recent and the closest to how he writes now.

```
• Replaced babel react-compiler with native rust port, frontend builds faster
  - Swapped the eslint-plugin-react-compiler rc for eslint-plugin-react-hooks.
• Atlas staff admin work into one stack PR (<url|pr>)
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
• Deployed PR for date picker tests <url|ENG-1002>.
• Working on improved search indexing <url|ENG-1001>.
• Going to need additional context on the next ticket. I tried to go spelunking but couldn't quite figure it out: <url|ENG-1003>.
```

```
• Fixed sticky header content overlay & out of viewport billing upgrade CTA (<url|pr>).
• Working on <url|ENG-1004: Account settings redesign>, coming along nicely so far. Doing the first rounds of testing on dev-5.
```

Done when the post sits inside the shape above, every piece of work from the source either has a bullet or was dropped on purpose, and the post is on the clipboard.
