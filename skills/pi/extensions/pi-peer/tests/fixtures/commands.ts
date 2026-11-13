import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function testCommands(pi: ExtensionAPI) {
  pi.registerCommand("peer-test-reload", {
    description: "Reload the isolated test runtime",
    handler: async (_args, ctx) => { await ctx.reload(); },
  });
}
