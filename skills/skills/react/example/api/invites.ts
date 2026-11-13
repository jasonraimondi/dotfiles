export type Invite = {
  id: string;
  email: string;
  role: "admin" | "member" | "viewer";
  status: "pending" | "accepted" | "revoked";
  expiresAt: string;
};

export async function fetchInvites(workspaceId: string): Promise<Invite[]> {
  const response = await fetch(`/api/workspaces/${workspaceId}/invites`);
  if (!response.ok) throw new Error("Failed to load invites");
  return response.json();
}

export async function resendInvite(inviteId: string): Promise<void> {
  await fetch(`/api/invites/${inviteId}/resend`, { method: "POST" });
}

export async function revokeInvite(inviteId: string): Promise<void> {
  await fetch(`/api/invites/${inviteId}`, { method: "DELETE" });
}
