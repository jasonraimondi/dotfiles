import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, expect, it, vi } from "vitest";

import * as invitesApi from "../../api/invites";
import { InviteTeammates } from "./InviteTeammates";

const invite = (overrides: Partial<invitesApi.Invite> = {}): invitesApi.Invite => ({
  id: "inv_1",
  email: "ada@example.com",
  role: "member",
  status: "pending",
  expiresAt: "2030-01-01T00:00:00.000Z",
  ...overrides,
});

function renderComponent() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <QueryClientProvider client={queryClient}>
      <InviteTeammates workspaceId="ws_1" />
    </QueryClientProvider>,
  );
}

beforeEach(() => {
  vi.spyOn(invitesApi, "fetchInvites").mockResolvedValue([
    invite(),
    invite({ id: "inv_2", email: "grace@example.com", role: "admin" }),
  ]);
  vi.spyOn(invitesApi, "revokeInvite").mockResolvedValue();
});

it("filters invites by email", async () => {
  renderComponent();
  await screen.findByText("ada@example.com");

  await userEvent.type(screen.getByLabelText("Filter by email"), "grace");

  expect(screen.queryByText("ada@example.com")).not.toBeInTheDocument();
  expect(screen.getByText("grace@example.com")).toBeInTheDocument();
});

it("revokes an invite after confirmation", async () => {
  renderComponent();
  await screen.findByText("ada@example.com");

  await userEvent.click(screen.getAllByRole("button", { name: "Revoke" })[0]);
  await userEvent.click(screen.getByRole("button", { name: "Confirm revoke" }));

  await waitFor(() => expect(invitesApi.revokeInvite).toHaveBeenCalledWith("inv_1"));
});

it("confirms one revoke at a time", async () => {
  renderComponent();
  await screen.findByText("ada@example.com");

  const [adaRevoke, graceRevoke] = screen.getAllByRole("button", { name: "Revoke" });
  await userEvent.click(adaRevoke);
  await userEvent.click(graceRevoke);
  await userEvent.click(screen.getByRole("button", { name: "Confirm revoke" }));

  await waitFor(() => expect(invitesApi.revokeInvite).toHaveBeenCalledWith("inv_2"));
  expect(invitesApi.revokeInvite).not.toHaveBeenCalledWith("inv_1");
});
