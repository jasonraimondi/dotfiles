---
name: html
description: HTML and template markup conventions. Use when writing or refactoring HTML or template markup (including Svelte), choosing between div/section/article/ul/li, cleaning up div soup, fixing heading or landmark structure, labeling forms, deciding between buttons and links, embedding images or media, adding ARIA, or replacing custom controls with native HTML. Also use for UI/accessibility review, or checking UI code against best practices.
---

# HTML Best Practices

Write semantic, accessible, low-noise HTML. Pick the element that matches the content or interaction — not the element a rule prescribes.

**Violating the spirit beats violating the letter.** "Semantic HTML" does not mean using the most specialized element everywhere. A plain `<div>` is better than a wrong semantic element.

## Decision order

1. Pick the element that matches the content or interaction.
2. Prefer native HTML behavior before custom behavior.
3. Remove wrappers that add no structural, styling, or behavioral value.
4. Get labels, headings, landmarks, and image handling right.
5. Reach for ARIA only when native HTML cannot express the behavior.

## Template safety

When the file is a framework component or template (not a standalone document), read the matching framework reference before editing:

- Svelte: [references/svelte.md](references/svelte.md)

## Element choice

### Lists vs sections vs articles vs containers

Repetition is not list semantics. Wrapping card grids in `<ul>`/`<li>` by default is the most common mistake.

| Content | Element |
|---|---|
| Steps, menu items, bullets, grouped items where *being a list* is the point | `<ul>` / `<ol>` / `<li>` |
| Each repeated item stands on its own (post, card, search result) with its own heading or actions | `<article>` |
| Block of content unified by a theme that benefits from its own heading | `<section>` |
| Mostly layout, no stronger semantic available | plain `<div>` |

### Forms

- Every input has an associated `<label>` (wrap or `for`/`id`). Placeholder is not a label.
- Use the right `type` (`email`, `tel`, `number`, `url`, `password`, `search`, `date`).
- Group related inputs in `<fieldset>` with a `<legend>`.
- Mark required fields with the `required` attribute, not just text.
- Use native validation attributes (`required`, `pattern`, `min`, `max`, `maxlength`) before reaching for JS validation.

### Links vs buttons

- `<a>` to go somewhere (changes URL/location).
- `<button>` to do something (mutates state, submits, opens UI).
- Never a clickable `<div>` or `<span>`.

### Images

- `alt=""` for decorative images.
- Descriptive `alt` for informative ones — describe meaning, not file content.
- Provide `width` and `height` to reduce layout shift.
- `<figure>` + `<figcaption>` when the caption is part of the content.
- `srcset`/`sizes` when meaningfully different sizes are actually served.
- `loading="lazy"` for below-the-fold images — never for the hero/LCP image.

### Video and audio

- Provide captions (`<track kind="captions">`) for video with speech; link a transcript when practical.
- Use `poster` so video has a meaningful thumbnail before playback.
- Do not autoplay with sound. If a video must autoplay, mute it and give the user a way to stop it.

### Text emphasis

- `<em>`/`<strong>` when the emphasis changes meaning.
- `<b>`/`<i>` are valid for conventions (keywords, terms, titles, foreign phrases) — not for looks.
- Purely visual styling belongs in CSS, not in element choice.

### Headings

- One clear `<h1>` per page or main view.
- Follow the outline (`h1` → `h2` → `h3`). Do not skip levels for visual reasons.
- Do not use headings to make text big.

### Landmarks

- Use `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>` where they help orientation.
- Do not wrap every block in a landmark — too many landmarks is noise, not structure.

### Native controls first

`<button>`, `<details>`/`<summary>`, `<dialog>`, `<input>`, `<select>`, `<fieldset>`, `<table>` are almost always better than rebuilding them from `<div>`s and JS.

### ARIA (when native HTML falls short)

Most ARIA is a sign a native element exists that you didn't use. When native HTML genuinely can't express it:

- `aria-label` / `aria-labelledby` for accessible names (icon-only buttons, landmark disambiguation).
- `aria-expanded` on toggles that show/hide content.
- `aria-hidden="true"` on decorative icons and duplicated visuals.
- `aria-live` for content that updates without user action.

An ARIA attribute is a promise about behavior: `aria-expanded` that never changes is worse than nothing.

### Document metadata (full documents only)

For standalone documents include: `<!doctype html>`, `lang` on `<html>`, `<meta charset="utf-8">`, `<meta name="viewport" content="width=device-width, initial-scale=1">`, a meaningful `<title>`.

Load scripts with `defer` (or `type="module"`, which defers by default) instead of blocking parsing at the bottom of `<body>`.

## Anti-patterns

- Clickable `<div>` or `<span>` instead of `<button>` or `<a>`.
- ARIA added where native HTML already does the job.
- Inputs without an associated `<label>`; placeholder used as the label.
- Headings chosen for font size, or levels skipped.
- Deeply nested wrappers that exist only because they were there before.
- Tables used for layout.
- `onclick="..."` strings in raw HTML (different from framework event attributes).
- `<ul>`/`<li>` around card grids by default.
- `<section>` or `<article>` forced onto layout-only structures.
- Extra landmarks with no navigational purpose.
- ARIA state attributes that don't track real state (`aria-expanded` that never updates).
- Autoplaying media with sound.
- Class names that describe appearance (`box1`, `red_text`, `left_side`).

## UI review mode

When asked to review or audit existing UI code ("review my UI", "check accessibility", "audit design", "review UX"), check the files against the Web Interface Guidelines in addition to the rules above:

1. Read [references/web-interface-guidelines.md](references/web-interface-guidelines.md) — a vendored copy of Vercel's [web-interface-guidelines](https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md) `command.md`.
2. Read the files under review (ask which files if none were given).
3. Apply all rules from the guidelines plus this skill's anti-patterns.
4. Output findings grouped by file in the terse `file:line` format specified in the guidelines.

## Heuristics

When in doubt, ask:

- Can each element justify why it exists?
- Would this still make sense without CSS?
- Is this truly a list, or just repeated content?
- Could each repeated item stand alone as an `<article>`?
- Am I choosing this element because it's accurate, or because it's a rule I memorized?
