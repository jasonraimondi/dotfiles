---
name: create-marp-deck
description: Creates polished Marp slide decks through an interview-driven workflow. Use when the user wants to create a presentation, build slides, or make a deck. Interviews the user first (goal, audience, key points, data, constraints), then generates structured Marp Markdown with gradient section dividers, breadcrumb navigation, consistent formatting, and automatic HTML/PPTX export.
disable-model-invocation: true
---

# Create Marp Slide Deck

Create a presentation slide deck using the Marp markdown format, following the established conventions below.

## Phase 1: Interview

Before generating anything, make sure you know the answers to the questions below. Ask about whichever ones the request and any provided files don't already answer, one at a time, waiting for each answer before the next.

**Question 1 — Goal & Topic:**
Ask: "What's this presentation about? What should the audience walk away knowing or being able to do?"

**Question 2 — Audience:**
Ask: "Who's the audience? (e.g., engineering team, executives, external clients, conference attendees)"

**Question 3 — Key Points:**
Ask: "What are the key points or sections you want to cover? List the main ideas, even if rough."
- If the user provides files, URLs, or references, read/fetch them thoroughly before continuing.

**Question 4 — Data & Demos:**
Ask: "Any specific data, code examples, diagrams, or demos to include? Do you have these ready, or should I create them?"

**Question 5 — Constraints:**
Ask: "Any constraints? Think: target number of slides, time limit for the talk, things to avoid, or specific branding requirements."

After collecting all answers, briefly summarize what you understood and ask for confirmation before proceeding.

## Phase 2: Generate the Deck

Follow the structure and conventions below exactly.

---

## FRONTMATTER

Every deck starts with this exact frontmatter:

```yaml
---
marp: true
theme: default
paginate: true
size: 16:9
---
```

---

## CSS STYLE BLOCK

Immediately after the frontmatter, include a `<style>` block with:

1. **Base font sizes** for section, table, blockquote, pre
2. **Header styles** for breadcrumb navigation (gray text, blue for active section)
3. **Section classes** for the title slide and each part/section divider - these get gradient backgrounds and white text

### Color palette for section dividers (pick 2-4 based on number of parts):
- Blue: `linear-gradient(135deg, #1e3a5f 0%, #2d5a8e 100%)`
- Green: `linear-gradient(135deg, #064e3b 0%, #047857 100%)`
- Amber: `linear-gradient(135deg, #7a4a1a 0%, #a66b2e 100%)`
- Purple: `linear-gradient(135deg, #3d1e5c 0%, #5a2d8e 100%)`
- Title slide (always dark navy): `linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%)`

### Template:

```html
<style>
section {
  font-size: 22px;
}
table {
  font-size: 18px;
}
blockquote {
  font-size: 22px;
}
pre {
  font-size: 16px;
}
header {
  font-size: 14px;
  color: #999;
}
header strong {
  color: #2563eb;
}
section.title-slide {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%);
}
section.part-FIRST,
section.part-SECOND,
section.part-THIRD,
section.title-slide {
  --h1-color: #fff;
  --heading-strong-color: #fff;
  --fgColor-default: rgba(255, 255, 255, 0.95);
  --fgColor-muted: rgba(255, 255, 255, 0.7);
  color: white;
}
section.part-FIRST {
  background: linear-gradient(135deg, #1e3a5f 0%, #2d5a8e 100%);
}
section.part-SECOND {
  background: linear-gradient(135deg, #064e3b 0%, #047857 100%);
}
section.part-THIRD {
  background: linear-gradient(135deg, #3d1e5c 0%, #5a2d8e 100%);
}
</style>
```

Replace `FIRST`, `SECOND`, `THIRD` with short descriptive names for each part (e.g., `part-context`, `part-results`, `part-summary`).

---

## SLIDE STRUCTURE

The deck follows this exact order:

### 1. Title Slide
```markdown
<!-- _class: lead title-slide -->

# Main Title
## Subtitle

**Key detail 1**: value
**Key detail 2**: value
**Date**: Month Year
```

### 2. Questions / Goals slide
List 3-5 questions the deck will answer, as a numbered list with bold lead-ins.

### 3. Agenda slide
```markdown
<!-- _class: lead title-slide -->

# Agenda

### Part 1: Name
Short description

### Part 2: Name
Short description

### Part 3: Name
Short description
```

### 4. For each part: section divider + content slides

**Section divider** (full-bleed colored background):
```markdown
<!-- _header: "" -->
<!-- _class: lead part-NAME -->

# Part N: Section title

**One-line description**
```

**Content slides** (with breadcrumb header):
```markdown
<!-- header: "**Active section** > Other section > Other section" -->

# Slide title

Content here
```

The breadcrumb shows where you are in the deck. The active section is wrapped in `**bold**`. The header directive persists until changed, so you only need to set it once per section (on the first content slide after the divider). Reset it with `<!-- _header: "" -->` before each section divider.

### 5. Final Slides
End with summary/takeaway slides, still within the last section.

---

## FORMATTING RULES

1. **Sentence case for all headings** — only capitalize the first letter and proper nouns (e.g., "Get started in 5 minutes", not "Get Started in 5 Minutes"). Breadcrumb headers follow the same rule
2. **No trailing periods** on bullets, text lines, or table cells
3. **Single dash** (`-`) for parenthetical separators, not double dash (`--`)
4. **Backticks** for program names, file names, and technical identifiers (not bold)
5. **Bold** for emphasis on key phrases and findings
6. **Tables** for data comparisons - keep them concise
7. **Blockquotes** (`>`) for key callouts or distinctions
8. **One idea per slide** - if a slide is getting dense, split it into two
9. Keep bullet lists to 3-5 items max per slide
10. No parenthetical notes in the slide body unless absolutely necessary

---

## EXPORTING

After writing the deck, export to both HTML and PPTX:

```bash
npx @marp-team/marp-cli@latest --no-stdin FILENAME.md -o FILENAME.html
npx @marp-team/marp-cli@latest --no-stdin --pptx FILENAME.md -o FILENAME.pptx
```

Always use `--no-stdin` to prevent marp from hanging on stdin.

---

## MOBILE-FRIENDLY WEB EXPORT

**Required whenever the deck is shared as a link** (Netlify, GitHub Pages, Slack) rather than presented live.

Every Marp HTML export renders each slide as a fixed 1280×720 stage. On a phone the whole stage scales to roughly 30%, so 22px body text lands at ~7px. No CSS on the slide *stage* fixes this — the text is small because the slide is small. Shrinking or scroll-snapping the stage just yields an unreadable deck that scrolls.

The fix is to serve two different things:

| File | What it is | Who gets it |
|---|---|---|
| `index.html` | The normal slideshow — arrow keys, swipe, fullscreen. Unchanged | Desktop and tablets |
| `mobile.html` | The deck's **content reflowed into a responsive document** — real text at phone size, one card per slide | Phones (auto-redirected) |

`mobile.html` is not a scaled slideshow. `scripts/marp-mobile.py` (bundled with this skill) re-parses the deck markdown and emits a normal HTML document: 17px body text that wraps to the screen, one card per slide, section dividers and title slide keeping the gradients **read from the deck's own `<style>` block** (so it adapts to any deck using these conventions), breadcrumb headers as a nav line, slide numbers, tables in their own horizontal-scroll container, and a dark-mode variant.

```bash
# 1. Desktop slideshow (unchanged)
npx @marp-team/marp-cli@latest --no-stdin --html FILENAME.md -o SITE_DIR/index.html

# 2. Reflowed mobile document
python3 scripts/marp-mobile.py FILENAME.md -o SITE_DIR/mobile.html --slideshow-href "./"

# 3. Send phones to the mobile view — inject right after <head>, before anything renders
python3 - <<'EOF'
import io
p = 'SITE_DIR/index.html'
html = io.open(p, encoding='utf-8').read()
redirect = "<script>if(matchMedia('(pointer:coarse)').matches&&Math.min(screen.width,screen.height)<700)location.replace('mobile.html')</script>"
assert '<head>' in html
io.open(p, 'w', encoding='utf-8').write(html.replace('<head>', '<head>' + redirect, 1))
EOF
```

Requires `markdown-it-py` (`pip install markdown-it-py`).

Notes:
- The redirect must be JS, not a meta refresh — it needs the pointer/screen test. The `< 700px` smallest-dimension check keeps tablets on the real slideshow. `location.replace` leaves the back button working.
- `mobile.html` shows a "Slideshow ↗" link back to `index.html` on hover-capable devices only, so a desktop visitor who lands there isn't stuck.
- Netlify's pretty-URL post-processing rewrites `href` attributes but not JS strings, so the `'mobile.html'` redirect target survives deploy.
- The script reflows **markdown**, not Marp's rendered output. Renderer-level features (`![bg]` background images, multi-column CSS, positioned image reveals) will not carry over. For a component-heavy deck, accept a plain-text mobile view or share a PDF instead.
- Verify before deploying by screenshotting `mobile.html` **directly** — headless Chrome reports a fine pointer, so `index.html` will not redirect:
  `chrome-headless-shell --headless --screenshot=/tmp/m.png --window-size=390,900 file://…/mobile.html`

---

## EDITABLE PPTX EXPORT (OPTIONAL)

If the user asks for editable PPTX (text that can be edited in PowerPoint or Google Slides), run these additional steps. This requires LibreOffice and python-pptx to be installed.

```bash
# PPTX - editable text (experimental, requires LibreOffice)
npx @marp-team/marp-cli@latest --no-stdin --pptx --pptx-editable --allow-local-files FILENAME.md -o FILENAME-editable.pptx
python3 -c "
from pptx import Presentation
from pptx.util import Emu
prs = Presentation('FILENAME-editable.pptx')
margin = Emu(747720)
for slide in prs.slides:
    for shape in slide.shapes:
        if shape.has_text_frame and shape.shape_type == 17:
            tf = shape.text_frame
            if not tf.text.strip() or tf.text.strip().isdigit():
                continue
            font_size = None
            if tf.paragraphs and tf.paragraphs[0].runs:
                font_size = tf.paragraphs[0].runs[0].font.size
            if not font_size:
                continue
            new_width = prs.slide_width - margin - shape.left
            if new_width > shape.width:
                shape.width = new_width
            min_height = int(font_size * 1.4) * 2
            if shape.height < min_height:
                shape.height = min_height
            tf.word_wrap = True
prs.save('FILENAME-editable.pptx')
"
```

Notes:
- `--allow-local-files` needed for local images
- `--pptx-editable` requires LibreOffice installed
- The python-pptx post-processing fixes text box sizing issues from LibreOffice conversion
- Always use `--no-stdin` to prevent marp from hanging on stdin
