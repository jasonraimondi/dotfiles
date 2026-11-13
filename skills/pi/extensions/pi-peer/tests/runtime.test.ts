import assert from "node:assert/strict";
import { spawn, execFile } from "node:child_process";
import { once } from "node:events";
import { mkdtemp, mkdir, readdir, rm, symlink, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

function object(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
function text(content: unknown): string {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) return content.map((item) => object(item) && typeof item.text === "string" ? item.text : "").join("\n");
  return "";
}

test("real Pi runtimes wake on messages, reply through the tool, persist provenance, and replace endpoints", { timeout: 30000 }, async (t) => {
  const root = await mkdtemp("/tmp/pi-peer-rpc-");
  t.after(() => rm(root, { recursive: true, force: true }));
  const registry = join(root, "peers");
  const config = join(root, "config");
  await mkdir(config);
  const extension = fileURLToPath(new URL("../index.ts", import.meta.url));
  await mkdir(join(config, "extensions"));
  await symlink(fileURLToPath(new URL("../", import.meta.url)), join(config, "extensions/pi-peer"));
  const commands = fileURLToPath(new URL("fixtures/commands.ts", import.meta.url));
  const cli = fileURLToPath(new URL("../node_modules/@earendil-works/pi-coding-agent/dist/cli.js", import.meta.url));
  const scripts = fileURLToPath(new URL("../../../../skills/agent-fleet/scripts/", import.meta.url));
  let modelCalls = 0;
  let releaseHold = () => {};
  let reportHeld = () => {};
  const hold = new Promise<void>((resolveHold) => { releaseHold = resolveHold; });
  const held = new Promise<void>((resolveHeld) => { reportHeld = resolveHeld; });
  t.after(() => releaseHold());
  const model = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const chunk of req) chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    const body: unknown = JSON.parse(Buffer.concat(chunks).toString());
    assert.ok(object(body) && Array.isArray(body.messages));
    const last: unknown = body.messages.at(-1);
    assert.ok(object(last));
    const content = text(last.content);
    if (content === "HOLD") { reportHeld(); await hold; }
    const begin = /BEGIN PING (pi:[0-9a-f-]+)/.exec(content);
    const reply = /Reply with peer_sessions action=send, to=(pi:[0-9a-f-]+)/.exec(content);
    const to = last.role === "user" ? (begin?.[1] || (content.endsWith("PING") ? reply?.[1] : undefined)) : undefined;
    const delta = to ? {
      tool_calls: [{ index: 0, id: `call_${++modelCalls}`, type: "function", function: {
        name: "peer_sessions", arguments: JSON.stringify({ action: "send", to, message: begin ? "PING" : "PONG" }),
      } }],
    } : { content: "Finished." };
    res.writeHead(200, { "content-type": "text/event-stream" });
    for (const [chunk, finish] of [[delta, null], [{}, to ? "tool_calls" : "stop"]]) {
      res.write(`data: ${JSON.stringify({ id: "test", object: "chat.completion.chunk", created: 1, model: "fake", choices: [{ index: 0, delta: chunk, finish_reason: finish }] })}\n\n`);
    }
    res.end("data: [DONE]\n\n");
  });
  model.listen(0, "127.0.0.1");
  await once(model, "listening");
  t.after(() => { model.closeAllConnections(); model.close(); });
  const address = model.address();
  assert.ok(address && typeof address !== "string");
  await writeFile(join(config, "models.json"), JSON.stringify({ providers: {
    "peer-test": { baseUrl: `http://127.0.0.1:${address.port}/v1`, apiKey: "local-test-only", api: "openai-completions", models: [
      { id: "fake", name: "Fake", reasoning: false, input: ["text"], contextWindow: 100000, maxTokens: 1000, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } },
    ] },
  } }));

  async function start(name: string, tools = "peer_sessions") {
    const child = spawn(process.execPath, [cli, "--mode", "rpc", "--offline", "--no-approve", "--no-context-files", "--no-skills", "--no-prompt-templates", "--extension", extension, "--extension", commands, "--tools", tools, "--provider", "peer-test", "--model", "fake", "--name", name, "--session-dir", join(root, "sessions")], {
      cwd: root,
      env: { ...process.env, PI_CODING_AGENT_DIR: config, PI_PEER_DIR: registry },
      stdio: ["pipe", "pipe", "pipe"],
    });
    const events: Record<string, unknown>[] = [];
    let buffer = "";
    let stderr = "";
    child.stderr.setEncoding("utf8").on("data", (chunk: string) => { stderr += chunk; });
    child.stdout.setEncoding("utf8").on("data", (chunk: string) => {
      buffer += chunk;
      while (buffer.includes("\n")) {
        const index = buffer.indexOf("\n");
        const value: unknown = JSON.parse(buffer.slice(0, index));
        buffer = buffer.slice(index + 1);
        if (object(value)) { events.push(value); child.emit("rpc-event", value); }
      }
    });
    async function wait(predicate: (event: Record<string, unknown>) => boolean): Promise<Record<string, unknown>> {
      const existing = events.find(predicate);
      if (existing) return existing;
      return new Promise((resolveWait, reject) => {
        const timer = setTimeout(() => finish(new Error(`RPC timeout: ${stderr}`)), 10000);
        const finish = (error?: Error, event?: Record<string, unknown>) => {
          clearTimeout(timer); child.off("rpc-event", check); child.off("exit", exited);
          if (error) reject(error); else if (event) resolveWait(event);
        };
        const check = (event: Record<string, unknown>) => { if (predicate(event)) finish(undefined, event); };
        const exited = () => finish(new Error(`Pi exited: ${stderr}`));
        child.on("rpc-event", check); child.once("exit", exited);
      });
    }
    let sequence = 0;
    async function command(type: string, data: object = {}) {
      const id = `${name}-${++sequence}`;
      child.stdin.write(JSON.stringify({ type, id, ...data }) + "\n");
      const response = await wait((event) => event.id === id && event.type === "response");
      assert.equal(response.success, true, JSON.stringify(response));
      return response.data;
    }
    async function stop() {
      if (child.exitCode !== null || child.signalCode !== null) return;
      const exit = once(child, "exit");
      child.kill("SIGTERM");
      const fallback = setTimeout(() => child.kill("SIGKILL"), 3000);
      await exit;
      clearTimeout(fallback);
    }
    t.after(stop);
    const state = await command("get_state");
    assert.ok(object(state));
    return { command, wait, stop, state, events };
  }

  async function listing() {
    const { stdout } = await promisify(execFile)("python3", [resolve(scripts, "peer-addr.py"), "--harness", "pi", "--json"], {
      env: { ...process.env, PI_PEER_DIR: registry, PYTHONDONTWRITEBYTECODE: "1" },
    });
    const value: unknown = JSON.parse(stdout);
    assert.ok(object(value) && Array.isArray(value.sessions));
    return value.sessions.filter(object);
  }

  const parent = await start("planner");
  const worker = await start("worker");
  const disabled = await start("disabled", "read");
  const peers = await listing();
  assert.equal(peers.length, 2, "tool-disabled sessions must not register");
  const target = peers.find((peer) => peer.name === "worker");
  assert.ok(target && typeof target.address === "string");
  await worker.command("prompt", { message: "HOLD" });
  await held;
  await parent.command("prompt", { message: `BEGIN PING ${target.address}` });
  await parent.wait((event) => event.type === "agent_settled");
  const busy = await worker.command("get_state");
  assert.ok(object(busy) && busy.isStreaming === true, "inbound delivery must not abort ongoing work");
  assert.ok(parent.events.some((event) => event.type === "tool_execution_end" && object(event.result) && object(event.result.details) && event.result.details.status === "accepted"));
  assert.ok(!worker.events.some((event) => event.type === "message_end" && object(event.message) && event.message.role === "custom"));
  releaseHold();
  await parent.wait((event) => event.type === "message_end" && object(event.message) && event.message.role === "custom" && text(event.message.content).endsWith("PONG"));
  await parent.wait((event) => event.type === "agent_settled");
  await worker.wait((event) => event.type === "agent_settled");
  assert.equal(modelCalls, 2, "one outbound tool call and one reply, without ack loops");
  const entries = await parent.command("get_entries");
  assert.ok(object(entries) && Array.isArray(entries.entries));
  assert.ok(entries.entries.some((entry: unknown) => object(entry) && entry.type === "custom_message" && entry.customType === "pi-peer" && object(entry.details) && typeof entry.details.messageId === "string"
    && text(entry.content).split("\n")[0]?.endsWith(` · id ${entry.details.messageId}`)));
  await worker.command("set_session_name", { name: "renamed" });
  assert.equal((await listing()).find((peer) => peer.address === target.address)?.name, "renamed");
  await worker.command("prompt", { message: "/peer-test-reload" });
  const reloaded = (await listing()).find((peer) => peer.pid === target.pid);
  assert.ok(reloaded && reloaded.address !== target.address);
  await worker.command("new_session");
  const replacement = (await listing()).find((peer) => peer.pid === target.pid);
  assert.ok(replacement && replacement.address !== target.address && replacement.address !== reloaded.address);
  assert.ok(!(await readdir(registry)).includes(`${String(target.instanceId)}.json`));
  await disabled.stop();
  await worker.stop();
  await parent.stop();
  assert.deepEqual(await listing(), []);
});
