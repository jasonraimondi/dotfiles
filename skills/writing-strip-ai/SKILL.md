---
name: writing-strip-ai
description: Strip AI-sounding patterns out of a draft so it reads like a human wrote it, not a chatbot. Use whenever the user asks to "humanize", "make this sound less AI", "remove AI tells", "edit this", "remove emdashes", or pastes a draft and asks for editing help. Also use for Slack messages, GitHub PR comments, or any external-facing writing where AI tells would be embarrassing.
---

## Ethos

Good writing sounds like a person talking, not a chatbot performing. The goal is to make the reader feel like a peer, not a student. Say the thing. Don't frame the thing you're about to say. Specifics win over abstractions. The reader is smart and doesn't need setup.

## Voice principles

- Start with the observation, not the setup.
- Say the thing. Don't announce that you're about to say it.
- One idea per sentence. Let short sentences do the work, but not every sentence needs to be short.
- Lowercase and contractions are fine. They're how people talk.
- Specifics over abstractions. Numbers, names, what actually happened.
- The reader is smart. No throat-clearing.

## Hard rules

- No em dashes. Use commas, parentheses, or two sentences.
- No italics for emphasis.
- No corporate AI vocabulary (banned word list in the pattern catalog below).
- No sycophantic openers ("Great question," "I'd be happy to").
- No boilerplate closers ("let me know if you have questions," "looking forward to hearing your thoughts").
- No curly quotes or title case headings.
- No emoji decoration in headers or bullets.

## Audiences and tone shifts

- Internal Slack: terse, lowercase, assumes context, no setup
- LinkedIn / external: more framing allowed, but no thought-leader cosplay
- Long-form (essays, case studies): more range allowed, every sentence still earns its place

## Anti-voice

Avoid sounding like: a LinkedIn influencer coached by ChatGPT. A consultant deck. A motivational speaker. Anyone who uses "let's unpack" without irony. The "thought leader" register where every observation is packaged as a profound insight. Writing that takes itself too seriously.

## AI pattern catalog

Edit these out.

- **High-frequency AI vocabulary:** delve, tapestry, pivotal, underscore, intricate, leverage, robust, holistic, seamless, ecosystem (figurative), navigate (figurative), foster, garner, embark, crucial, vital, align with, showcase, harness
- **Significance inflation:** "marks a pivotal moment," "stands as a testament," "underscores the importance," "in today's evolving landscape"
- **Promotional puffery:** nestled, vibrant, must-visit, renowned, boasts, groundbreaking, cutting-edge, world-class
- **Participle tails:** sentences ending in "...emphasizing its importance," "...highlighting the interplay," "...ensuring success"
- **Vague attributions:** "experts argue," "studies show" without naming a source
- **Negative parallelism:** "not just X, but Y" used as a reflex
- **Rule of three:** three-item lists where two or one would land harder
- **Copula avoidance:** "serves as," "stands as," "represents a" instead of "is" or "has"
- **Hedging stacks:** "could potentially possibly"
- **Authority tropes:** "the real question is," "at its core," "fundamentally"
- **Signposting:** "let's dive in," "here's what you need to know"
- **Sycophantic openers:** "Great question," "Of course," "I'd be happy to"
- **Boilerplate closers:** "let me know if you have questions," "looking forward to hearing your thoughts"
- **Empty-label bullets:** inline-header bullets where the label is just restated in the content
- **Formatting tells:** curly quotes, title case headings, emoji in headers or bullets

## Additional AI patterns

Patterns that are hard to unsee once you start looking. Apply universally.

**The speech cadence.** AI defaults to a rhythm pulled from speech transcripts. Short sentence. Another short sentence. Another. Each one on its own line, performative, the whole thing reading like a TED talk script even when the topic is a status update. Makes mundane points sound dramatic. Fix: combine sentences and let the paragraph breathe.

**Rhetorical question setups.** "Here's the thing." "But the truth?" "Wait until you hear this." AI sets up a fake reveal before saying anything. Fix: just say the thing.

**Fake-weight phrases.** "At its core," "when it comes to," "let's unpack." These show up at the start of sentences trying to add weight that isn't there. Fix: cut the opener. The sentence usually reads better without it.

**Listicle scaffolding.** "Three lessons I learned." "Five reasons why." AI defaults to numbered structures even when the underlying idea isn't a list. Fix: if the points don't naturally parallel each other, write it as prose.

**The fake reflection opener.** "I've been thinking a lot lately about..." with no actual specifics. Buys time, signals reflection, commits to nothing. Fix: skip the warmup and start with the observation.

**Permission phrases.** "Read that again." "Let that sink in." Dropped after an unremarkable observation to manufacture gravity. The insight doesn't earn the dramatic pause. Fix: cut both. If the observation lands on its own, it lands. If it doesn't, more pauses won't save it.

**ALL-CAPS emphasis.** Capitalizing single words mid-sentence to fake intensity. "We generated MILLIONS in ARR." "I was SO tired." Reads as performative hype instead of earned emphasis. Fix: use the actual number or the actual thing. "$4M in ARR" hits harder than "MILLIONS."

**Reading complexity creep.** AI clusters multi-syllable words and nested dependent clauses in ways that push reading level up. On LinkedIn especially, denser text gets less dwell time and lower reach. Fix: shorter words, shorter sentences, fewer clauses per sentence. Aim for prose a 9th grader could read on a phone.

## Process

1. Read the draft. Identify which patterns and principles are at play.
2. Rewrite. Preserve the writer's phrasing wherever you can.
3. Audit: "What still sounds AI? What still doesn't sound like the writer?"
4. Revise once more.
5. Deliver.

## Critical principle

If the user pastes their own writing and asks for editing, the smallest edit that removes the AI tells and lands on the voice is the best edit. Do not rewrite their sentences into your own.

## Output format

Default to delivering only the edited version, in a code block, ready to copy. Skip change summaries unless the user asks for them.
