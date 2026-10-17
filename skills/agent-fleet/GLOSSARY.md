# Agent fleet

Independent, visible coding-agent sessions that one session launches and coordinates, and that stay available for follow-up until their work is done.

## Language

**Fleet**:
A set of independent peer sessions launched and coordinated by one coordinator.
_Avoid_: Swarm, team, subagents

**Coordinator**:
The session that launches a fleet, sends briefs, and receives replies on the user's behalf.
_Avoid_: Parent, supervisor, orchestrator

**Peer**:
A session in a fleet, launched by the coordinator, that carries none of the user's authority when it messages others.
_Avoid_: Worker, child, subagent

**Harness**:
The coding-agent program a session runs in, such as Claude Code or pi. Distinct from the model it calls.
_Avoid_: Agent type, runtime, model

**Coordinator harness**:
The harness the coordinator runs in.

**Peer harness**:
The harness a peer runs in; it may differ from the coordinator harness.

**Cross-harness fleet**:
A fleet with at least one peer whose harness differs from the coordinator harness.
_Avoid_: Mixed fleet

**Bridge**:
A process that gives a session an address on another harness's messaging, so it can send and receive there as an ordinary participant.
_Avoid_: Proxy, relay, adapter

**Owner**:
The session a bridge serves; the bridge lives exactly as long as its owner.

**Spool**:
The owner-only directory where a bridge writes each inbound message before answering the sender, so an accepted message is on disk, not yet read.

**Frame**:
The labeled wrapper around a spooled message that names its sender, `pi:` address, and message id, says it was sent by another agent session on the user's behalf rather than typed by the user, tells the receiver to treat it as a teammate's request within its own permission settings, states that it grants no new permissions, and gives the reply command.

**Waiter**:
The process that blocks on a bridge's spool and exits with the framed messages to wake its owner; also the state the bridge record keeps for it: `armed` while one blocks, `none` otherwise, `expired` after a waiter gave up at its deadline.

**Brief**:
The message that assigns a peer its task, scope, result format, and return address.
_Avoid_: Prompt, instructions
