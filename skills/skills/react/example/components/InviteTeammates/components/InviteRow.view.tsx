import type { Invite } from "../../../api/invites";
import { RoleBadge } from "./RoleBadge";

type InviteRowViewProps = {
  email: string;
  role: Invite["role"];
  status: Invite["status"];
  expiresInDays: number;
  canResend: boolean;
  canRevoke: boolean;
  isConfirmingRevoke: boolean;
  onResend: () => void;
  onRequestRevoke: () => void;
  onCancelRevoke: () => void;
  onConfirmRevoke: () => void;
};

export function InviteRowView({
  email,
  role,
  status,
  expiresInDays,
  canResend,
  canRevoke,
  isConfirmingRevoke,
  onResend,
  onRequestRevoke,
  onCancelRevoke,
  onConfirmRevoke,
}: InviteRowViewProps) {
  return (
    <div>
      <span>{email}</span>
      <RoleBadge role={role} />
      <span>{status === "pending" ? `expires in ${expiresInDays}d` : status}</span>

      <button type="button" disabled={!canResend} onClick={onResend}>
        Resend
      </button>

      {isConfirmingRevoke ? (
        <>
          <button type="button" onClick={onConfirmRevoke}>
            Confirm revoke
          </button>
          <button type="button" onClick={onCancelRevoke}>
            Cancel
          </button>
        </>
      ) : (
        <button
          type="button"
          disabled={!canRevoke}
          onClick={onRequestRevoke}
        >
          Revoke
        </button>
      )}
    </div>
  );
}
