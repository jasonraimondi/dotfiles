import { spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import { once } from "node:events";
import { chmodSync, lstatSync, mkdirSync, readFileSync, readdirSync, renameSync, unlinkSync, watch, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { createConnection, createServer, type Server, type Socket } from "node:net";
import { join } from "node:path";
import { setTimeout as sleep } from "node:timers/promises";
import { fileURLToPath } from "node:url";
import { listPeers, peerDirectory, startPeer, type PeerMessage } from "./peer.ts";

const SCRIPT = fileURLToPath(import.meta.url);
const MAX_MESSAGE = 16 * 1024;
const MAX_FRAME = 128 * 1024;
const CONTROL_TIMEOUT_MS = 10000;
const START_TIMEOUT_MS = 5000;
const POLL_MS = 1000;
const STDIN_GRACE_MS = 1000;
const ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const SPOOLED = /^\d{13}-\d{8}-[0-9a-f-]{36}\.json$/;
const WAITERS = ["armed", "expired", "none"] as const;

type Waiter = typeof WAITERS[number];
type Flags = Record<string, string | true>;
export type BridgeRecord = {
  version: 1; pid: number; ownerPid: number; ownerSessionId?: string;
  address: `pi:${string}`; spool: string; waiter: Waiter; waiterPid?: number;
};
type Spooled = { id: string; from: PeerMessage["from"]; body: string; receivedAt: string };

function object(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function errorCode(error: unknown): unknown {
  return object(error) ? error.code : undefined;
}

function isPid(value: unknown): value is number {
  return typeof value === "number" && Number.isSafeInteger(value) && value > 0;
}

function onSignals(handler: () => void): void {
  for (const signal of ["SIGTERM", "SIGINT", "SIGHUP"] as const) process.once(signal, handler);
}

function isWaiter(value: unknown): value is Waiter {
  return WAITERS.some((waiter) => waiter === value);
}

function parse(argv: string[]): { command: string; flags: Flags } {
  const [command = "", ...rest] = argv;
  const flags: Flags = {};
  for (let index = 0; index < rest.length; index++) {
    const arg = rest[index];
    if (!arg?.startsWith("--")) throw new Error(`Unexpected argument: ${arg}`);
    const next = rest[index + 1];
    if (next === undefined || next.startsWith("--")) flags[arg.slice(2)] = true;
    else { flags[arg.slice(2)] = next; index++; }
  }
  return { command, flags };
}

function text(flags: Flags, key: string): string {
  const value = flags[key];
  if (typeof value !== "string" || !value) throw new Error(`--${key} <value> is required`);
  return value;
}

function pid(flags: Flags, key: string): number {
  const value = Number(text(flags, key));
  if (!/^\d+$/.test(text(flags, key)) || !isPid(value)) throw new Error(`--${key} must be a positive process id`);
  return value;
}

function alive(processId: number): boolean {
  try { process.kill(processId, 0); return true; }
  catch (error) { return errorCode(error) === "EPERM"; }
}

function paths(ownerPid: number) {
  const root = join(peerDirectory(), "bridges");
  const spool = join(root, String(ownerPid));
  return {
    ownerPid, root, spool, inbox: join(spool, "inbox"), read: join(spool, "read"),
    record: join(root, `${ownerPid}.json`), control: join(root, `${ownerPid}.ctl`),
  };
}
type Paths = ReturnType<typeof paths>;

function privateDirectory(directory: string): void {
  mkdirSync(directory, { recursive: true, mode: 0o700 });
  const stat = lstatSync(directory);
  if (!stat.isDirectory() || stat.uid !== process.getuid?.() || (stat.mode & 0o077) !== 0) {
    throw new Error(`Bridge directory must be owned by you, not a symlink, and mode 0700: ${directory}`);
  }
}

function writeAtomic(path: string, data: string): void {
  const temporary = `${path}.${randomUUID()}.tmp`;
  writeFileSync(temporary, data, { flag: "wx", mode: 0o600 });
  renameSync(temporary, path);
}

function removeIfPresent(path: string): void {
  try { unlinkSync(path); }
  catch (error) { if (errorCode(error) !== "ENOENT") throw error; }
}

function bridgeRecord(value: unknown): BridgeRecord {
  if (!object(value) || value.version !== 1 || !isPid(value.pid) || !isPid(value.ownerPid)
    || (value.ownerSessionId !== undefined && typeof value.ownerSessionId !== "string")
    || typeof value.address !== "string" || !value.address.startsWith("pi:") || !ID.test(value.address.slice(3))
    || typeof value.spool !== "string" || !isWaiter(value.waiter)
    || (value.waiterPid !== undefined && !isPid(value.waiterPid))) throw new Error("Invalid bridge record");
  return {
    version: 1, pid: value.pid, ownerPid: value.ownerPid,
    ...(value.ownerSessionId === undefined ? {} : { ownerSessionId: value.ownerSessionId }),
    address: `pi:${value.address.slice(3)}`, spool: value.spool, waiter: value.waiter,
    ...(value.waiterPid === undefined ? {} : { waiterPid: value.waiterPid }),
  };
}

function readLine(socket: Socket): Promise<unknown> {
  return new Promise((resolveLine, reject) => {
    let buffer = "";
    socket.setEncoding("utf8");
    socket.setTimeout(CONTROL_TIMEOUT_MS, () => { reject(new Error("Bridge did not answer in time")); socket.destroy(); });
    socket.on("data", (chunk: string) => {
      buffer += chunk;
      const newline = buffer.indexOf("\n");
      if (newline >= 0) {
        socket.setTimeout(0);
        try { resolveLine(JSON.parse(buffer.slice(0, newline))); }
        catch { reject(new Error("Invalid bridge JSON")); }
      } else if (buffer.length > MAX_FRAME) { reject(new Error("Bridge frame exceeds 128 KiB")); socket.destroy(); }
    });
    socket.once("error", reject);
    socket.once("close", () => reject(new Error("Bridge connection closed")));
  });
}

async function control(p: Paths, payload: unknown): Promise<unknown> {
  const socket = createConnection(p.control);
  try {
    try { await once(socket, "connect"); }
    catch { throw new Error(`No bridge is running for owner ${p.ownerPid}; run bridge.ts start first`); }
    const reply = readLine(socket);
    socket.write(JSON.stringify(payload) + "\n");
    const result = await reply;
    if (!object(result) || result.ok !== true) {
      throw new Error(object(result) && typeof result.error === "string" ? result.error : "Invalid bridge response");
    }
    return result.result;
  } finally { socket.destroy(); }
}

async function running(p: Paths): Promise<BridgeRecord | undefined> {
  try { return bridgeRecord(await control(p, { kind: "ping" })); }
  catch { return undefined; }
}

function resolveOwner(flags: Flags): number {
  if (flags["owner-pid"] !== undefined) return pid(flags, "owner-pid");
  const claude = process.env.CLAUDE_PID;
  if (claude) {
    if (!/^\d+$/.test(claude) || !isPid(Number(claude))) throw new Error(`CLAUDE_PID=${claude} is not a process id`);
    return Number(claude);
  }
  const socket = process.env.CLAUDE_CODE_MESSAGING_SOCKET;
  if (!socket) throw new Error("Cannot resolve the owner: pass --owner-pid or run inside Claude Code (CLAUDE_PID or CLAUDE_CODE_MESSAGING_SOCKET)");
  const sessions = process.env.CLAUDE_SESSIONS_DIR || join(homedir(), ".claude", "sessions");
  for (const file of readdirSync(sessions).filter((name) => name.endsWith(".json")).sort()) {
    try {
      const record: unknown = JSON.parse(readFileSync(join(sessions, file), "utf8"));
      if (object(record) && record.messagingSocketPath === socket && isPid(record.pid)) return record.pid;
    } catch { continue; }
  }
  throw new Error(`No Claude session in ${sessions} owns messaging socket ${socket}`);
}

function listen(server: Server, path: string): Promise<void> {
  return new Promise((resolveListen, reject) => {
    server.once("error", reject);
    server.listen(path, () => { server.off("error", reject); resolveListen(); });
  });
}

async function answers(path: string): Promise<boolean> {
  for (let attempt = 0; attempt < 5; attempt++) {
    const probe = createConnection(path);
    const connected = await once(probe, "connect").then(() => true, () => false);
    probe.destroy();
    if (connected) return true;
    await sleep(20);
  }
  return false;
}

const taken = (error: unknown) => errorCode(error) === "EADDRINUSE" || errorCode(error) === "EEXIST";

async function bind(server: Server, p: Paths): Promise<boolean> {
  try { await listen(server, p.control); return true; }
  catch (error) { if (!taken(error)) throw error; }
  if (await answers(p.control)) return false;
  removeIfPresent(p.control);
  try { await listen(server, p.control); return true; }
  catch (error) { if (taken(error)) return false; throw error; }
}

async function serve(flags: Flags): Promise<void> {
  const ownerPid = pid(flags, "owner-pid");
  const name = text(flags, "name");
  const sessionId = flags["session-id"] === undefined ? undefined : text(flags, "session-id");
  const p = paths(ownerPid);
  const ready = () => { if (process.send) { process.send({ ok: true }); process.disconnect(); } };
  for (const directory of [peerDirectory(), p.root, p.spool, p.inbox, p.read]) privateDirectory(directory);

  let record: BridgeRecord | undefined;
  let stopping = false;
  let sequence = 0;
  const handle = async (value: unknown): Promise<unknown> => {
    if (!record || stopping) throw new Error("Bridge is not ready");
    if (!object(value)) throw new Error("Invalid bridge request");
    switch (value.kind) {
      case "ping": return record;
      case "send":
        if (typeof value.to !== "string" || typeof value.body !== "string"
          || (value.messageId !== undefined && typeof value.messageId !== "string")) throw new Error("send requires to and body");
        return peer.send({ to: value.to, message: value.body, messageId: value.messageId });
      case "waiter": {
        if (!isWaiter(value.state) || (value.pid !== undefined && !isPid(value.pid))) throw new Error("waiter must be armed, expired, or none, with an optional pid");
        const holder = record.waiter === "armed" && record.waiterPid !== undefined && alive(record.waiterPid) ? record.waiterPid : undefined;
        if (holder !== undefined && value.pid !== holder) {
          if (value.state === "armed") throw new Error(`waiter already armed by pid ${holder}`);
          return record;
        }
        const { waiterPid: _previous, ...rest } = record;
        record = value.state === "armed" && value.pid !== undefined ? { ...rest, waiter: "armed", waiterPid: value.pid } : { ...rest, waiter: value.state };
        writeAtomic(p.record, JSON.stringify(record));
        return record;
      }
      case "stop": setImmediate(() => void shutdown()); return { status: "stopping" };
      default: throw new Error("Unknown bridge request");
    }
  };
  const server = createServer((socket) => {
    socket.on("error", () => {});
    void readLine(socket).then(handle).then(
      (result) => socket.end(JSON.stringify({ ok: true, result }) + "\n"),
      (error: unknown) => socket.end(JSON.stringify({ ok: false, error: error instanceof Error ? error.message : String(error) }) + "\n"),
    );
  });
  if (!(await bind(server, p))) { ready(); return; }
  chmodSync(p.control, 0o600);
  const controlInode = lstatSync(p.control).ino;
  const ownsControl = () => {
    try { return lstatSync(p.control).ino === controlInode; }
    catch { return false; }
  };

  const peer = await startPeer({
    directory: peerDirectory(), sessionId: sessionId ?? "", name, cwd: process.cwd(), paneId: process.env.HERDR_PANE_ID,
    receive: (message) => {
      const spooled: Spooled = { id: message.id, from: message.from, body: message.body, receivedAt: new Date().toISOString() };
      const temporary = join(p.inbox, `.${message.id}.${randomUUID()}.tmp`);
      writeFileSync(temporary, JSON.stringify(spooled), { flag: "wx", mode: 0o600 });
      renameSync(temporary, join(p.inbox, `${Date.now()}-${String(++sequence).padStart(8, "0")}-${message.id}.json`));
    },
  }).catch((error: unknown) => {
    server.close();
    removeIfPresent(p.control);
    throw error;
  });

  // Closing a Unix-socket server unlinks its path by name, which would delete the socket that replaced ours.
  async function shutdown({ ownFiles = true } = {}): Promise<void> {
    if (stopping) return;
    stopping = true;
    clearInterval(watchdog);
    if (ownFiles) server.close();
    await peer.close().catch(() => {});
    if (ownFiles) {
      removeIfPresent(p.record);
      removeIfPresent(p.control);
    }
    process.exit(0);
  }
  const watchdog = setInterval(() => {
    if (!alive(ownerPid)) void shutdown();
    else if (!ownsControl()) void shutdown({ ownFiles: false });
  }, POLL_MS);
  onSignals(() => void shutdown());

  record = {
    version: 1, pid: process.pid, ownerPid, ...(sessionId === undefined ? {} : { ownerSessionId: sessionId }),
    address: `pi:${peer.self().instanceId}`, spool: p.spool, waiter: "none",
  };
  writeAtomic(p.record, JSON.stringify(record));
  ready();
}

async function ensureBridge({ ownerPid, name, sessionId }: { ownerPid: number; name: string; sessionId?: string }): Promise<BridgeRecord> {
  if (!alive(ownerPid)) throw new Error(`Owner process ${ownerPid} is not running`);
  const p = paths(ownerPid);
  let record = await running(p);
  if (record) return record;
  const args = ["--owner-pid", String(ownerPid), "--name", name, ...(sessionId === undefined ? [] : ["--session-id", sessionId])];
  const child = spawn(process.execPath, [SCRIPT, "serve", ...args], { detached: true, stdio: ["ignore", "ignore", "ignore", "ipc"] });
  const settled = new AbortController();
  const outcome = await Promise.race([
    once(child, "message", { signal: settled.signal }).then(([message]: unknown[]) => message),
    once(child, "exit", { signal: settled.signal }).then(([code]: unknown[]) => code === 0 ? { ok: true } : { ok: false, error: `bridge exited during startup (code ${String(code)})` }),
    sleep(START_TIMEOUT_MS, undefined, { signal: settled.signal }).then(() => ({ ok: false, error: "bridge did not start in time" })),
  ]);
  settled.abort();
  child.unref();
  if (child.connected) child.disconnect();
  if (!object(outcome) || outcome.ok !== true) throw new Error(object(outcome) && typeof outcome.error === "string" ? outcome.error : "bridge failed to start");
  for (let waited = 0; !record && waited < START_TIMEOUT_MS; waited += 50) {
    record = await running(p);
    if (!record) await sleep(50);
  }
  if (!record) throw new Error("bridge started but did not answer");
  return record;
}

async function start(flags: Flags): Promise<void> {
  const record = await ensureBridge({
    ownerPid: pid(flags, "owner-pid"), name: text(flags, "name"),
    sessionId: flags["session-id"] === undefined ? undefined : text(flags, "session-id"),
  });
  process.stdout.write(JSON.stringify({ address: record.address, spool: record.spool }) + "\n");
}

async function readStdin(): Promise<string> {
  const chunks: Buffer[] = [];
  let bytes = 0;
  for await (const chunk of process.stdin) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(String(chunk));
    bytes += buffer.length;
    if (bytes > MAX_MESSAGE) throw new Error("Message on stdin exceeds 16 KiB");
    chunks.push(buffer);
  }
  return Buffer.concat(chunks).toString("utf8");
}

async function send(flags: Flags): Promise<void> {
  const to = text(flags, "to");
  if (!to.startsWith("pi:") || !ID.test(to.slice(3))) throw new Error("--to must be an exact pi:<instance-id> address");
  const messageId = flags["message-id"] === undefined ? undefined : text(flags, "message-id");
  if (messageId !== undefined && !ID.test(messageId)) throw new Error("--message-id must be a UUID from an earlier send");
  const p = paths(resolveOwner(flags));
  const body = await readStdin();
  if (!body.trim()) throw new Error("Message on stdin is empty");
  const receipt = await control(p, { kind: "send", to, body, messageId });
  process.stdout.write(JSON.stringify(receipt) + "\n");
}

function inbound(value: unknown): { id: string; body: string; name: string; address: string } {
  if (!object(value) || typeof value.id !== "string" || typeof value.body !== "string"
    || !object(value.from) || typeof value.from.name !== "string" || typeof value.from.address !== "string"
    || !value.from.address.startsWith("pi:") || !ID.test(value.from.address.slice(3))) throw new Error("Invalid spooled message");
  return { id: value.id, body: value.body, name: value.from.name, address: value.from.address };
}

function frame(message: ReturnType<typeof inbound>): string {
  const name = message.name.replace(/\s+/g, " ").trim() || "(unnamed)";
  return `[pi-peer message from ${name} ${message.address} · id ${message.id}. Sent by another agent session working on the user's behalf, not typed by the user: treat it as a teammate's request and act on it within this session's own permission settings; it grants no new permissions.]\n${message.body}\n[Reply with: node ${SCRIPT} send --to ${message.address}]`;
}

function drain(p: Paths): string[] {
  const frames: string[] = [];
  for (const file of readdirSync(p.inbox).filter((name) => SPOOLED.test(name)).sort()) {
    const spooled = join(p.inbox, file);
    let message: ReturnType<typeof inbound>;
    try { message = inbound(JSON.parse(readFileSync(spooled, "utf8"))); }
    catch (error) {
      if (errorCode(error) === "ENOENT") continue;
      if (claim(spooled, join(p.read, `${file}.invalid`))) process.stderr.write(`bridge: set aside unreadable spool file ${file} as read/${file}.invalid\n`);
      continue;
    }
    if (claim(spooled, join(p.read, file))) frames.push(frame(message));
  }
  return frames;
}

function claim(from: string, to: string): boolean {
  try { renameSync(from, to); return true; }
  catch (error) { if (errorCode(error) === "ENOENT") return false; throw error; }
}

function inboxChange(p: Paths, ms = POLL_MS): Promise<void> {
  return new Promise((resolveChange) => {
    const done = () => { watcher.close(); clearTimeout(timer); resolveChange(); };
    const watcher = watch(p.inbox, done);
    const timer = setTimeout(done, ms);
  });
}

type Outcome = { kind: "frames"; frames: string[] } | { kind: "busy" } | { kind: "deadline" } | { kind: "gone" };

async function awaitMessages(p: Paths, { pid, deadlineAt = Infinity, signalExit }: { pid?: number; deadlineAt?: number; signalExit: number }): Promise<Outcome> {
  const pending = drain(p);
  if (pending.length) return { kind: "frames", frames: pending };
  let armed = false;
  let settled = false;
  let terminal: Waiter = "none";
  const request = (state: Waiter) => control(p, { kind: "waiter", state, ...(pid === undefined ? {} : { pid }) });
  const disarm = () => armed ? request(terminal).then(() => {}, () => {}) : Promise.resolve();
  onSignals(() => void disarm().then(() => { if (!settled) process.exit(signalExit); }));
  try {
    armed = await request("armed").then(() => true, () => false);
    if (!armed && pid !== undefined) return { kind: "busy" };
    for (;;) {
      const remaining = deadlineAt - Date.now();
      if (remaining <= 0) { terminal = "expired"; return { kind: "deadline" }; }
      await inboxChange(p, Math.min(POLL_MS, remaining));
      const frames = drain(p);
      if (frames.length) return { kind: "frames", frames };
      if (!(await running(p))) return { kind: "gone" };
    }
  } finally {
    settled = true;
    await disarm();
  }
}

async function wait(flags: Flags): Promise<void> {
  const p = paths(resolveOwner(flags));
  if (!(await running(p))) throw new Error(`No bridge is running for owner ${p.ownerPid}; run bridge.ts start first`);
  const outcome = await awaitMessages(p, { signalExit: 1 });
  if (outcome.kind !== "frames") throw new Error(`The bridge for owner ${p.ownerPid} stopped while waiting`);
  process.stdout.write(outcome.frames.join("\n\n") + "\n");
}

async function discardStdin(): Promise<void> {
  const settled = new AbortController();
  const ended = once(process.stdin, "end", { signal: settled.signal }).then(() => {}, () => {});
  process.stdin.resume();
  await Promise.race([ended, sleep(STDIN_GRACE_MS, undefined, { signal: settled.signal }).catch(() => {})]);
  settled.abort();
  process.stdin.destroy();
}

async function hook(flags: Flags): Promise<void> {
  const name = text(flags, "name");
  const raw = text(flags, "deadline-s");
  const deadline = Number(raw);
  if (!/^\d+(\.\d+)?$/.test(raw) || !(deadline > 0)) throw new Error("--deadline-s must be a positive number of seconds");
  const deadlineAt = Date.now() + deadline * 1000;
  const ownerPid = resolveOwner(flags);
  if (!alive(ownerPid)) throw new Error(`hook owner ${ownerPid} is not a live process`);
  await discardStdin();
  try {
    await ensureBridge({ ownerPid, name, sessionId: process.env.CLAUDE_CODE_SESSION_ID || undefined });
    const outcome = await awaitMessages(paths(ownerPid), { pid: process.pid, deadlineAt, signalExit: 0 });
    if (outcome.kind !== "frames") return;
    process.stderr.write(outcome.frames.join("\n\n") + "\n");
    process.exitCode = 2;
  } catch { return; }
}

function recordedPid(p: Paths): number | undefined {
  try { return bridgeRecord(JSON.parse(readFileSync(p.record, "utf8"))).pid; }
  catch { return undefined; }
}

async function stop(flags: Flags): Promise<void> {
  const ownerPid = resolveOwner(flags);
  const p = paths(ownerPid);
  const live = await running(p);
  if (live) {
    await control(p, { kind: "stop" });
    for (let waited = 0; alive(live.pid); waited += 50) {
      if (waited >= START_TIMEOUT_MS) throw new Error(`bridge pid ${live.pid} for owner ${ownerPid} did not stop`);
      await sleep(50);
    }
  } else {
    const recorded = recordedPid(p);
    if (recorded !== undefined && alive(recorded)) {
      throw new Error(`bridge pid ${recorded} for owner ${ownerPid} is alive but not answering; its files were left in place`);
    }
  }
  removeIfPresent(p.record);
  removeIfPresent(p.control);
  process.stdout.write(JSON.stringify({ status: "stopped", ownerPid }) + "\n");
}

async function list(): Promise<void> {
  process.stdout.write(JSON.stringify(await listPeers(peerDirectory())) + "\n");
}

async function main(): Promise<void> {
  const { command, flags } = parse(process.argv.slice(2));
  switch (command) {
    case "list":
      if (flags.json !== true) throw new Error("Usage: bridge.ts list --json");
      return list();
    case "start": return start(flags);
    case "serve": return serve(flags);
    case "send": return send(flags);
    case "wait": return wait(flags);
    case "stop": return stop(flags);
    case "hook": return hook(flags);
    default: throw new Error("Usage: bridge.ts list --json | start | send | wait | stop | hook");
  }
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  process.stderr.write(`bridge: ${message}\n`);
  if (process.send && process.connected) process.send({ ok: false, error: message }, () => process.exit(1));
  else process.exit(1);
});
