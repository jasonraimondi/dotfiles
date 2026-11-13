# Lens: `modularity`

What does `mdlr` measure on the changed code, and which of its numbers are worth acting on?

The numbers are **advisory**. `mdlr` counts complexity, duplication, and coupling; it cannot tell whether the split a number implies would leave the code simpler or only more spread out. This lens supplies that judgement, and its findings feed the report's engineering rating.

## Inputs

`mdlr`, run from the repo root. Check it exists first: `mdlr --version`. If it isn't installed, report "mdlr not installed — modularity skipped" and stop; that's a complete result, not a failure.

## Workflow

1. `mdlr check --pretty`.
2. Scope its output to the review. mdlr scopes itself to the dirty files, or to the diff against `main` on a clean feature branch — where it reports a diff scope covering this review, take it as-is. Where it reports `scope: whole project` (a clean `main`, or nothing analyzable in the diff), cross-reference the opportunities table against the changed files and drop every row outside them. Whole-project rows are not this review's findings.
3. Weigh each surviving opportunity. Open the code, name the concrete change that would improve the number, and ask whether the next person to edit this code is better off after it.
   - **Keep** it when the change removes code, removes a duplicate, or separates a function doing several jobs into the jobs it does.
   - **Set it aside** when the change only moves code: an extraction with one caller, a wrapper, a file split along no real seam. That is overengineering in service of a number.
4. Report the kept opportunities grouped by metric, each with mdlr's bucket (fair / poor / critical). List the ones set aside in one line each, with the reason.

## Output

Per finding: file, metric, bucket, what the number means for someone changing this code next, and the change worth making. Every finding here is a Minor at most, a `critical` bucket included; name the `critical` ones so the reader sees them.

This lens reports what the tool measured and whether it matters. Structural judgement calls beyond the numbers belong to `architecture`.
