import type { Invite } from "../../../api/invites";
import { InviteRowView } from "./InviteRow.view";

type InviteRowProps = {
  invite: Invite;
  isBusy: boolean;
  onResend: () => void;
  onRevoke: () => void;
};

export function InviteRow({ invite, isBusy, onResend, onRevoke }: InviteRowProps) {
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
      onResend={onResend}
      onRevoke={onRevoke}
    />
  );
}
