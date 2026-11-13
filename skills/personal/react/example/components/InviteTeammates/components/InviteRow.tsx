import type { Invite } from "../../../api/invites";
import { InviteRowView } from "./InviteRow.view";

type InviteRowProps = {
  invite: Invite;
  isBusy: boolean;
  isConfirmingRevoke: boolean;
  onResend: () => void;
  onRequestRevoke: () => void;
  onCancelRevoke: () => void;
  onConfirmRevoke: () => void;
};

export function InviteRow({
  invite,
  isBusy,
  isConfirmingRevoke,
  onResend,
  onRequestRevoke,
  onCancelRevoke,
  onConfirmRevoke,
}: InviteRowProps) {
  const expiresInDays = Math.ceil(
    (new Date(invite.expiresAt).getTime() - Date.now()) / 86_400_000,
  );

  return (
    <InviteRowView
      email={invite.email}
      role={invite.role}
      status={invite.status}
      expiresInDays={expiresInDays}
      canResend={invite.status === "pending" && !isBusy}
      canRevoke={invite.status !== "revoked" && !isBusy}
      isConfirmingRevoke={isConfirmingRevoke}
      onResend={onResend}
      onRequestRevoke={onRequestRevoke}
      onCancelRevoke={onCancelRevoke}
      onConfirmRevoke={onConfirmRevoke}
    />
  );
}
