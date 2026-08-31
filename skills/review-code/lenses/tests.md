# Lens: `tests`

Would these tests catch the bug if it were there?

## Inputs

The diff, plus the test files it touches read in full. A test's meaning lives in its setup and assertions, not in its diff hunk.

## Checklist

- **Vacuous test** — mentally revert the change under test. Does the test still pass? Then it asserts nothing. This is the highest-value finding in the lens, and it's blocking.
- **Risky paths uncovered** — new branches, error paths, and boundary conditions with no test.
- **Assertion strength** — asserts a specific expected value, not merely that something was returned or that no error was thrown.
- **Mocked-away subject** — the mock stands in for the very thing the test claims to verify.
- **Coverage of the changed path** — the tests exercise what the diff changed, not neighbouring behaviour that already worked.
- **Weakened tests** — assertions loosened, cases deleted, or tests skipped in this diff.

## Output

Per finding: the test, and what would have to break for it to fail. A test that would not catch a regression on a risky path is blocking; a missing case on a low-risk path is not.

## Rules

Judge the tests that exist and name the cases that don't. Writing them belongs to `tdd`.
