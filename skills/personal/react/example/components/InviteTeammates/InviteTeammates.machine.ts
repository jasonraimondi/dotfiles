export type RevokeState =
  | { status: "idle" }
  | { status: "confirming"; inviteId: string };

export type RevokeEvent =
  | { type: "revokeRequested"; inviteId: string }
  | { type: "cancelled" }
  | { type: "confirmed" };

export const initialRevokeState: RevokeState = { status: "idle" };

export function revokeMachine(state: RevokeState, event: RevokeEvent): RevokeState {
  switch (state.status) {
    case "idle":
      return event.type === "revokeRequested"
        ? { status: "confirming", inviteId: event.inviteId }
        : state;
    case "confirming":
      if (event.type === "revokeRequested") {
        return { status: "confirming", inviteId: event.inviteId };
      }
      return { status: "idle" };
  }
}
