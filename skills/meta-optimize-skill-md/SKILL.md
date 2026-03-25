---
name: meta-optimize-skill-md
description: Reviews and improves existing skills by auditing clarity, trigger quality, workflow completeness, and instruction density, then rewriting SKILL.md with minimal-drift improvements. Use when user asks to improve a skill, review SKILL.md, optimize skill prompts, tighten skill descriptions, or refactor skill documentation.
---

# Optimize Existing Skills

Improve existing skills by preserving intent while making `SKILL.md` clearer, easier to trigger, and more execution-ready.

## When to use

Use this skill when the user asks to:

- improve an existing skill
- review or rewrite `SKILL.md`
- optimize skill trigger descriptions
- reduce ambiguity in skill instructions
- tighten or refactor skill documentation

## Required workflow

1. **Locate and read** the target `SKILL.md` fully.
2. **Map current intent** in 3-6 bullets before editing.
3. **Audit quality** using the rubric below.
4. **Propose changes** grouped as:
   - keep (already strong)
   - tighten (wording/structure)
   - add (missing critical guidance)
   - remove (noise/redundancy)
5. **Rewrite with minimal drift**:
   - keep core behavior and scope
   - improve wording, ordering, and actionability
   - avoid introducing new product/domain claims
6. **Return both**:
   - concise review summary
   - improved `SKILL.md` content (or patch-ready diff)

## Optimization rubric

### 1) Frontmatter quality

- `name` is stable and slug-safe
- `description` clearly states capability + trigger contexts
- Trigger language includes realistic user phrases
- Description remains concise and specific

### 2) Trigger precision

- Skill should be discoverable from common user wording
- Trigger list avoids over-broad claims
- Adjacent skills are not duplicated without need

### 3) Instruction quality

- Steps are explicit, ordered, and observable
- Ambiguous phrases replaced with concrete actions
- “Do this first” constraints are clearly marked
- Safety/guardrail rules are easy to spot

### 4) Information architecture

- Most important guidance appears early
- Long sections are chunked with headings/lists
- Optional/advanced material is separated from core flow

### 5) Token efficiency

- Remove repeated ideas
- Prefer short, directive sentences
- Keep examples only when they reduce ambiguity

## Rewrite standards

- Preserve original intent and scope unless user asks to expand
- Prefer minimal-diff edits over full rewrites
- Keep voice imperative and implementation-oriented
- Use checklists for repeatable procedures
- Keep claims timeless (avoid version/date-sensitive phrasing)

## Output format

1. **Audit summary** (strengths, gaps, risks)
2. **Optimization plan** (what changed and why)
3. **Improved `SKILL.md`**
4. **Open questions** (if any assumptions remain)

## Anti-patterns

- Rewriting into a different skill/domain
- Adding verbose theory with no execution value
- Removing trigger phrases that aid discovery
- Making the skill longer without improving clarity
- Introducing tools/workflows not available in the environment
