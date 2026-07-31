import { useState } from "react";

import type { Invite } from "../../../api/invites";
import { RoleBadge } from "./RoleBadge";

type InviteRowViewProps = {
  email: string;
  role: Invite["role"];
  status: Invite["status"];
  expiresInDays: number;
  canResend: boolean;
  canRevoke: boolean;
  onResend: () => void;
  onRevoke: () => void;
};

export function InviteRowView({
  email,
  role,
  status,
  expiresInDays,
  canResend,
  canRevoke,
  onResend,
  onRevoke,
}: InviteRowViewProps) {
  const [isConfirmingRevoke, setIsConfirmingRevoke] = useState(false);

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
          <button
            type="button"
            onClick={() => {
              setIsConfirmingRevoke(false);
              onRevoke();
            }}
          >
            Confirm revoke
          </button>
          <button type="button" onClick={() => setIsConfirmingRevoke(false)}>
            Cancel
          </button>
        </>
      ) : (
        <button
          type="button"
          disabled={!canRevoke}
          onClick={() => setIsConfirmingRevoke(true)}
        >
          Revoke
        </button>
      )}
    </div>
  );
}
