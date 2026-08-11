# CSS Techniques Guide

> Curated catalog of 62 snippets demonstrating modern CSS replacements for outdated patterns.

> ⚠️ Browser support percentages in rule frontmatter are point-in-time estimates/snapshots and may drift. Verify current support via each rule’s `bcd_id` and `mdn_url` before production recommendations.

## Contents

- [1. Layout & Spacing](#1-layout--spacing)
- [2. Animation & Transitions](#2-animation--transitions)
- [3. Color & Theming](#3-color--theming)
- [4. Typography](#4-typography)
- [5. Selectors & Specificity](#5-selectors--specificity)
- [6. Workflow & Architecture](#6-workflow--architecture)
- [7. Interactive UI](#7-interactive-ui)

## 1. Layout & Spacing

### Gap Instead of Margin Hacks
**Old:** Margin on all children with `:last-child { margin: 0 }` override.
**Modern:** Flexbox/Grid `gap` handles spacing uniformly.
```css
/* Old */
.stack > * { margin-bottom: 16px; }
.stack > *:last-child { margin-bottom: 0; }

/* Modern */
.stack { display: flex; flex-direction: column; gap: 16px; }
```

### Aspect Ratio Without Padding Hack
**Old:** `padding-top: 56.25%` trick with absolute positioned inner.
**Modern:** `aspect-ratio` single property.
```css
/* Old */
.video-wrapper { position: relative; padding-top: 56.25%; }
.video-wrapper > * { position: absolute; inset: 0; }

/* Modern */
.video-wrapper { aspect-ratio: 16 / 9; }
```

### Inset Shorthand
**Old:** Separate top/right/bottom/left declarations.
**Modern:** `inset` shorthand covers all edges.
```css
/* Old */
.overlay { position: absolute; top: 0; right: 0; bottom: 0; left: 0; }

/* Modern */
.overlay { position: absolute; inset: 0; }
```

### Object-Fit for Responsive Images
**Old:** Background-image with `background-size: cover`.
**Modern:** `object-fit: cover` on semantic `<img>`.
```css
/* Old */
.hero { background-image: url(...); background-size: cover; background-position: center; }

/* Modern */
.hero img { width: 100%; height: 100%; object-fit: cover; }
```

### Logical Properties for RTL Support
**Old:** Separate left/right with `[dir="rtl"]` overrides.
**Modern:** Logical properties adapt automatically.
```css
/* Old */
.sidebar { margin-left: 16px; }
[dir="rtl"] .sidebar { margin-left: 0; margin-right: 16px; }

/* Modern */
.sidebar { margin-inline-start: 16px; }
```

### Sticky Positioning
**Old:** JS scroll listeners with getBoundingClientRect.
**Modern:** Pure CSS.
```css
/* Modern */
.header { position: sticky; top: 0; z-index: 10; }
```

### Container Queries
**Old:** Viewport-based media queries.
**Modern:** Component-based container queries.
```css
/* Old */
@media (max-width: 768px) { .card { flex-direction: column; } }

/* Modern */
.card-container { container-type: inline-size; }
@container (width < 400px) { .card { flex-direction: column; } }
```

### Grid Template Areas
**Old:** Float with clearfix or grid line numbers.
**Modern:** Semantic named areas.
```css
/* Modern */
.layout {
  display: grid;
  grid-template-areas:
    "header header"
    "sidebar main"
    "footer footer";
}
.header { grid-area: header; }
.sidebar { grid-area: sidebar; }
```

### Subgrid
**Old:** Child grid repeats parent column definitions.
**Modern:** `subgrid` inherits parent tracks.
```css
/* Modern */
.parent { display: grid; grid-template-columns: 1fr 2fr 1fr; }
.child { display: grid; grid-template-columns: subgrid; grid-column: span 3; }
```

### Scrollbar Gutter
**Old:** `overflow-y: scroll` always or padding hack.
**Modern:** Reserves space without visible scrollbar.
```css
/* Modern */
.content { scrollbar-gutter: stable; }
```

### Auto-Growing Textarea
**Old:** JS measuring scrollHeight on every keystroke.
**Modern:** CSS-only auto-growth.
```css
/* Modern */
textarea { field-sizing: content; min-height: 3lh; }
```

### Stretch Width
**Old:** `width: calc(100% - 40px)` workarounds.
**Modern:** `stretch` fills container respecting margins.
```css
/* Modern */
.full-width { width: stretch; }
```

### Text Box Trim (Optical Centering)
**Old:** Uneven padding with manual tweaking.
**Modern:** Trims leading/trailing whitespace from text.
```css
/* Modern */
.button { text-box: trim-both cap alphabetic; }
```

### Content Visibility (Lazy Rendering)
**Old:** JS IntersectionObserver.
**Modern:** Browser skips rendering off-screen content.
```css
/* Modern */
.card { content-visibility: auto; contain-intrinsic-size: auto 300px; }
```

### Corner Shapes
**Old:** Complex `clip-path: polygon()` coordinates.
**Modern:** `corner-shape` property.
```css
/* Modern */
.card { corner-shape: squircle; border-radius: 20px; }
```

## 2. Animation & Transitions

### Height Auto Transitions
**Old:** JS measuring scrollHeight, setting pixels, transitioning.
**Modern:** Animate to/from `height: auto`.
```css
/* Modern */
:root { interpolate-size: allow-keywords; }
.panel { transition: height 0.3s ease; }
.panel[open] { height: auto; }
```

### Display None Animations
**Old:** JS waiting for transitionend before display:none.
**Modern:** `allow-discrete` handles display transitions.
```css
/* Modern */
.modal {
  transition: opacity 0.3s, display 0.3s;
  transition-behavior: allow-discrete;
}
.modal[hidden] { opacity: 0; display: none; }
```

### Entry Animations
**Old:** requestAnimationFrame adding class after paint.
**Modern:** `@starting-style` triggers entrance animations.
```css
/* Modern */
.toast {
  opacity: 1;
  transition: opacity 0.3s;
  @starting-style { opacity: 0; }
}
```

### Scroll-Linked Animations
**Old:** JS IntersectionObserver with manual transforms.
**Modern:** CSS-only scroll-driven animations.
```css
/* Modern */
.fade-in {
  animation: fadeIn linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
```

### Independent Transform Properties
**Old:** Monolithic `transform` shorthand.
**Modern:** Separate properties animate independently.
```css
/* Old */
.card:hover { transform: translateY(-4px) rotate(2deg) scale(1.05); }

/* Modern */
.card { translate: 0; rotate: 0deg; scale: 1; transition: translate 0.2s, rotate 0.3s, scale 0.2s; }
.card:hover { translate: 0 -4px; rotate: 2deg; scale: 1.05; }
```

### Page Transitions (View Transitions)
**Old:** Barba.js or framework transition libraries.
**Modern:** Native View Transitions API.
```css
/* Modern */
.hero-image { view-transition-name: hero; }
::view-transition-old(hero) { animation: fadeOut 0.3s; }
::view-transition-new(hero) { animation: fadeIn 0.3s; }
```

### Staggered Animations
**Old:** nth-child with hardcoded delay values.
**Modern:** `sibling-index()` auto-calculates.
```css
/* Old */
.item:nth-child(1) { animation-delay: 0.1s; }
.item:nth-child(2) { animation-delay: 0.2s; }

/* Modern */
.item { animation-delay: calc(sibling-index() * 0.1s); }
```

### Scroll State Styling
**Old:** JS scroll listener checking element position.
**Modern:** CSS detects stuck/snapped state.
```css
/* Modern */
@container scroll-state(stuck: top) {
  .header { box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
}
```

### Responsive Clip Paths
**Old:** SVG path() that doesn't scale.
**Modern:** CSS shape() with responsive units.
```css
/* Modern */
.blob { clip-path: shape(from 0% 50%, curve to 100% 50% via 50% 0%, curve to 0% 50% via 50% 100%); }
```

## 3. Color & Theming

### OKLCH Color Space
**Old:** Manual hex values with guessed shades.
**Modern:** Perceptually uniform — change lightness predictably.
```css
/* Old */
--blue-500: #3b82f6;
--blue-600: #2563eb; /* guessed darker */

/* Modern */
--blue-500: oklch(0.55 0.2 264);
--blue-600: oklch(0.45 0.2 264); /* just lower lightness */
```

### Color Mix
**Old:** Sass `mix($blue, $pink, 60%)`.
**Modern:** Native CSS function.
```css
/* Modern */
.blended { color: color-mix(in oklch, #3b82f6, #ec4899); }
```

### Light-Dark Function
**Old:** Separate media queries duplicating color values.
**Modern:** Single declaration.
```css
/* Old */
:root { --bg: #fff; --text: #111; }
@media (prefers-color-scheme: dark) { :root { --bg: #111; --text: #eee; } }

/* Modern */
:root { color-scheme: light dark; }
.surface { background: light-dark(#fff, #111); color: light-dark(#111, #eee); }
```

### Accent Color
**Old:** `appearance: none` rebuilding form controls from scratch.
**Modern:** Tint native controls.
```css
/* Modern */
input[type="checkbox"], input[type="radio"] { accent-color: #7c3aed; }
```

### Relative Color Syntax
**Old:** Sass `lighten()`/`darken()` functions.
**Modern:** Derive variants from a base color.
```css
/* Modern */
.lighter { color: oklch(from var(--brand) calc(l + 0.2) c h); }
.more-saturated { color: oklch(from var(--brand) l calc(c * 1.5) h); }
```

### Wide Gamut Colors (Display-P3)
**Old:** Limited sRGB gamut.
**Modern:** Vivid Display-P3 colors.
```css
/* Modern */
.vivid { color: color(display-p3 1 0.2 0.1); }
```

### Color Scheme
**Old:** Media query styling form controls for dark mode.
**Modern:** Browser handles it automatically.
```css
/* Modern */
:root { color-scheme: light dark; }
```

### Backdrop Filter (Frosted Glass)
**Old:** Pseudo-element with blurred background image.
**Modern:** Single property.
```css
/* Modern */
.glass { backdrop-filter: blur(12px); background: rgba(255,255,255,0.1); }
```

## 4. Typography

### Balanced Text Wrap
**Old:** Manual `<br>` or Balance-Text JS library.
**Modern:** Browser distributes words evenly.
```css
/* Modern */
h1, h2, h3 { text-wrap: balance; }
p { text-wrap: pretty; } /* prevents orphans */
```

### Fluid Typography
**Old:** Multiple media query breakpoints.
**Modern:** Smooth scaling with clamp().
```css
/* Old */
h1 { font-size: 2rem; }
@media (min-width: 768px) { h1 { font-size: 3rem; } }

/* Modern */
h1 { font-size: clamp(2rem, 1rem + 2.5vw, 3.5rem); }
```

### Line Clamp (Multiline Truncation)
**Old:** JS character counting with manual ellipsis.
**Modern:** CSS-only truncation.
```css
/* Modern */
.excerpt { display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
/* Future: line-clamp: 3; */
```

### Font Display
**Old:** Invisible text during font load.
**Modern:** Show fallback immediately.
```css
/* Modern */
@font-face { font-family: "Custom"; src: url(...); font-display: swap; }
```

### Variable Fonts
**Old:** Separate @font-face per weight.
**Modern:** One file, infinite weights.
```css
/* Modern */
@font-face { font-family: "Inter"; src: url("inter-variable.woff2"); font-weight: 100 900; }
.bold { font-weight: 650; } /* any value in range */
```

### Drop Caps
**Old:** Float hack with fragile line-height.
**Modern:** Single property.
```css
/* Modern */
.article > p:first-of-type { initial-letter: 3; }
```

## 5. Selectors & Specificity

### :has() Parent Selector
**Old:** JS `closest()` traversing DOM.
**Modern:** Select parent based on children.
```css
/* Modern */
.card:has(img) { grid-template-rows: auto 1fr; }
.form:has(:invalid) .submit { opacity: 0.5; pointer-events: none; }
```

### :focus-visible
**Old:** `:focus` showing outlines on mouse click.
**Modern:** Keyboard-only focus styles.
```css
/* Modern */
button:focus-visible { outline: 2px solid var(--focus-ring); outline-offset: 2px; }
```

### :where() Zero Specificity
**Old:** Verbose selectors for resets.
**Modern:** Zero-specificity wrapper.
```css
/* Modern */
:where(ul, ol) { list-style: none; padding: 0; margin: 0; }
:where(h1, h2, h3, h4) { margin: 0; }
```

### :is() Selector Grouping
**Old:** Repeating parent for each child selector.
**Modern:** Group selector lists.
```css
/* Old */
.card h1, .card h2, .card h3 { margin-bottom: 0.5em; }

/* Modern */
.card :is(h1, h2, h3) { margin-bottom: 0.5em; }
```

### :user-invalid Form Validation
**Old:** JS adding `.touched` class on blur.
**Modern:** Styles only after user interaction.
```css
/* Modern */
input:user-invalid { border-color: red; }
input:user-valid { border-color: green; }
```

### :target-current Scroll Spy
**Old:** 15+ lines of IntersectionObserver JS.
**Modern:** CSS highlights current section.
```css
/* Modern */
.nav a:target-current { color: var(--accent); font-weight: bold; }
```

### @layer Cascade Control
**Old:** Specificity wars with `!important`.
**Modern:** Explicit cascade ordering.
```css
/* Modern */
@layer base, components, utilities;
@layer base { a { color: blue; } }
@layer utilities { .text-red { color: red; } } /* always wins over base */
```

## 6. Workflow & Architecture

### Native CSS Nesting
**Old:** Sass/Less required for nesting.
**Modern:** Native support.
```css
/* Modern */
.card {
  padding: 16px;
  & .title { font-size: 1.25rem; }
  &:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
}
```

### @scope
**Old:** BEM naming (.card__title) or CSS Modules.
**Modern:** Native scope boundaries.
```css
/* Modern */
@scope (.card) to (.card-footer) {
  .title { font-size: 1.25rem; }
  .description { color: gray; }
}
```

### Custom Properties (Runtime Variables)
**Old:** Sass $variables compiled to static values.
**Modern:** Live runtime variables.
```css
/* Modern */
:root { --primary: oklch(0.55 0.2 264); --radius: 8px; }
.button { background: var(--primary); border-radius: var(--radius); }
```

### @property (Typed Custom Properties)
**Old:** String custom properties can't animate.
**Modern:** Typed properties enable interpolation.
```css
/* Modern */
@property --hue {
  syntax: "<angle>";
  inherits: false;
  initial-value: 0deg;
}
.gradient { --hue: 0deg; background: oklch(0.7 0.15 var(--hue)); transition: --hue 0.5s; }
.gradient:hover { --hue: 180deg; }
```

### Native CSS Functions
**Old:** Sass @function / @mixin requiring compilation.
**Modern:** Native CSS @function.
```css
/* Modern (experimental) */
@function --fluid-size(--min, --max) {
  @return clamp(var(--min), calc(var(--min) + (var(--max) - var(--min)) * (100vw - 320px) / 1280), var(--max));
}
h1 { font-size: --fluid-size(2rem, 4rem); }
```

### Inline Conditionals
**Old:** JS class toggling with if/else.
**Modern:** CSS if() conditionals.
```css
/* Modern (experimental) */
.button {
  background: if(style(--variant: primary): var(--blue); else: var(--gray));
}
```

### Typed Attribute Values
**Old:** JS reading dataset and applying to styles.
**Modern:** attr() with type coercion.
```css
/* Modern (experimental) */
.progress-bar { width: attr(data-pct type(<percentage>)); }
```

### Range Style Queries
**Old:** Multiple @container style() blocks.
**Modern:** Range comparisons in style queries.
```css
/* Modern (experimental) */
@container style(--progress > 50%) { .bar { background: green; } }
```

## 7. Interactive UI

### Native Dialog
**Old:** Custom modal with z-index, ESC handling, focus trap.
**Modern:** `<dialog>` with built-in behavior.
```css
/* Modern */
dialog::backdrop { background: rgba(0,0,0,0.5); }
dialog[open] { animation: fadeIn 0.2s ease; }
```

### Popover (Dropdowns)
**Old:** JS display toggle with click-outside listener.
**Modern:** Native popover behavior.
```html
<button popovertarget="menu">Menu</button>
<div id="menu" popover>...</div>
```

### Popover Hints (Tooltips)
**Old:** JS mouseenter/mouseleave with positioning.
**Modern:** Native tooltip behavior.
```html
<button interestfor="tip">Hover me</button>
<div id="tip" popover="hint">Tooltip text</div>
```

### CSS Anchor Positioning
**Old:** Popper.js / Floating UI computing coordinates.
**Modern:** CSS-only positioning relative to anchor.
```css
/* Modern */
.trigger { anchor-name: --btn; }
.tooltip { position-anchor: --btn; inset-area: top; }
```

### Scroll Snap
**Old:** Swiper/Slick carousel with JS touch handlers.
**Modern:** CSS-only snap behavior.
```css
/* Modern */
.carousel { scroll-snap-type: x mandatory; overflow-x: auto; display: flex; }
.slide { scroll-snap-align: start; flex: 0 0 100%; }
```

### Scroll Buttons & Markers
**Old:** Carousel library with prev/next buttons and pagination.
**Modern:** Native pseudo-elements.
```css
/* Modern */
.carousel::scroll-button(inline-start) { content: "←"; }
.carousel::scroll-button(inline-end) { content: "→"; }
.carousel .slide::scroll-marker { content: "●"; }
```

### Custom Select (appearance: base-select)
**Old:** Select2 or Choices.js rebuilding entire DOM.
**Modern:** Style native selects.
```css
/* Modern */
select { appearance: base-select; }
select::picker(select) { background: white; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
```

### Dialog Commands
**Old:** Inline onclick with querySelector.
**Modern:** Declarative triggers.
```html
<button commandfor="my-dialog" command="show-modal">Open</button>
<dialog id="my-dialog">
  <button commandfor="my-dialog" command="close">Close</button>
</dialog>
```

### Light Dismiss
**Old:** JS click event checking element bounds.
**Modern:** Attribute handles it.
```html
<dialog closedby="any">...</dialog>
```
