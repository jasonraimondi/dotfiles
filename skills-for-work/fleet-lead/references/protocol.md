# Fleet-lead protocol

Plain-text messages between the lead, an impl coordinator, and the integration coordinator. The first line is a parseable header; the rest is labelled lines. Every message is sent with the harness's messaging tool to a literal address from the ledger roster.

## Header

```
[fleet-lead] <TYPE> id=<sender>.<n> from=<name> reply-to=<addr> [supersedes=<id>]
```

- `id` is the sender's name plus a counter that only goes up; a reply quotes the id it answers.
- `supersedes` names an earlier request of the same type that this one replaces. The receiver answers the old id with SKIPPED and works the new one.
- Requests are worked one at a time in arrival order.
- **ACK** `<id>`: one line, sent before starting the work, for STAGE and GATE only. Every other type is answered by its result.

## Types

### STAGE (impl → integration)

```
[fleet-lead] STAGE id=impl-ux.3 from=impl-ux reply-to=uds:/tmp/cc-socks/48430.sock supersedes=impl-ux.2
mode: merge | rebuild
base: <sha>
tips:
| branch | sha | worktree | author |
|---|---|---|---|
diff: <base-sha>...<tip-sha>
reload: fe-hmr | ai-watch | restart-needed
migration: none | <command>
browser: <route or flow to look at, with any session or record ids>
caveats: <what will change: pending Blocker will rewrite SHAs, etc.>
known-failures: <path>
```

`mode: rebuild` when any SHA from an earlier STAGE was rewritten: the integration branch is reset to `base` and the fixes and tips are merged again. `migration` other than `none` becomes a GATE from the integration coordinator to the lead. `known-failures` is a path; the file carries the details.

### RESULT (integration → impl, one STATUS line to the lead)

```
[fleet-lead] RESULT id=integration-coordinator.7 from=integration-coordinator reply-to=<addr>
answers: impl-ux.3
merge: <sha> | conflict: <files>
lint/tests: <pass | failures beyond known-failures, with file:line>
health: fe <code> | ai <code> | be <code>
serving: <sha> == HEAD | unproven: <why>
observed: <what the browser pass showed>; screenshots: <path>
not-observable: <what this environment cannot show: Temporal runs, Slack, …>
gates-pending: none | <GATE ids>
```

### DEFECT (integration → impl, which forwards it to the authoring implementer)

```
[fleet-lead] DEFECT id=integration-coordinator.8 from=integration-coordinator reply-to=<addr>
answers: impl-ux.3
error: <exact text>
at: <file:line>
introduced-by: <sha> (git log -S)
tests-missed-it: <why>
fix: <proposed change>
```

### SKIPPED (integration → impl)

```
[fleet-lead] SKIPPED id=... from=... reply-to=<addr>
answers: <old id>
superseded-by: <new id>
```

### GATE (any coordinator → lead)

```
[fleet-lead] GATE id=... from=... reply-to=<addr>
command: <exact command>
cwd: <directory>
why: <one line>
blast-radius: <what else it touches: shared dev-11 database, a server the user started, every service>
```

The lead answers **GATE-DONE** `<id>` with the command's output tail, or **GATE-DENIED** `<id>` with the user's words.

### PRIORITY (lead → coordinators)

```
[fleet-lead] PRIORITY id=... from=lead reply-to=<addr>
said: "<the user's words verbatim>" at <timestamp>
preset: none | demo | checkpoint
```

- `demo`: skip review-code, stage the pre-fix tips, record a rebuild as owed.
- `checkpoint`: every peer writes a handoff; worktrees stay; processes and tabs come down.

An impl coordinator relays PRIORITY to its own fleet under its own rules.

### ROSTER (lead → coordinator)

```
[fleet-lead] ROSTER id=... from=lead reply-to=<addr>
<name>: <addr>
```

Sent after a spawn or respawn, so the receiver addresses its peer coordinator by the current address.

### STATUS (coordinator → lead, at phase boundaries and on ask)

```
[fleet-lead] STATUS id=... from=... reply-to=<addr>
phase: <Plan | Launch | Brief | Integrate | Stage | Final review | Triage | Finish | handoff-written>
line: <one line>
```

### SAID (coordinator → lead)

When the user types directly into a coordinator, it echoes the words to the lead before acting:

```
[fleet-lead] SAID id=... from=... reply-to=<addr>
said: "<the user's words verbatim>" at <timestamp>
```

### GO-PUSH / GO-HOLD (lead → impl)

```
[fleet-lead] GO-PUSH id=... from=lead reply-to=<addr>
said: "<the user's words verbatim>" at <timestamp>
```

Sent when the impl coordinator reports STATUS `phase: Finish`. On GO-PUSH it pushes and opens PRs; on GO-HOLD the branches stay local and DONE lists them. Either way it tears down its fleet and replies DONE.

### DONE (impl → lead)

```
[fleet-lead] DONE id=... from=... reply-to=<addr>
report: <path>
prs: <urls or none>
held: <branches left unpushed, or none>
```
