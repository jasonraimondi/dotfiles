# Research: TypeScript skill consolidation

## Scope

This brief evaluates the proposed consolidation in the handoff document: make `vendor-auto/typescript-magician` the single model-invoked TypeScript skill, retain its progressive-disclosure rules, and retire or demote `vendor-auto/typescript-advanced-types` only after the replacement is discoverable.

## Conclusion

`typescript-magician` should become the canonical skill. It already covers the old skill's principal trigger space, provides an operational debugging-and-validation loop, and links to focused rule files rather than placing a large tutorial in every invocation.

The current exposure problem is not its frontmatter. The repository installer recognizes both skills, but the installed catalogue is stale: the current state manifest and `~/.agents/skills/` contain `typescript-advanced-types` but not `typescript-magician`. Register the canonical skill first, prove its discovery, then remove or demote the old skill.

## Primary-source findings

### 1. Discovery and invocation are controlled by `setup.sh`

`setup.sh` defines the three source roots as `skills/`, `vendor/`, and `vendor-auto/`. A direct child directory is a skill if it contains `SKILL.md`. For each discovered skill, the installer creates links in the configured skill targets and records the names in `${XDG_STATE_HOME:-~/.local/state}/jason-skills/synced-skills`.

`vendor-auto/` is explicitly the auto-invoked root: `invocation_policy_for` returns `auto`, and `apply_invocation_policy` removes any `disable-model-invocation` key. Therefore both existing TypeScript skills are model-invoked today, regardless of whether the README lists one of them.

**Source:** [`setup.sh`](../setup.sh), especially `SKILLS_SOURCES`, `SKILLS_TARGETS`, `invocation_policy_for`, `list_skills`, and `sync_skills`.

### 2. The installer knows about `typescript-magician`; the installed catalogue is stale

The current sync manifest includes `typescript-advanced-types` but does not include `typescript-magician`. Likewise, `~/.agents/skills/typescript-advanced-types` is a symlink and the corresponding magician path is absent.

A non-mutating `./setup.sh --dry-run` enumerated and would link **both** skills. Its TypeScript-specific output included:

```text
ln -sfn .../vendor-auto/typescript-advanced-types .../.agents/skills/typescript-advanced-types
ln -sfn .../vendor-auto/typescript-magician .../.agents/skills/typescript-magician
```

So the immediate discoverability issue is an out-of-date installation, not a duplicate name or a `disable-model-invocation` setting. Do not remove the old skill until a real installer run has exposed magician and the active Pi catalogue has been checked.

**Sources:** [`setup.sh`](../setup.sh); `${XDG_STATE_HOME:-~/.local/state}/jason-skills/synced-skills`; the installed `~/.agents/skills/` entries; local `./setup.sh --dry-run` output (run during this research).

### 3. Pi-target documentation disagrees with the current installer

The README says `setup.sh` links skills to `~/.claude/skills/` and `~/.pi/agent/skills/`. The actual `SKILLS_TARGETS` array contains only:

```bash
$HOME/.claude/skills
$HOME/.agents/skills
```

The script does link `AGENT.md` and extensions into `~/.pi/agent/`, but it does not link skill directories there. This needs one explicit decision:

- if `~/.agents/skills` is the intended Pi discovery location, correct the README; or
- if `~/.pi/agent/skills` is the contract, add it to `SKILLS_TARGETS` and test it.

The current session's available-skill list and the live `~/.agents/skills` symlink support the first explanation, but Pi's version-specific discovery path should be confirmed after installation.

**Sources:** [`README.md`](../README.md#install); [`setup.sh`](../setup.sh).

### 4. Coverage overlap is substantial; magician is the more suitable main entry

The old tutorial contains generics, conditional types, mapped types, template-literal types, utilities, `infer`, type guards, discriminated unions, and type tests. Magician's manifest advertises the same type-error and advanced-type work and exposes dedicated references for all major shared areas:

| Area | Old tutorial | Canonical rule coverage | Result |
| --- | --- | --- | --- |
| Generics, constraints, inference | Main tutorial | `generics-basics.md`, `deep-inference.md` | Covered |
| Conditional/distributive types and `infer` | Main tutorial | `conditional-types.md`, `infer-keyword.md` | Covered |
| Mapped/key-remapped and template-literal types | Main tutorial | `mapped-types.md`, `template-literal-types.md` | Covered |
| Utility types and deriving types from values | Main tutorial | `utility-types.md`, `as-const-typeof.md`, `array-index-access.md` | Covered, with more focused references |
| Guards and discriminated-union narrowing | Main tutorial | `type-narrowing.md` | Covered |
| Builder and deep transformation patterns | Main tutorial | `builder-pattern.md`, conditional/mapped rules | Covered |
| Opaque IDs, overloads, diagnosing errors | Not presented as focused references | `opaque-types.md`, `function-overloads.md`, `error-diagnosis.md` | Magician advantage |

All 14 `rules/*.md` files linked by magician's reference index exist; a local link check found no missing relative links.

**Sources:** [`typescript-advanced-types/SKILL.md`](../vendor-auto/typescript-advanced-types/SKILL.md); [`typescript-magician/SKILL.md`](../vendor-auto/typescript-magician/SKILL.md); [`typescript-magician/rules/`](../vendor-auto/typescript-magician/rules/).

### 5. Preserve only real gaps, as references rather than a second main skill

The old tutorial has several material items not currently called out in magician's reference index:

- small compile-time type-test patterns (type equality assertions and `@ts-expect-error` usage);
- cautions about recursive/conditional-type complexity and compile performance;
- application examples for a typed API client, form validation, and a reducer/state machine.

The first two are broadly useful. Add a compact `rules/type-tests.md` and a short complexity note in an existing type-level rule (probably `conditional-types.md` or `mapped-types.md`). Keep the three application examples only if the maintained skill explicitly intends to advise on those designs; otherwise they are tutorial material rather than required invocation guidance.

**Sources:** [`typescript-advanced-types/SKILL.md`](../vendor-auto/typescript-advanced-types/SKILL.md); [`typescript-magician/SKILL.md`](../vendor-auto/typescript-magician/SKILL.md); [`typescript-magician/rules/`](../vendor-auto/typescript-magician/rules/).

### 6. The canonical workflow should be narrowed before promotion

Magician's current instructions assume `tsc --noEmit` is always the right command and require replacing every `any`, explaining theory, presenting multiple solutions, showing before/after representations, and adding comprehensive type tests for every request. Those blanket requirements are too broad:

- repositories may typecheck through a package script, workspace package, project reference, or a non-root `tsconfig`;
- a documented `any` at a genuine interop boundary can be intentional and sounder than a misleading replacement;
- a simple compiler-error repair does not always need multiple approaches or comprehensive type tests.

This repository's skill-authoring guidance supports a concise, reliable process with deeper material behind explicit links.

**Sources:** [`typescript-magician/SKILL.md`](../vendor-auto/typescript-magician/SKILL.md#instructions); [`writing-for-agents/SKILL.md`](../vendor-auto/writing-for-agents/SKILL.md).

## Recommended implementation sequence

1. **Refine the canonical main manifest.** Keep `typescript-magician` as the sole broad TypeScript-type/type-error trigger. Change its workflow to:
   1. inspect `package.json`, workspace layout, and `tsconfig*.json` (or ask if unavailable) to select the narrowest project-native typecheck command;
   2. run it and capture relevant errors;
   3. identify the root cause and load only relevant `rules/*.md` files;
   4. make the smallest sound type change; use `unknown` plus narrowing at untrusted boundaries, while retaining an intentional documented `any` only when appropriate;
   5. rerun the same typecheck and any focused existing test or type-test command.

   Request explanations, alternatives, or explicit type tests only when the user asks, a public/reusable type API changes, or the project already has a type-test harness.

2. **Add only the retained gaps.** Add a small `rules/type-tests.md`, point to it from the manifest, and add a complexity note to a relevant existing rule. Do not transfer the 724-line tutorial into the main skill.

3. **Correct the catalogue and target documentation.** Replace the README's `typescript-advanced-types` row with `typescript-magician` and its task-oriented summary. Resolve the README/installer Pi-target discrepancy explicitly.

4. **Register before retiring.** Run `./setup.sh`, then confirm:
   - the state manifest contains `typescript-magician`;
   - every intended skill target resolves it to `vendor-auto/typescript-magician`;
   - its manifest is not disabled for model invocation; and
   - the active Pi skill catalogue lists it.

5. **Retire the overlapping old skill.** Preferred: delete `vendor-auto/typescript-advanced-types`. Alternative: move it to `vendor/` as a tiny user-invoked compatibility pointer to magician. Do **not** leave a trigger-bearing shim under `vendor-auto/`, since that leaves two model-invoked owners of the same trigger space.

6. **Validate the final state.** Run `./setup.sh` again, verify stale-link cleanup removes the old installed link, recheck magician's relative links, and confirm the active catalogue has one TypeScript skill for this trigger space.

## Risks and remaining verification

- The exact Pi runtime relationship between `~/.agents/skills` and the advertised catalogue has not been proven by a post-change installer run. This is the gating verification before deletion.
- Decide whether the API-client, form-validation, and reducer examples are genuinely supported use cases before preserving them.
- Existing unrelated working-tree changes were present before this research; this brief does not alter skills, installer code, or registration state.

## Files affected by the eventual change

Likely edits: `vendor-auto/typescript-magician/SKILL.md`, one or more magician rule files, `README.md`, and possibly `setup.sh` (only if `~/.pi/agent/skills` is the intended target). Likely retirement: `vendor-auto/typescript-advanced-types/` after successful registration validation.
