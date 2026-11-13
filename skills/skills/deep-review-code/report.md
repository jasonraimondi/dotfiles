# Report

One report shape for every mode, and one **finding anatomy** for every reviewer. A reviewer dispatched by a mode returns its findings in this anatomy, whatever template its lens file carries.

## Shape

```
# Review: <PR #n "title" | <branch> → <base> | scope description>

Scope: `<diff command>` (head `<sha>`, <n> commits), <n> files, +<added>/-<removed>. <How the code was read. What was run, and what was not.>
Reviewers: <axes that ran>. <Each axis that skipped or failed, with its reason.>

## Verdict

**<Approve | Approve with comments | Request changes>.**

<One paragraph. What is sound, then what blocks, by finding ID. For a PR, the CI and merge state.>

## Summary

- <What the change does, one behaviour per bullet, each with its `file:line`.>

## Engineering

**<Overengineered | Underengineered | Perfectly engineered>.** <One or two sentences, resting on finding IDs.>

## Findings

### Blocker

**B1. <The defect and its consequence, as one sentence.>**

Location: `<file:line>` (<what is there>), `<file:line>` (<what is there>).

- **What is wrong.** <The mechanism, step by step, each step cited.>
- **Scenario.** <A concrete sequence of actors, values, and times that ends in the wrong outcome.>
- **Why it matters.** <Who feels it. Whether this change introduces it.>
- **Suggested fix.** <The change to make, and the test that pins it.>

### Major

**M1. <…>**

### Minor

**m1. <…>**

### Nit

**n1. <Title.>** `<file:line>`: <the problem and the fix, in a few sentences>.

## Open questions for the author

1. <Question.> (B1)

## Could not verify

- <The claim or check, and why it stayed unverified.>
```

## Sections

- **Verdict comes first.** A reader who stops after that paragraph knows whether to merge and why. Any blocking finding makes it *Request changes*; Minor findings alone make it *Approve with comments*.
- **Summary describes the code, read from the diff.** Where the PR description or commit message claims something the code does otherwise, that difference is a finding.
- **Engineering rates the size of the solution against the size of the problem** (see *Engineering rating*).
- **Findings are one list, ranked by severity.** Number them within each severity (`B1`, `M1`, `m1`, `n1`) so the verdict and the questions can cite them. Omit a severity with no findings; with none at all, *Findings* reads `None.`
- **Open questions are for what only the author or the product owner can answer**: intent, sign-off, rollout order, what a flag is set to in production. A question the code can answer is legwork still owed.
- **Could not verify appears in every report.** It lists each thing the review leans on without having confirmed it: suites not run, a path not traced to its end, CI that never started, a claim resting on a reading of code that no test exercises.

## Finding anatomy

- **Title** — a full sentence carrying the defect and its consequence: "A leftover cancellation job can remove a module early after a revoke and re-grant", where "Job handling issue" says nothing.
- **Location** — every site the argument rests on, each with a note on what lives there. Unchanged code belongs here when the change is what makes it wrong.
- **What is wrong** — the mechanism, traced through the code, a citation on each step.
- **Scenario** — for a finding about behaviour: a sequence with real actors, values, and times, walked to the wrong outcome. "Granted for 14 days, revoked on day 3, re-granted for 30 days on day 5; on day 14 the first job fires and removes it 21 days early." A behavioural finding whose scenario will not come together goes under *Could not verify*.
- **Why it matters** — who feels it and how. Say whether the change introduces the problem or widens one that existed; that is what makes it this review's finding.
- **Suggested fix** — the smallest change that fixes it; a fix that adds more structure than the defect needs is overengineering the review introduced. Where there are alternatives, label them (a), (b), say which one fixes the root cause and what the others leave uncovered, and name the test case that would pin the fix.

Blocker and Major findings carry the full anatomy. A Minor carries *What is wrong*, *Why it matters*, and *Suggested fix*. A Nit is one paragraph.

## Severity

- **Blocker** — merging causes harm: wrong behaviour that users or data will feel, data loss, a security hole, a contract with callers broken.
- **Major** — blocks the merge without being live harm: a recorded decision reversed without amending the record, a promise descoped, a test that would not catch a regression on a risky path.
- **Minor** — real and worth fixing, safe to merge without: an unlikely edge, a field that implies behaviour that does not happen, a silent failure that deserves a log, rationale deleted.
- **Nit** — placement, duplication, wording.

**Blocking** means Blocker or Major. The lens files say which findings are blocking; choose between the two by whether the harm is live.

A finding from the `modularity` lens is a Minor at most, whatever bucket `mdlr` gave it.

## Engineering rating

One rating for the whole change:

- **Overengineered** — more solution than problem: speculative abstraction, flexibility nothing uses, premature generalization, error handling for cases that cannot happen, an extraction or layer with a single caller.
- **Underengineered** — less solution than problem: missing validation at a real boundary, a risky path with no test, an edge case ignored, a shortcut that will break.
- **Perfectly engineered** — the scope matches the problem: no speculative scaffolding, no missing safeguard.

Each reviewer ends its return with `Engineering: over | under | right — <reason, with its `file:line`>`, judged through its own lens. The rating is set at assembly from those lines and the findings. A change that is over in one place and under in another takes the rating of the larger problem, and the sentence names the other.

The rating cuts both ways on structure. A high `mdlr` number is evidence of underengineering only when the code is hard to change as it stands; a split made to satisfy the number is overengineering.

## Prose

Plain sentences, one claim each: state what the code does, cite it, move on. Praise appears only in the verdict paragraph, and only as the specific thing that is sound.
