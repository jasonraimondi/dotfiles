#!/usr/bin/env python3
"""Render a Marp deck as a responsive mobile HTML document.

Marp's own HTML exports (bespoke and bare) render every slide as a fixed
1280x720 stage, so on a phone the whole slide is scaled to ~30% and 22px body
text lands at ~7px. This reflows the same markdown into a normal HTML document:
real text at mobile-readable size, one card per slide, section dividers keeping
the gradient backgrounds declared in the deck's <style> block.

Usage: marp-mobile.py deck.md -o site/mobile.html [--slideshow-href ./]
"""

import argparse
import html
import re
import sys

from markdown_it import MarkdownIt

FENCE_RE = re.compile(r"^\s*(```|~~~)")
DIRECTIVE_RE = re.compile(r"<!--\s*(_?)(class|header|footer|paginate|backgroundColor|color)\s*:\s*(.*?)\s*-->", re.S)
COMMENT_RE = re.compile(r"<!--.*?-->", re.S)
STYLE_RE = re.compile(r"<style>(.*?)</style>", re.S)
# section.foo, section.foo.bar — capture the class chain so we can re-scope it
SECTION_RULE_RE = re.compile(r"(^|,|\})\s*section((?:\.[\w-]+)+)", re.M)


def split_source(text):
    """Return (frontmatter, style_css, [raw_slide_chunks])."""
    lines = text.split("\n")
    i = 0
    frontmatter = ""
    if lines and lines[0].strip() == "---":
        for j in range(1, len(lines)):
            if lines[j].strip() == "---":
                frontmatter = "\n".join(lines[1:j])
                i = j + 1
                break

    body = "\n".join(lines[i:])

    style_css = ""
    m = STYLE_RE.search(body)
    if m:
        style_css = m.group(1)
        body = body[: m.start()] + body[m.end() :]

    # Split on standalone `---` outside fenced code blocks
    chunks, current, in_fence = [], [], False
    for line in body.split("\n"):
        if FENCE_RE.match(line):
            in_fence = not in_fence
        if not in_fence and line.strip() == "---":
            chunks.append("\n".join(current))
            current = []
        else:
            current.append(line)
    chunks.append("\n".join(current))

    return frontmatter, style_css, [c for c in chunks if c.strip()]


def parse_directives(chunk, sticky):
    """Pull Marp directives out of a slide. Non-underscore ones persist ('sticky')."""
    local = {}
    for underscore, key, value in DIRECTIVE_RE.findall(chunk):
        value = value.strip().strip('"').strip("'")
        if underscore:
            local[key] = value
        else:
            sticky[key] = value
            local.setdefault(key, value)
    merged = dict(sticky)
    merged.update(local)
    return merged, COMMENT_RE.sub("", chunk).strip()


def scope_style(css):
    """Rewrite the deck's `section.foo` rules to target our `.slide.foo` cards.

    Bare `section {}` rules (font sizes tuned for a 1280px stage) are dropped —
    they are exactly what makes the deck unreadable on a phone.
    """
    css = re.sub(r"(^|\})\s*section\s*\{[^}]*\}", r"\1", css, flags=re.M)
    return SECTION_RULE_RE.sub(lambda m: f"{m.group(1)} .slide{m.group(2)}", css)


def render_breadcrumb(raw):
    """`**Active** > Other > Other` -> HTML, bolding the active crumb."""
    if not raw.strip():
        return ""
    parts = [p.strip() for p in raw.split(">")]
    out = []
    for p in parts:
        m = re.fullmatch(r"\*\*(.+?)\*\*", p)
        if m:
            out.append(f'<strong>{html.escape(m.group(1))}</strong>')
        else:
            out.append(html.escape(p))
    return '<nav class="crumb">' + '<span class="sep">›</span>'.join(out) + "</nav>"


CSS = """
:root{color-scheme:light dark;--bg:#0b0f17;--card:#fff;--ink:#1a2230;--muted:#5b6779;--rule:#e4e8ee;--accent:#2563eb}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--bg);color:var(--ink);
  font:400 17px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  padding:14px 12px 56px}
.deck{max-width:760px;margin:0 auto}
.slide{background:var(--card);border-radius:14px;padding:22px 20px;margin:0 0 14px;
  box-shadow:0 1px 3px rgba(0,0,0,.28);overflow-wrap:anywhere}
.slide h1{font-size:1.5rem;line-height:1.25;margin:.1em 0 .5em;color:#1e3a5f}
.slide h2{font-size:1.2rem;margin:1em 0 .4em}
.slide h3{font-size:1.02rem;margin:1.1em 0 .3em;color:#334155}
.slide p,.slide li{font-size:1rem}
.slide ul,.slide ol{padding-left:1.25em;margin:.5em 0}
.slide li{margin:.35em 0}
.slide li>ul,.slide li>ol{margin:.25em 0}
.slide blockquote{margin:.9em 0;padding:.6em .9em;border-left:3px solid var(--accent);
  background:rgba(37,99,235,.06);border-radius:0 8px 8px 0;color:#26324a}
.slide blockquote p{margin:.2em 0}
.slide code{font-size:.9em;background:rgba(120,130,150,.14);padding:.12em .35em;border-radius:4px}
.slide pre{overflow-x:auto;background:#0f172a;color:#e2e8f0;padding:12px;border-radius:8px;font-size:.85rem}
.slide pre code{background:none;padding:0;color:inherit}
.slide img{max-width:100%;height:auto;border-radius:8px}
.slide hr{border:0;border-top:1px solid var(--rule);margin:1em 0}
.tw{overflow-x:auto;-webkit-overflow-scrolling:touch;margin:.8em 0}
.slide table{border-collapse:collapse;width:100%;font-size:.92rem}
.slide th,.slide td{border:1px solid var(--rule);padding:8px 10px;text-align:left;vertical-align:top}
.slide th{background:rgba(120,130,150,.09);font-weight:600}
.crumb{font-size:.72rem;letter-spacing:.02em;color:var(--muted);margin:-4px 0 12px;
  text-transform:none;display:flex;flex-wrap:wrap;gap:4px;align-items:center}
.crumb strong{color:var(--accent);font-weight:600}
.crumb .sep{opacity:.45}
.num{float:right;font-size:.72rem;color:#94a3b8;margin:-6px -4px 0 8px}
/* Section dividers / title slide: keep the deck's gradients, invert the text */
.slide.lead h1,.slide.lead h2{text-align:left}
.slide.title-slide,.slide[class*="part-"]{color:#fff;padding:30px 20px}
.slide.title-slide h1,.slide[class*="part-"] h1,
.slide.title-slide h2,.slide[class*="part-"] h2,
.slide.title-slide h3,.slide[class*="part-"] h3{color:#fff}
.slide.title-slide .crumb,.slide[class*="part-"] .crumb{display:none}
.slide.title-slide .num,.slide[class*="part-"] .num{color:rgba(255,255,255,.55)}
.slide.title-slide strong,.slide[class*="part-"] strong{color:#fff}
.slide.title-slide h1{font-size:1.9rem}
.top{max-width:760px;margin:0 auto 14px;display:flex;justify-content:space-between;
  align-items:center;gap:10px;color:#8b97a8;font-size:.78rem}
.top a{color:#cbd5e1;text-decoration:none;background:rgba(255,255,255,.09);
  padding:7px 11px;border-radius:7px;white-space:nowrap}
@media (max-width:420px){
  body{font-size:16px;padding:10px 8px 48px}
  .slide{padding:18px 15px;border-radius:12px}
  .slide h1{font-size:1.35rem}
  .slide.title-slide h1{font-size:1.6rem}
}
@media (prefers-color-scheme:dark){
  :root{--card:#161d29;--ink:#dde3ec;--muted:#8b97a8;--rule:#2b3444;--accent:#60a5fa}
  .slide h1{color:#93c5fd}
  .slide h3{color:#b8c2d0}
  .slide blockquote{color:#c9d3e0;background:rgba(96,165,250,.08)}
  .slide th{background:rgba(255,255,255,.05)}
}
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("-o", "--output", required=True)
    ap.add_argument("--slideshow-href", default="", help="link back to the desktop slideshow (e.g. ./)")
    ap.add_argument("--title", default="")
    args = ap.parse_args()

    text = open(args.source, encoding="utf-8").read()
    _, style_css, chunks = split_source(text)

    # breaks=True matches Marp Core: a single newline is a line break, not a space
    md = (
        MarkdownIt("commonmark", {"html": True, "linkify": True, "breaks": True})
        .enable("table")
        .enable("strikethrough")
    )

    sticky, cards = {}, []
    title = args.title
    for idx, chunk in enumerate(chunks, 1):
        directives, body = parse_directives(chunk, sticky)
        if not body:
            continue
        if not title:
            m = re.search(r"^#\s+(.+)$", body, re.M)
            if m:
                title = re.sub(r"[*`]", "", m.group(1)).strip()

        classes = ["slide"] + [c for c in directives.get("class", "").split() if c]
        inner = md.render(body)
        # tables need their own horizontal scroll container so the page never scrolls sideways
        inner = re.sub(r"<table>", '<div class="tw"><table>', inner)
        inner = re.sub(r"</table>", "</table></div>", inner)

        crumb = render_breadcrumb(directives.get("header", ""))
        cards.append(
            f'<section class="{" ".join(classes)}">'
            f'<span class="num">{idx}</span>{crumb}{inner}</section>'
        )

    title = title or "Deck"
    top = f'<div class="top"><span>{html.escape(title)}</span>'
    if args.slideshow_href:
        top += f'<a href="{html.escape(args.slideshow_href)}">Slideshow ↗</a>'
    top += "</div>"

    out = (
        "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\">"
        '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
        f"<title>{html.escape(title)}</title>"
        f"<style>{CSS}{scope_style(style_css)}</style></head><body>"
        f'{top}<main class="deck">{"".join(cards)}</main></body></html>'
    )
    open(args.output, "w", encoding="utf-8").write(out)
    print(f"{args.source} => {args.output} ({len(cards)} slides)", file=sys.stderr)


if __name__ == "__main__":
    main()
