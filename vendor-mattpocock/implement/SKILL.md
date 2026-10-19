---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
---

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

Call the Skill tool with "tdd" where possible, at pre-agreed seams.

Use /agent-fleet when the work splits into independent tracks.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, call the Skill tool with "review-code" in `quick` mode to review the work, passing the spec or ticket path if you have one. Fix every Blocker and Major finding, then re-run the affected tests.

Commit your work to the current branch.
