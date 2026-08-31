# Lens: `modularity`

Does the diff worsen complexity, duplication, or coupling — measured, not eyeballed?

## Inputs

`mdlr`, run from the repo root. Check it exists first: `mdlr --version`. If it isn't installed, report "mdlr not installed — modularity skipped" and stop; that's a complete result, not a failure.

## Workflow

1. `mdlr check --pretty`.
2. Scope its output to the review. mdlr scopes itself to the dirty files, or to the diff against `main` on a clean feature branch — where it reports a diff scope covering this review, take it as-is. Where it reports `scope: whole project` (a clean `main`, or nothing analyzable in the diff), cross-reference the opportunities table against the changed files and drop every row outside them. Whole-project rows are not this review's findings.
3. Report the surviving opportunities grouped by metric, each with mdlr's bucket (fair / poor / critical).

## Output

Per finding: file, metric, bucket, and what the number means for someone changing this code next. Call out every `critical` bucket explicitly — those are blocking.

This lens reports what the tool measured. Structural judgement calls belong to `architecture`.
