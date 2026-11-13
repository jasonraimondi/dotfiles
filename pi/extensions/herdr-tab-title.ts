import { spawn } from "node:child_process";
import os from "node:os";
import path from "node:path";

const script = path.join(os.homedir(), ".claude/hooks/herdr-tab-title.sh");

export default function (pi) {
  if (!process.env.HC_TERMINAL_ID) return;

  pi.on("input", (event, ctx) => {
    if (ctx?.mode !== "tui" || event?.source === "extension") return;
    const sessionId = ctx.sessionManager?.getSessionId?.();
    if (!sessionId || !event.text) return;

    const child = spawn("bash", [script], { stdio: ["pipe", "ignore", "ignore"] });
    child.on("error", () => {});
    child.stdin.on("error", () => {});
    child.stdin.end(JSON.stringify({ session_id: sessionId, prompt: event.text }));
  });
}
