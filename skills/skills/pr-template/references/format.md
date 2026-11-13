# PR body format

Reference for the build step of the pr-template skill. The diff shows implementation detail. The body gives the reviewer the missing frame: **why this matters, what changed, and what consequences follow**. Keep it compact by removing low-value facts, not by compressing useful ideas into clipped prose.

## Language

Use the ubiquitous language in `GLOSSARY.md` when that file exists. The mandatory Unslop pass in step 7 governs punctuation, diction, rhythm, voice, and structure.

Write natural, connected prose. Give each sentence one clear job, but use enough words to show cause and effect. Write each paragraph and each bullet as one unbroken line and let GitHub soft-wrap it. Newlines separate paragraphs, bullets, and headings.

## Length

A reviewer reads the body once before opening the diff, so it should be short enough to read in one pass. A typical PR needs a short paragraph for `Why`, a sentence or two for `What changed`, and two labelled `Risk` bullets. A body earns more length when the PR has several distinct behaviors, a migration or rollout, a breaking contract, cross-system effects, or risks that reviewers must evaluate. Diff size alone does not justify more prose. Every added sentence must answer a concrete reviewer question that a shorter version leaves open.

Compression removes content. It does not join discarded facts into dense compound sentences. Keep the causal chain, behavioral changes, strongest test evidence, material scope boundaries, and required human actions. Drop secondary implementation detail, exhaustive cases, repeated consequences, unchanged behavior, and facts a reviewer can read directly from the diff.

Never cut information needed to review or ship the change safely, and never preserve a detail by making another sentence harder to read.

## Sections

Use these sections in this order. Every optional section waits for its trigger.

**`## Stack`** — Only when `baseRefName` is not `main`/`master`, or the body or commits say "stacked on", "depends on", "split out of". First position: merge order is the reviewer's most urgent context. Use one framing sentence and usually no more than 2 bullets — what it is **stacked on** (the PR number, the merge order) and any **sibling PR** split from the same branch. Note that GitHub retargets this PR to the default branch once the parent merges.

**`## Why`** — Every PR. Explain the failure, need, or goal before the change. Trace the causal chain far enough that a reviewer understands both the mechanism and the user or operational consequence. The ticket ID sits in the title; this section carries the reason itself, readable without opening the ticket. Keep implementation changes out of this section.

**`## What changed`** — Every PR. State the approach in 1–3 sentences. When the change has several distinct behaviors, follow with plain bullets: each describes one coherent behavior, contract, or decision and explains its important consequence, ordered along the runtime or user flow when one exists. When the change is structural — a new call path, a moved module boundary, a changed component or file layout — open the section with a shape sketch (see "Shape sketches") and keep the prose for the consequences the sketch cannot show. Two things join this section only when they exist: a rejected alternative the author recorded in the original body, carried in their words with the reason it lost, and a scope boundary that would surprise a reviewer, as one sentence naming what remains and where it is tracked.

**`## Breaking changes`** — Only when the diff shows one: removed public exports, changed public signatures, renamed or removed endpoints, removed CLI flags, schema removals, a major version bump, or a `BREAKING:` marker. State what breaks and how callers migrate.

**`## How to verify`** — Include for code changes when the diff or existing body provides a way to check them. Evidence ranks in tiers. Lead with the highest tier the PR holds, and state a result only where the original body or a commit records the run.

1. **S-tier: before-and-after screenshots or video** for a visual change. They live in `## Screenshots`; here, one bullet names what the pair shows.
2. **A-tier: before-and-after execution output** recorded by the author: the exact test or command that failed and now passes, or output captured on each side.
3. **B-tier: a path to run**: the test file, command, or click-through step paired with the behavior it proves, covering the main success case and the highest-risk boundary. Combine related assertions.

**`## Risk`** — Every code change. Two labelled bullets. `**Door:**` is `one-way` or `two-way`: a change that a revert fully undoes is a two-way door; a destructive migration, a wire format consumers adopt on sight, or a decision that is hard to reverse once data flows through it is a one-way door. `**Blast radius:**` is a short phrase naming the widest thing that breaks if the change is wrong: a query's callers, layout on every page, each consumer of a schema. Add a second sentence to either bullet only when the label alone would mislead. Blockers follow under `**Before merge:**` when the diff produces any. See "Blockers".

**`## Screenshots`** — Only when the original body already holds images or video links. Carry them through unchanged, at the bottom. Generate nothing here.

Keep the section set small by omitting optional sections, not by collapsing distinct reviewer questions into one paragraph. Remove file inventories, low-value implementation trivia, and repeated facts. Spend words where they add insight, then stop.

Name collaborators in assignees. Write any `@`-mention from the original body as plain text — GitHub re-notifies mentioned users on every edit.

## Shape sketches

A sketch shows the shape of a structural change in fewer words than bullets can. Pick the smallest view that makes the point, place it right after the sentence it supports, and cut every call, file, prop, or state the reviewer does not need. One sketch is usual, several is rare, and all of them is never.

- Logic or an algorithm as pseudocode.
- Runtime control flow as a call tree.
- UI structure as a component tree, marking the state hooks and module boundaries that matter.
- File responsibility or a broad refactor as a shallow file tree with one comment per entry.
- Component interaction or data flow as a Mermaid `sequenceDiagram`.
- A change to any of these as a `diff` of that shape, when the surrounding structure already exists and the point is what moved.
- The whole block as code when most of it is new, when omitted context would hide ownership or order, or when the reviewer needs a copyable target shape.

A component tree:

```text
<SessionPage>                 apps/example/src/routes/session.tsx
  useSessionEvents()
  <SessionToolbar>
    <RunSkillButton>          packages/ui
```

A data-flow sketch:

```mermaid
sequenceDiagram
    participant User
    participant UI
    participant Daemon
    User->>UI: choose command
    UI->>Daemon: send expanded prompt
    Daemon-->>UI: stream result
```

A call-tree diff:

```diff
 submitForm
   createSession
     persistPrompt
+    expandSkillMention
     launchAgent
   navigateToSession
+    subscribeToEvents
```

A file-layout diff:

```diff
 src/
 ├── commands/
+│   └── show-me.ts       # expands the slash command
 ├── sessions/
-└── transport.ts
+└── transport/
+    ├── client.ts
+    └── stream.ts
```

A control-flow diff:

```diff
 on(save)
-  write content
+  if content is unchanged
+    return cached result
+  write new content
+  invalidate cache
```

## Blockers

A blocker is a human action this diff makes necessary before merge, where skipping it breaks a deploy, loses data, or breaks a consumer. Blockers close `## Risk` as a GitHub task list under a `**Before merge:**` line, all unchecked.

Test every candidate by finishing the sentence "if this merges with the box unchecked, ___ breaks." A candidate with a concrete answer is a blocker. Every other candidate has a home elsewhere: a step that confirms the change works belongs in `## How to verify`, a gap in the diff belongs in the report, and anything CI proves needs no mention.

Where blockers usually come from:

| Signal in the diff                                              | Blocker                                                                  |
| --------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Files under `migrations/`, `db/migrate/`, `schema/`, `*.sql`     | Migration run against a production-sized dataset; rollback path verified |
| Schema or wire-format change with consumers outside this repo    | Backward compatibility confirmed with downstream consumers               |
| New env vars or config keys the code reads without a default     | Values set in staging and production                                     |

A signal is a place to look, and the test decides. Word each blocker to name the actual change: "Migration tested against a production-sized dataset (drop index is a safe rollback)". Most PRs have no blockers, and then `**Before merge:**` is omitted.

## Worked examples

### Example 1 — the typical PR

**Input:** Body mentions `PROJ-892`. Diff: one query rewrite in `reports/queries.ts` plus coverage in `reports/queries.test.ts` for large workspaces and result ordering. No migration, no UI, no public API change.

**Output title:** `fix(reports): PROJ-892 rewrite dashboard query to use the events index`

**Output body:**
```markdown
## Why
Reports become unusable for large workspaces because the dashboard sorts every event in memory and times out.

## What changed
The dashboard query reads from the existing `events(workspace_id, created_at)` index, which removes the in-memory sort while keeping the current reporting path.

## How to verify
- `reports/queries.test.ts` proves a large-workspace report completes with the indexed query and keeps the existing result order.

## Risk
- **Door:** two-way. A revert restores the in-memory sort.
- **Blast radius:** dashboard report results in every workspace.
```

That is the whole body. Each section answers one reviewer question. A query rewrite has one behavior, so `What changed` stays a sentence and has no shape worth sketching. No migration files means no blockers, and no contract change means no `Breaking changes`.

### Example 2 — a larger PR

**Input:** Branch `feature/oauth-pkce`, base `feature/oauth-be`, commits reference `PROJ-456`. Diff adds an authorization code path with tests in `auth/pkce.test.ts`, modifies the `/oauth/authorize` handler, removes the ability to call it without a code challenge, and adds an `OAUTH_PKCE_REQUIRED` env var. Existing public clients migrate in separate repositories.

**Output title:** `feat(auth)!: PROJ-456 add OAuth2 PKCE flow`

**Output body:**
````markdown
## Stack
Client half of the PKCE work, split from the combined branch.
- **Stacked on #4666.** This PR uses its token-exchange contract. Merge #4666 first. GitHub then retargets this PR to `main`.

## Why
An intercepted redirect can expose an authorization code from a public OAuth2 client. An attacker can use that code because nothing binds it to the client that started the request.

## What changed
```diff
 /oauth/authorize
+  requireCodeChallenge
 /oauth/token
+  verifyCodeVerifier
+  verifyClientSecret
```
Authorization and token exchange now enforce PKCE behind a flag. Existing public clients adopt the challenge in their own repositories.
- Require a PKCE challenge on each authorization request.
- Verify the matching client secret during token exchange.
- Gate enforcement with `OAUTH_PKCE_REQUIRED` while public clients migrate.

## Breaking changes
`/oauth/authorize` rejects requests without a `code_challenge`. Public clients must send one before enforcement, or they get `400 invalid_request`.

## How to verify
- `auth/pkce.test.ts` proves authorization accepts a valid challenge and verifier pair.
- The same file proves token exchange rejects a missing or mismatched verifier.

## Risk
- **Door:** two-way while `OAUTH_PKCE_REQUIRED` is off. Turning it on rejects every client that has not migrated, and turning it back off is the rollback.
- **Blast radius:** every public OAuth client that has not adopted PKCE.

**Before merge:**
- [ ] `OAUTH_PKCE_REQUIRED` set in staging and production before deploy
````

The body separates the security failure, implementation, compatibility break, verification, and rollback story. The call-tree diff shows where enforcement lands, and the bullets carry the consequences the sketch cannot. The scope boundary is one sentence in `What changed`. The env var is a blocker because a deploy without it reads an unset value. The missing API documentation goes in the report.
