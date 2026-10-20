---
name: report-for-standup
description: Turn recent work into Jason's async standup post.
disable-model-invocation: true
---

# Report for standup

Jason pastes this into the async standup thread in Slack. Teammates skim it between their own posts, so it reads like one of theirs: a few terse bullets, in Jason's own voice. The samples at the bottom are the spec; the rules only name what they show.

Source: the work in this conversation. If the conversation carries none, use `git log --author=jason --since=yesterday` across the repo.

## Shape

A flat list of `•` bullets and nothing else: two or three bullets, 15 to 60 words in all. Order: shipped, then in hand, then next up or a blocker. Each bullet is one sentence that starts on the verb, subject dropped.

- **Shipped**: past tense. "Deployed out …", "fixed …", "merged …". When the fix touches customers or admins, say the effect in their words ("they should no longer be borked").
- **In hand**: "Working on …", "Finalizing …", "bringing … to the finish line". Say where it stands ("in review now", "testing on dev-5") and hedge the ETA ("should have a PR up shortly", "trying to get this merged out today ideally").
- **Next or blocker**: "after, …" or "I'm going to look at … after". A blocker is a plain ask naming what is missing ("Going to need additional context on …", "just have a quick question to Hannah about it").

Links ride at the end of the bullet they belong to. A ticket is its Linear link labelled with the ID, `<url|ENG-1001>`, or the ID with its title. A PR is `<url|pr>` or the bare GitHub URL.

Casing is loose: a bullet may start lowercase. Bullets end without a period. Product terms stay as the team says them (`GLOSSARY.md` if present); jargon is fine, the readers are engineers. At most one emoji, and only where Jason would wince or hope: `:see_no_evil:` after a confession, `:crossed_fingers:` on a long shot.

Personal logistics are one more bullet with the time window and who covers: "OOO after 2pm, Brandi is taking over shift after 2".

## Samples

Verbatim from Jason's past posts.

```
• Deployed out a fix for trialing shops that uninstall, and then reinstall, they should no longer be borked
• Working on final QA and testing of allowing a scheduled subscription change from a legacy subscription to a modular sub. This is for Admin's b/c right now on brands that are moving over, they need to remember to make the manual change on the day the sub ends :see_no_evil: Trying to get this merged out today ideally
```

```
• fixed the onboarding stepper header issue, in review now
• working on the general support request page now. I have the full page and form loading already, one small issue that I'm going to start a new thread about
```

```
• Deployed PR for date picker tests <url|ENG-1002>
• Working on Improved search indexing <url|ENG-1001>
• Going to need additional context on next ticket, I tried to go spelunking but couldnt quite figure it out: <url|ENG-1003>
```

```
• fixed sticky header content overlay & out of viewport billing upgrade CTA (<url|pr>)
• working on <url|ENG-1004: Account settings redesign>, coming along nicely so far, doing the first rounds of testing on dev-5
```

Done when the post sits inside the shape above and every piece of work from the source either has a bullet or was dropped on purpose.
