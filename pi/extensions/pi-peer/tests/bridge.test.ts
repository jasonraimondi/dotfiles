import assert from "node:assert/strict";
import { spawn, type ChildProcess } from "node:child_process";
import { createServer } from "node:net";
import { randomUUID } from "node:crypto";
import { once } from "node:events";
import { watch } from "node:fs";
import { access, chmod, mkdir, mkdtemp, readdir, readFile, rm, stat, symlink, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { setTimeout as sleep } from "node:timers/promises";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { startPeer, type PeerMessage } from "../peer.ts";

const BRIDGE = fileURLToPath(new URL("../bridge.ts", import.meta.url));

type Context = { after: (callback: () => unknown) => void };
type Run = { code: number | null; stdout: string; stderr: string };

async function directory(t: Context): Promise<string> {
  const path = await mkdtemp("/tmp/pi-peer-test-");
  t.after(() => rm(path, { recursive: true, force: true }));
  return path;
}

async function run(dir: string, args: string[], options: { input?: string; env?: Record<string, string>; node?: string } = {}): Promise<Run> {
  const child = spawn(options.node ?? process.execPath, [BRIDGE, ...args], {
    env: { ...process.env, PI_PEER_DIR: dir, CLAUDE_CODE_MESSAGING_SOCKET: "", CLAUDE_PID: "", CLAUDE_CODE_SESSION_ID: "", ...options.env },
    stdio: ["pipe", "pipe", "pipe"],
  });
  let stdout = "";
  let stderr = "";
  child.stdout.on("data", (chunk) => { stdout += String(chunk); });
  child.stderr.on("data", (chunk) => { stderr += String(chunk); });
  child.stdin.end(options.input ?? "");
  const [code] = await once(child, "exit");
  return { code, stdout, stderr };
}

function owner(t: Context): ChildProcess & { pid: number } {
  const child = spawn(process.execPath, ["-e", "setInterval(() => {}, 1000)"], { stdio: "ignore" });
  t.after(() => { child.kill("SIGKILL"); });
  if (child.pid === undefined) throw new Error("owner did not start");
  return Object.assign(child, { pid: child.pid });
}

async function until(check: () => Promise<boolean>, what: string): Promise<void> {
  for (let attempt = 0; attempt < 100; attempt++) {
    if (await check()) return;
    await sleep(50);
  }
  throw new Error(`timed out waiting for ${what}`);
}

const exists = (path: string) => access(path).then(() => true, () => false);

async function bridge(t: Context, dir: string, pid: number, name = "coordinator"): Promise<{ address: string; spool: string }> {
  const result = await run(dir, ["start", "--owner-pid", String(pid), "--name", name]);
  assert.equal(result.code, 0, result.stderr);
  t.after(() => run(dir, ["stop", "--owner-pid", String(pid)]));
  return JSON.parse(result.stdout);
}

test("start is idempotent per owner and the bridge exits with its owner", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const first = await bridge(t, dir, dummy.pid);
  assert.match(first.address, /^pi:[0-9a-f-]{36}$/);
  assert.equal(first.spool, join(dir, "bridges", String(dummy.pid)));
  const record = join(dir, "bridges", `${dummy.pid}.json`);
  assert.equal((await stat(record)).mode & 0o777, 0o600);
  assert.equal((await stat(join(first.spool, "inbox"))).mode & 0o777, 0o700);
  const saved = JSON.parse(await readFile(record, "utf8"));
  assert.equal(saved.ownerPid, dummy.pid);
  assert.equal(saved.address, first.address);
  assert.equal(saved.waiter, "none");
  assert.deepEqual(await bridge(t, dir, dummy.pid), first);
  const lister = await startPeer({ directory: dir, sessionId: "l", name: "lister", cwd: "/", receive: () => {} });
  t.after(() => lister.close());
  assert.deepEqual((await lister.list()).filter((peer) => peer.name === "coordinator").map((peer) => peer.address), [first.address]);
  dummy.kill("SIGKILL");
  await until(async () => !(await exists(record)), "bridge record removal");
  await dead(saved.pid);
  assert.equal(await exists(join(dir, `${first.address.slice(3)}.json`)), false);
  assert.deepEqual((await lister.list()).map((peer) => peer.name), ["lister"]);
});

async function spooled(dir: string): Promise<string[]> {
  return (await readdir(dir)).filter((file) => file.endsWith(".json")).sort();
}

async function dead(pid: number): Promise<void> {
  await until(async () => { try { process.kill(pid, 0); return false; } catch { return true; } }, `pid ${pid} to exit`);
}

test("an inbound message is spooled before accepted, and retries are deduplicated", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const { address, spool } = await bridge(t, dir, dummy.pid);
  const bridgePid: number = JSON.parse(await readFile(join(dir, "bridges", `${dummy.pid}.json`), "utf8")).pid;
  const sender = await startPeer({ directory: dir, sessionId: "s", name: "reviewer", cwd: "/r", receive: () => {} });
  t.after(() => sender.close());
  const inbox = join(spool, "inbox");
  await chmod(inbox, 0o500);
  await assert.rejects(sender.send({ to: address, message: "unspoolable" }), /EACCES|permission/i);
  await chmod(inbox, 0o700);
  const messageId = randomUUID();
  await Promise.all([sender.send({ to: address, message: "first", messageId }), sender.send({ to: address, message: "first", messageId })]);
  await assert.rejects(sender.send({ to: address, message: "changed", messageId }), /different content/);
  await sender.send({ to: address, message: "second" });
  process.kill(bridgePid, "SIGKILL");
  await dead(bridgePid);
  const files = await spooled(inbox);
  assert.equal(files.length, 2);
  const first = JSON.parse(await readFile(join(inbox, files[0] ?? ""), "utf8"));
  assert.equal(first.id, messageId);
  assert.equal(first.body, "first");
  assert.equal(first.from.address, sender.self().address);
  assert.equal(first.from.name, "reviewer");
  assert.equal(typeof first.receivedAt, "string");
  assert.equal((await stat(join(inbox, files[0] ?? ""))).mode & 0o777, 0o600);
  assert.equal(JSON.parse(await readFile(join(inbox, files[1] ?? ""), "utf8")).body, "second");
});

test("send reads stdin, sends from the bridge endpoint, and rejects bad input", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const { address } = await bridge(t, dir, dummy.pid);
  const received: PeerMessage[] = [];
  const reviewer = await startPeer({ directory: dir, sessionId: "w", name: "reviewer", cwd: "/w", receive: (message) => { received.push(message); } });
  t.after(() => reviewer.close());
  const to = reviewer.self().address;
  const sessions = await mkdtemp("/tmp/pi-peer-sessions-");
  t.after(() => rm(sessions, { recursive: true, force: true }));
  await writeFile(join(sessions, "other.json"), JSON.stringify({ pid: 1, messagingSocketPath: "/tmp/cc-socks/other.sock" }));
  await writeFile(join(sessions, "owner.json"), JSON.stringify({ pid: dummy.pid, messagingSocketPath: "/tmp/cc-socks/owner.sock" }));
  const env = { CLAUDE_SESSIONS_DIR: sessions, CLAUDE_CODE_MESSAGING_SOCKET: "/tmp/cc-socks/owner.sock" };

  const sent = await run(dir, ["send", "--to", to], { input: "Please review.\n", env });
  assert.equal(sent.code, 0, sent.stderr);
  const receipt = JSON.parse(sent.stdout);
  assert.equal(receipt.status, "accepted");
  assert.equal(receipt.to, to);
  assert.equal(receipt.messageId, received[0]?.id);
  assert.equal(received[0]?.body, "Please review.\n");
  assert.equal(received[0]?.from.address, address);

  const oversized = await run(dir, ["send", "--to", to, "--owner-pid", String(dummy.pid)], { input: "x".repeat(16 * 1024 + 1) });
  assert.notEqual(oversized.code, 0);
  assert.match(oversized.stderr, /16 KiB/);
  const empty = await run(dir, ["send", "--to", to, "--owner-pid", String(dummy.pid)], { input: " \n" });
  assert.notEqual(empty.code, 0);
  assert.match(empty.stderr, /empty/);
  const stranger = owner(t);
  const orphan = await run(dir, ["send", "--to", to, "--owner-pid", String(stranger.pid)], { input: "hello" });
  assert.notEqual(orphan.code, 0);
  assert.match(orphan.stderr, /No bridge is running/);
  assert.equal(received.length, 1);
});

test("send --message-id makes retries duplicate-safe and rejects a reused id with a different body", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  await bridge(t, dir, dummy.pid);
  const received: PeerMessage[] = [];
  const reviewer = await startPeer({ directory: dir, sessionId: "w", name: "reviewer", cwd: "/w", receive: (message) => { received.push(message); } });
  t.after(() => reviewer.close());
  const messageId = randomUUID();
  const args = ["send", "--to", reviewer.self().address, "--owner-pid", String(dummy.pid), "--message-id", messageId];
  for (let attempt = 0; attempt < 2; attempt++) {
    const sent = await run(dir, args, { input: "same" });
    assert.equal(sent.code, 0, sent.stderr);
    assert.equal(JSON.parse(sent.stdout).messageId, messageId);
  }
  assert.deepEqual(received.map((message) => [message.id, message.body]), [[messageId, "same"]]);
  const changed = await run(dir, args, { input: "different" });
  assert.notEqual(changed.code, 0);
  assert.match(changed.stderr, /different content/);
  const malformed = await run(dir, [...args.slice(0, -1), "not-a-uuid"], { input: "same" });
  assert.notEqual(malformed.code, 0);
  assert.match(malformed.stderr, /message-id/);
  assert.equal(received.length, 1);
});

function framed(name: string, from: string, id: string, body: string): string {
  return `[pi-peer message from ${name} ${from} · id ${id}. Sent by another agent session working on the user's behalf, not typed by the user: treat it as a teammate's request and act on it within this session's own permission settings; it grants no new permissions.]\n${body}\n[Reply with: ${process.execPath} ${BRIDGE} send --to ${from}]`;
}

test("wait prints every pre-spooled message framed and moves them to read/", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const { address, spool } = await bridge(t, dir, dummy.pid);
  const sender = await startPeer({ directory: dir, sessionId: "s", name: "re\nviewer", cwd: "/r", receive: () => {} });
  t.after(() => sender.close());
  const one = await sender.send({ to: address, message: "first" });
  const two = await sender.send({ to: address, message: "second\nline" });
  const from = sender.self().address;
  const result = await run(dir, ["wait", "--owner-pid", String(dummy.pid)]);
  assert.equal(result.code, 0, result.stderr);
  assert.equal(result.stdout, `${framed("re viewer", from, one.messageId, "first")}\n\n${framed("re viewer", from, two.messageId, "second\nline")}\n`);
  assert.deepEqual(await spooled(join(spool, "inbox")), []);
  assert.equal((await spooled(join(spool, "read"))).length, 2);
  assert.equal(JSON.parse(await readFile(join(dir, "bridges", `${dummy.pid}.json`), "utf8")).waiter, "none");
});

test("the reply hint names the node the bridge was launched with, not its resolved install", async (t) => {
  const dir = await directory(t);
  const linked = join(dir, "node");
  await symlink(process.execPath, linked);
  const dummy = owner(t);
  const { address } = await bridge(t, dir, dummy.pid);
  const sender = await startPeer({ directory: dir, sessionId: "s", name: "reviewer", cwd: "/r", receive: () => {} });
  t.after(() => sender.close());
  await sender.send({ to: address, message: "hi" });
  const result = await run(dir, ["wait", "--owner-pid", String(dummy.pid)], { node: linked });
  assert.equal(result.code, 0, result.stderr);
  assert.ok(result.stdout.includes(`[Reply with: ${linked} ${BRIDGE} send`), result.stdout);
});

test("wait blocks with an armed waiter until a message arrives, and fails when the bridge stops", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const { address } = await bridge(t, dir, dummy.pid);
  const record = join(dir, "bridges", `${dummy.pid}.json`);
  const sender = await startPeer({ directory: dir, sessionId: "s", name: "reviewer", cwd: "/r", receive: () => {} });
  t.after(() => sender.close());
  const waiting = run(dir, ["wait", "--owner-pid", String(dummy.pid)]);
  await until(async () => JSON.parse(await readFile(record, "utf8")).waiter === "armed", "armed waiter");
  const receipt = await sender.send({ to: address, message: "done" });
  const woke = await waiting;
  assert.equal(woke.code, 0, woke.stderr);
  assert.equal(woke.stdout, `${framed("reviewer", sender.self().address, receipt.messageId, "done")}\n`);

  const orphaned = run(dir, ["wait", "--owner-pid", String(dummy.pid)]);
  await until(async () => JSON.parse(await readFile(record, "utf8")).waiter === "armed", "armed waiter");
  const stopped = await run(dir, ["stop", "--owner-pid", String(dummy.pid)]);
  assert.equal(stopped.code, 0, stopped.stderr);
  assert.equal(await exists(record), false);
  const failed = await orphaned;
  assert.notEqual(failed.code, 0);
  assert.match(failed.stderr, /bridge/i);
  assert.equal(failed.stdout, "");
});

test("list --json matches peer.ts list() without registering an endpoint of its own", async (t) => {
  const dir = await directory(t);
  const reviewer = await startPeer({ directory: dir, sessionId: "w", name: "reviewer", cwd: "/w", receive: () => {} });
  t.after(() => reviewer.close());
  const before = new Set(await readdir(dir));
  const changes: string[] = [];
  const watcher = watch(dir, (_event, file) => { if (file !== null && /\.(json|sock)$/.test(file) && !before.has(file)) changes.push(file); });
  t.after(() => watcher.close());
  const result = await run(dir, ["list", "--json"]);
  assert.equal(result.code, 0, result.stderr);
  const listed = JSON.parse(result.stdout);
  assert.deepEqual(listed.map((peer: { address: string }) => peer.address), [reviewer.self().address]);
  assert.deepEqual(listed, await reviewer.list());
  await sleep(100);
  assert.deepEqual(changes, []);
});

test("list --json prints [] for a missing directory and refuses a public one", async (t) => {
  const root = await directory(t);
  const missing = await run(join(root, "absent"), ["list", "--json"]);
  assert.equal(missing.code, 0, missing.stderr);
  assert.deepEqual(JSON.parse(missing.stdout), []);
  assert.equal(await exists(join(root, "absent")), false);
  await chmod(root, 0o777);
  const open = await run(root, ["list", "--json"]);
  assert.notEqual(open.code, 0);
  assert.match(open.stderr, /0700/);
});

test("wait sets a corrupt spool file aside as .invalid and still delivers the rest", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const { address, spool } = await bridge(t, dir, dummy.pid);
  const sender = await startPeer({ directory: dir, sessionId: "s", name: "reviewer", cwd: "/r", receive: () => {} });
  t.after(() => sender.close());
  const one = await sender.send({ to: address, message: "first" });
  const corrupt = `0000000000000-00000000-${randomUUID()}.json`;
  await writeFile(join(spool, "inbox", corrupt), "{not json", { mode: 0o600 });
  const two = await sender.send({ to: address, message: "second" });
  const result = await run(dir, ["wait", "--owner-pid", String(dummy.pid)]);
  assert.equal(result.code, 0, result.stderr);
  const from = sender.self().address;
  assert.equal(result.stdout, `${framed("reviewer", from, one.messageId, "first")}\n\n${framed("reviewer", from, two.messageId, "second")}\n`);
  assert.match(result.stderr, new RegExp(corrupt));
  assert.equal(result.stderr.trim().split("\n").length, 1);
  assert.deepEqual(await readdir(join(spool, "inbox")), []);
  assert.ok((await readdir(join(spool, "read"))).includes(`${corrupt}.invalid`));
});

test("stop cleans up after a dead bridge but refuses to delete a live one that does not answer", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const bridges = join(dir, "bridges");
  await mkdir(bridges, { mode: 0o700 });
  const record = join(bridges, `${dummy.pid}.json`);
  const stand = (pid: number) => writeFile(record, JSON.stringify({ version: 1, pid, ownerPid: dummy.pid, address: `pi:${randomUUID()}`, spool: join(bridges, String(dummy.pid)), waiter: "none" }), { mode: 0o600 });
  const unresponsive = owner(t);
  await stand(unresponsive.pid);
  const refused = await run(dir, ["stop", "--owner-pid", String(dummy.pid)]);
  assert.notEqual(refused.code, 0);
  assert.match(refused.stderr, new RegExp(String(unresponsive.pid)));
  assert.equal(await exists(record), true);
  unresponsive.kill("SIGKILL");
  await once(unresponsive, "exit");
  const cleaned = await run(dir, ["stop", "--owner-pid", String(dummy.pid)]);
  assert.equal(cleaned.code, 0, cleaned.stderr);
  assert.equal(await exists(record), false);
});

test("concurrent starts for one owner agree on a single bridge", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  t.after(() => run(dir, ["stop", "--owner-pid", String(dummy.pid)]));
  const starts = await Promise.all([1, 2, 3].map(() => run(dir, ["start", "--owner-pid", String(dummy.pid), "--name", "coordinator"])));
  for (const result of starts) assert.equal(result.code, 0, result.stderr);
  assert.equal(new Set(starts.map((result) => JSON.parse(result.stdout).address)).size, 1);
});

const HOOK_INPUT = JSON.stringify({ session_id: "s-1", hook_event_name: "Stop", stop_hook_active: false });
const waiterOf = async (dir: string, pid: number) => JSON.parse(await readFile(join(dir, "bridges", `${pid}.json`), "utf8")).waiter;

test("hook starts a bridge for CLAUDE_PID, consumes stdin, and expires silently at its deadline", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  t.after(() => run(dir, ["stop", "--owner-pid", String(dummy.pid)]));
  const began = Date.now();
  const result = await run(dir, ["hook", "--name", "peer-a", "--deadline-s", "1"], { input: HOOK_INPUT, env: { CLAUDE_PID: String(dummy.pid), CLAUDE_CODE_SESSION_ID: "session-a" } });
  assert.equal(result.code, 0, result.stderr);
  assert.ok(Date.now() - began >= 1000);
  assert.equal(result.stdout, "");
  assert.equal(result.stderr, "");
  const record = JSON.parse(await readFile(join(dir, "bridges", `${dummy.pid}.json`), "utf8"));
  assert.equal(record.ownerPid, dummy.pid);
  assert.equal(record.ownerSessionId, "session-a");
  assert.equal(record.waiter, "expired");
  const lister = await startPeer({ directory: dir, sessionId: "l", name: "lister", cwd: "/", receive: () => {} });
  t.after(() => lister.close());
  assert.deepEqual((await lister.list()).filter((peer) => peer.name === "peer-a").map((peer) => peer.address), [record.address]);
});

test("hook delivers pre-spooled messages framed on stderr with exit 2", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const { address, spool } = await bridge(t, dir, dummy.pid, "peer-a");
  const sender = await startPeer({ directory: dir, sessionId: "s", name: "reviewer", cwd: "/r", receive: () => {} });
  t.after(() => sender.close());
  const one = await sender.send({ to: address, message: "first" });
  const two = await sender.send({ to: address, message: "second" });
  const result = await run(dir, ["hook", "--name", "peer-a", "--deadline-s", "30"], { input: HOOK_INPUT, env: { CLAUDE_PID: String(dummy.pid) } });
  assert.equal(result.code, 2);
  assert.equal(result.stdout, "");
  const from = sender.self().address;
  assert.equal(result.stderr, `${framed("reviewer", from, one.messageId, "first")}\n\n${framed("reviewer", from, two.messageId, "second")}\n`);
  assert.deepEqual(await spooled(join(spool, "inbox")), []);
  assert.equal((await spooled(join(spool, "read"))).length, 2);
  assert.equal(await waiterOf(dir, dummy.pid), "none");
});

test("hook blocks armed until a message arrives, and exits 0 silently if the bridge goes away", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const { address } = await bridge(t, dir, dummy.pid, "peer-a");
  const sender = await startPeer({ directory: dir, sessionId: "s", name: "reviewer", cwd: "/r", receive: () => {} });
  t.after(() => sender.close());
  const env = { CLAUDE_PID: String(dummy.pid) };
  const hooked = run(dir, ["hook", "--name", "peer-a", "--deadline-s", "30"], { input: HOOK_INPUT, env });
  await until(async () => (await waiterOf(dir, dummy.pid)) === "armed", "armed waiter");
  const receipt = await sender.send({ to: address, message: "wake up" });
  const woke = await hooked;
  assert.equal(woke.code, 2);
  assert.equal(woke.stderr, `${framed("reviewer", sender.self().address, receipt.messageId, "wake up")}\n`);
  assert.equal(await waiterOf(dir, dummy.pid), "none");

  const orphaned = run(dir, ["hook", "--name", "peer-a", "--deadline-s", "30"], { input: HOOK_INPUT, env });
  await until(async () => (await waiterOf(dir, dummy.pid)) === "armed", "armed waiter");
  assert.equal((await run(dir, ["stop", "--owner-pid", String(dummy.pid)])).code, 0);
  const quiet = await orphaned;
  assert.equal(quiet.code, 0);
  assert.equal(quiet.stdout + quiet.stderr, "");
});

test("hook exits 1 on bad arguments or an unresolvable owner, before arming", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  for (const args of [["hook", "--name", "x"], ["hook", "--name", "x", "--deadline-s", "soon"]]) {
    const bad = await run(dir, args, { input: HOOK_INPUT, env: { CLAUDE_PID: String(dummy.pid) } });
    assert.equal(bad.code, 1);
    assert.match(bad.stderr, /deadline-s/);
  }
  const dead = await run(dir, ["hook", "--name", "x", "--deadline-s", "1"], { input: HOOK_INPUT, env: { CLAUDE_PID: "999999999" } });
  assert.equal(dead.code, 1);
  assert.match(dead.stderr, /999999999/);
  const unknown = await run(dir, ["hook", "--name", "x", "--deadline-s", "1"], { input: HOOK_INPUT });
  assert.equal(unknown.code, 1);
  assert.match(unknown.stderr, /CLAUDE_PID/);
  assert.equal(await exists(join(dir, "bridges")), false);
});

test("only one hook waits per owner: a second exits 0 at once, and a new one arms after the first dies", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  await bridge(t, dir, dummy.pid, "peer-a");
  const record = async () => JSON.parse(await readFile(join(dir, "bridges", `${dummy.pid}.json`), "utf8"));
  const hookProcess = () => {
    const child = spawn(process.execPath, [BRIDGE, "hook", "--name", "peer-a", "--deadline-s", "30"], {
      env: { ...process.env, PI_PEER_DIR: dir, CLAUDE_CODE_MESSAGING_SOCKET: "", CLAUDE_CODE_SESSION_ID: "", CLAUDE_PID: String(dummy.pid) },
      stdio: ["pipe", "ignore", "ignore"],
    });
    child.stdin.end(HOOK_INPUT);
    t.after(() => { child.kill("SIGKILL"); });
    return child;
  };
  const first = hookProcess();
  await until(async () => (await record()).waiterPid === first.pid, "first hook armed");
  const began = Date.now();
  const second = await run(dir, ["hook", "--name", "peer-a", "--deadline-s", "30"], { input: HOOK_INPUT, env: { CLAUDE_PID: String(dummy.pid) } });
  assert.equal(second.code, 0);
  assert.equal(second.stdout + second.stderr, "");
  assert.ok(Date.now() - began < 5000);
  assert.equal((await record()).waiterPid, first.pid);
  assert.equal((await record()).waiter, "armed");

  first.kill("SIGKILL");
  await once(first, "exit");
  const third = hookProcess();
  await until(async () => (await record()).waiterPid === third.pid, "third hook armed");
  third.kill("SIGTERM");
  const [code] = await once(third, "exit");
  assert.equal(code, 0);
  const after = await record();
  assert.equal(after.waiter, "none");
  assert.equal(after.waiterPid, undefined);
});

test("send resolves the owner from CLAUDE_PID without a session registry", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  await bridge(t, dir, dummy.pid);
  const received: PeerMessage[] = [];
  const reviewer = await startPeer({ directory: dir, sessionId: "r", name: "reviewer", cwd: "/r", receive: (message) => { received.push(message); } });
  t.after(() => reviewer.close());
  const sessions = await mkdtemp("/tmp/pi-peer-sessions-");
  t.after(() => rm(sessions, { recursive: true, force: true }));
  const sent = await run(dir, ["send", "--to", reviewer.self().address], { input: "via CLAUDE_PID", env: { CLAUDE_PID: String(dummy.pid), CLAUDE_SESSIONS_DIR: sessions } });
  assert.equal(sent.code, 0, sent.stderr);
  assert.equal(received[0]?.body, "via CLAUDE_PID");
});

function armedHook(t: Context, dir: string, ownerPid: number): ChildProcess & { pid: number } {
  const child = spawn(process.execPath, [BRIDGE, "hook", "--name", "peer-a", "--deadline-s", "30"], {
    env: { ...process.env, PI_PEER_DIR: dir, CLAUDE_CODE_MESSAGING_SOCKET: "", CLAUDE_CODE_SESSION_ID: "", CLAUDE_PID: String(ownerPid) },
    stdio: ["pipe", "ignore", "ignore"],
  });
  child.stdin.end(HOOK_INPUT);
  t.after(() => { child.kill("SIGKILL"); });
  if (child.pid === undefined) throw new Error("hook did not start");
  return Object.assign(child, { pid: child.pid });
}

test("a live hook keeps the waiter: wait and a second hook neither take nor clear it", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const { address } = await bridge(t, dir, dummy.pid, "peer-a");
  const record = async () => JSON.parse(await readFile(join(dir, "bridges", `${dummy.pid}.json`), "utf8"));
  const sender = await startPeer({ directory: dir, sessionId: "s", name: "reviewer", cwd: "/r", receive: () => {} });
  t.after(() => sender.close());
  const holder = armedHook(t, dir, dummy.pid);
  await until(async () => (await record()).waiterPid === holder.pid, "hook armed");
  holder.kill("SIGSTOP");
  t.after(() => { holder.kill("SIGCONT"); });

  const waiting = run(dir, ["wait", "--owner-pid", String(dummy.pid)]);
  await sleep(300);
  const forWait = await sender.send({ to: address, message: "for wait" });
  const waited = await waiting;
  assert.equal(waited.code, 0, waited.stderr);
  assert.equal(waited.stdout, `${framed("reviewer", sender.self().address, forWait.messageId, "for wait")}\n`);
  assert.equal((await record()).waiter, "armed");
  assert.equal((await record()).waiterPid, holder.pid);

  const forHook = await sender.send({ to: address, message: "for hook B" });
  const second = await run(dir, ["hook", "--name", "peer-a", "--deadline-s", "30"], { input: HOOK_INPUT, env: { CLAUDE_PID: String(dummy.pid) } });
  assert.equal(second.code, 2);
  assert.equal(second.stderr, `${framed("reviewer", sender.self().address, forHook.messageId, "for hook B")}\n`);
  assert.equal((await record()).waiter, "armed");
  assert.equal((await record()).waiterPid, holder.pid);
});

test("a bridge that loses its control socket shuts down without touching the new owner's files", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const { address } = await bridge(t, dir, dummy.pid);
  const recordPath = join(dir, "bridges", `${dummy.pid}.json`);
  const bridgePid: number = JSON.parse(await readFile(recordPath, "utf8")).pid;
  const control = join(dir, "bridges", `${dummy.pid}.ctl`);
  await rm(control);
  const usurper = createServer((socket) => { socket.end(); });
  await new Promise<void>((resolveListen) => usurper.listen(control, resolveListen));
  t.after(() => new Promise<void>((resolveClose) => usurper.close(() => resolveClose())));
  await dead(bridgePid);
  assert.equal(await exists(join(dir, `${address.slice(3)}.json`)), false);
  assert.equal(await exists(control), true);
  assert.equal(await exists(recordPath), true);
});

test("an internal error after arming resets the waiter and exits 0", async (t) => {
  const dir = await directory(t);
  const dummy = owner(t);
  const { spool } = await bridge(t, dir, dummy.pid, "peer-a");
  const hooked = run(dir, ["hook", "--name", "peer-a", "--deadline-s", "30"], { input: HOOK_INPUT, env: { CLAUDE_PID: String(dummy.pid) } });
  await until(async () => (await waiterOf(dir, dummy.pid)) === "armed", "armed waiter");
  const inbox = join(spool, "inbox");
  await chmod(inbox, 0o000);
  const result = await hooked;
  await chmod(inbox, 0o700);
  assert.equal(result.code, 0);
  assert.equal(result.stdout, "");
  assert.equal(await waiterOf(dir, dummy.pid), "none");
});
