# Cross-harness messages use pi-peer through bridges

A cross-harness fleet needs Claude Code and pi sessions to message each other while keeping each message labeled as a peer message that carries none of the user's authority. We route every cross-harness message over pi-peer, unchanged, and give each Claude session in such a fleet a bridge: a long-lived process registered as an ordinary pi-peer endpoint that spools inbound messages and wakes its owner. Same-harness messages keep their native transport.

## Considered Options

- **`herdr agent prompt`**: works for every harness today with no new code, but the text arrives as if the human typed it, so a peer could launder authority, and replies typed into the coordinator's pane collide with the user's typing. The sole exception is the fixed text `Check your pi-peer bridge.` from a pi coordinator to wake an expired Claude peer: it carries no payload, and the message itself stays in the spool.
- **Writing to Claude's messaging socket from pi**: its wire protocol and sender verification are undocumented, so pi would depend on internals that can change without notice.
- **Relaxing pi-peer to accept one-shot senders**: removes the protocol's only sender-liveness check, and replies to a Claude session would still need somewhere to land, which is most of a bridge anyway.
