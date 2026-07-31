import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";

import { fetchInvites, resendInvite, revokeInvite } from "../../api/invites";
import { InviteTeammatesView } from "./InviteTeammates.view";

export function InviteTeammates({ workspaceId }: { workspaceId: string }) {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");

  const { data: invites = [], isPending } = useQuery({
    queryKey: ["invites", workspaceId],
    queryFn: () => fetchInvites(workspaceId),
  });

  const invalidate = () =>
    queryClient.invalidateQueries({ queryKey: ["invites", workspaceId] });

  const revoke = useMutation({ mutationFn: revokeInvite, onSuccess: invalidate });
  const resend = useMutation({ mutationFn: resendInvite, onSuccess: invalidate });

  const visibleInvites = useMemo(() => {
    const needle = search.trim().toLowerCase();
    if (!needle) return invites;
    return invites.filter((invite) => invite.email.toLowerCase().includes(needle));
  }, [invites, search]);

  const pendingCount = invites.filter((invite) => invite.status === "pending").length;

  const busyInviteId = revoke.isPending
    ? revoke.variables
    : resend.isPending
      ? resend.variables
      : null;

  return (
    <InviteTeammatesView
      invites={visibleInvites}
      isLoading={isPending}
      pendingCount={pendingCount}
      search={search}
      onSearchChange={setSearch}
      onResend={(inviteId) => resend.mutate(inviteId)}
      onRevoke={(inviteId) => revoke.mutate(inviteId)}
      busyInviteId={busyInviteId ?? null}
    />
  );
}
