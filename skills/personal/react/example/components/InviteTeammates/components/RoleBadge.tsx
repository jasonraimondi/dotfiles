import type { Invite } from "../../../api/invites";

const ROLE_LABELS: Record<Invite["role"], string> = {
  admin: "Admin",
  member: "Member",
  viewer: "Viewer",
};

export function RoleBadge({ role }: { role: Invite["role"] }) {
  return <span data-role={role}>{ROLE_LABELS[role]}</span>;
}
