import type { Invite } from "../../api/invites";
import { InviteRow } from "./components/InviteRow";

type InviteTeammatesViewProps = {
  invites: Invite[];
  isLoading: boolean;
  pendingCount: number;
  search: string;
  busyInviteId: string | null;
  confirmingInviteId: string | null;
  onSearchChange: (search: string) => void;
  onResend: (inviteId: string) => void;
  onRequestRevoke: (inviteId: string) => void;
  onCancelRevoke: () => void;
  onConfirmRevoke: () => void;
};

export function InviteTeammatesView({
  invites,
  isLoading,
  pendingCount,
  search,
  busyInviteId,
  confirmingInviteId,
  onSearchChange,
  onResend,
  onRequestRevoke,
  onCancelRevoke,
  onConfirmRevoke,
}: InviteTeammatesViewProps) {
  if (isLoading) return <p>Loading invites…</p>;

  return (
    <section>
      <header>
        <h2>Teammates</h2>
        <p>{pendingCount} pending</p>
      </header>

      <label>
        Filter by email
        <input
          value={search}
          onChange={(event) => onSearchChange(event.target.value)}
          placeholder="ada@example.com"
        />
      </label>

      {invites.length === 0 ? (
        <p>No invites match “{search}”.</p>
      ) : (
        <ul>
          {invites.map((invite) => (
            <li key={invite.id}>
              <InviteRow
                invite={invite}
                isBusy={busyInviteId === invite.id}
                isConfirmingRevoke={confirmingInviteId === invite.id}
                onResend={() => onResend(invite.id)}
                onRequestRevoke={() => onRequestRevoke(invite.id)}
                onCancelRevoke={onCancelRevoke}
                onConfirmRevoke={onConfirmRevoke}
              />
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
