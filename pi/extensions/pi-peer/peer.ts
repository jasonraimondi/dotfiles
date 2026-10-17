import { randomUUID } from "node:crypto";
import { chmod, lstat, mkdir, readFile, readdir, unlink, writeFile } from "node:fs/promises";
import { createConnection, createServer, type Socket } from "node:net";
import { join, resolve } from "node:path";

const PROTOCOL = 1;
const MAX_FRAME = 64 * 1024;
const MAX_MESSAGE = 16 * 1024;
const TIMEOUT_MS = 1500;
const ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

export type PeerInfo = {
  version: 1;
  instanceId: string;
  address: string;
  sessionId: string;
  name: string;
  cwd: string;
  pid: number;
  paneId: string;
  socketPath: string;
};
export type PeerMessage = { id: string; from: PeerInfo; body: string };
export type Receipt = { status: "accepted"; messageId: string; to: string };
export type Peer = Awaited<ReturnType<typeof startPeer>>;

type Options = {
  directory?: string;
  sessionId: string;
  name: string;
  cwd: string;
  paneId?: string;
  receive: (message: PeerMessage) => void;
};

function object(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function peerInfo(value: unknown): PeerInfo {
  if (!object(value) || value.version !== PROTOCOL || typeof value.instanceId !== "string" || !ID.test(value.instanceId)
    || value.address !== `pi:${value.instanceId}` || typeof value.sessionId !== "string"
    || typeof value.name !== "string" || typeof value.cwd !== "string" || typeof value.paneId !== "string"
    || typeof value.socketPath !== "string" || typeof value.pid !== "number" || !Number.isSafeInteger(value.pid) || value.pid <= 0) {
    throw new Error("Invalid pi-peer registry record");
  }
  return {
    version: PROTOCOL, instanceId: value.instanceId, address: `pi:${value.instanceId}`,
    sessionId: value.sessionId, name: value.name, cwd: value.cwd, pid: value.pid,
    paneId: value.paneId, socketPath: value.socketPath,
  };
}

export function peerDirectory(): string {
  if (!process.getuid) throw new Error("pi-peer currently requires macOS or Linux (Unix sockets)");
  return resolve(process.env.PI_PEER_DIR || `/tmp/pi-peer-${process.getuid()}`);
}

async function privateDirectory(directory: string): Promise<void> {
  if (!process.getuid) throw new Error("pi-peer currently requires macOS or Linux (Unix sockets)");
  await mkdir(directory, { recursive: true, mode: 0o700 });
  await checkPrivate(directory);
}

async function checkPrivate(directory: string): Promise<void> {
  const stat = await lstat(directory);
  if (!stat.isDirectory() || stat.uid !== process.getuid?.() || (stat.mode & 0o077) !== 0) {
    throw new Error(`pi-peer directory must be owned by you, not a symlink, and mode 0700: ${directory}`);
  }
}

function readFrame(socket: Socket): Promise<unknown> {
  return new Promise((resolveFrame, reject) => {
    let buffer = Buffer.alloc(0);
    const finish = (error?: Error, value?: unknown) => {
      socket.off("data", data);
      socket.off("error", fail);
      socket.off("end", ended);
      socket.off("close", closed);
      socket.off("timeout", timedOut);
      socket.setTimeout(0);
      if (error) reject(error);
      else resolveFrame(value);
    };
    const fail = (error: Error) => finish(error);
    const ended = () => finish(new Error("Peer closed before sending a complete frame"));
    const closed = () => finish(new Error("Peer connection closed"));
    const timedOut = () => { finish(new Error("Peer did not answer in time")); socket.destroy(); };
    const data = (chunk: Buffer) => {
      buffer = Buffer.concat([buffer, chunk]);
      if (buffer.length > MAX_FRAME) {
        finish(new Error("Peer frame exceeds 64 KiB"));
        socket.destroy();
        return;
      }
      const newline = buffer.indexOf(10);
      if (newline < 0) return;
      try { finish(undefined, JSON.parse(buffer.subarray(0, newline).toString("utf8"))); }
      catch { finish(new Error("Invalid peer JSON")); }
    };
    socket.on("data", data);
    socket.once("error", fail);
    socket.once("end", ended);
    socket.once("close", closed);
    socket.once("timeout", timedOut);
    socket.setTimeout(TIMEOUT_MS);
  });
}

async function request(socketPath: string, payload: unknown): Promise<unknown> {
  const socket = createConnection(socketPath);
  socket.on("error", () => {});
  try {
    const response = readFrame(socket);
    socket.write(JSON.stringify(payload) + "\n");
    const result = await response;
    if (!object(result) || result.ok !== true) {
      throw new Error(object(result) && typeof result.error === "string" ? result.error : "Invalid peer response");
    }
    return result.result;
  } finally { socket.destroy(); }
}

async function recordAt(directory: string, id: string): Promise<PeerInfo> {
  if (!ID.test(id)) throw new Error("Expected an exact pi:<instance-id> address from peer_sessions list");
  const path = join(directory, `${id}.json`);
  const stat = await lstat(path);
  if (!stat.isFile() || stat.uid !== process.getuid?.() || (stat.mode & 0o077) !== 0 || stat.size > MAX_FRAME) {
    throw new Error("Unsafe pi-peer registry file");
  }
  const record = peerInfo(JSON.parse(await readFile(path, "utf8")));
  if (record.instanceId !== id || record.socketPath !== join(directory, `${id}.sock`)) {
    throw new Error("Registry identity does not match its path");
  }
  return record;
}

async function liveRecord(directory: string, id: string): Promise<PeerInfo> {
  const record = await recordAt(directory, id);
  const live = peerInfo(await request(record.socketPath, { version: PROTOCOL, kind: "ping", to: id }));
  if (live.instanceId !== record.instanceId || live.pid !== record.pid || live.sessionId !== record.sessionId) {
    throw new Error("Peer identity changed; rediscover the session");
  }
  return live;
}

export async function listPeers(directory: string): Promise<PeerInfo[]> {
  try { await checkPrivate(directory); }
  catch (error) { if (object(error) && error.code === "ENOENT") return []; throw error; }
  const results: PeerInfo[] = [];
  const entries = (await readdir(directory)).filter((file) => file.endsWith(".json") && ID.test(file.slice(0, -5)));
  for (let index = 0; index < entries.length; index += 32) {
    const batch = await Promise.all(entries.slice(index, index + 32).map(async (file) => {
      try { return await liveRecord(directory, file.slice(0, -5)); }
      catch { return undefined; }
    }));
    results.push(...batch.filter((record) => record !== undefined));
  }
  return results.sort((a, b) => a.name.localeCompare(b.name) || a.instanceId.localeCompare(b.instanceId));
}

export async function startPeer(options: Options) {
  const directory = resolve(options.directory || peerDirectory());
  await privateDirectory(directory);
  const instanceId = randomUUID();
  const socketPath = join(directory, `${instanceId}.sock`);
  if (Buffer.byteLength(socketPath) > 100) throw new Error("PI_PEER_DIR is too long for a Unix socket; use a short private directory");
  const registryPath = join(directory, `${instanceId}.json`);
  const info: PeerInfo = {
    version: PROTOCOL, instanceId, address: `pi:${instanceId}`, sessionId: options.sessionId,
    name: (options.name || "(unnamed)").slice(0, 160), cwd: options.cwd, pid: process.pid,
    paneId: options.paneId || "", socketPath,
  };
  const sockets = new Set<Socket>();
  const accepted = new Map<string, string>();
  let closed = false;

  async function handle(value: unknown): Promise<PeerInfo | Receipt> {
    if (closed) throw new Error("Peer is shutting down");
    if (!object(value) || value.version !== PROTOCOL || value.to !== instanceId) throw new Error("Wrong peer or protocol version");
    if (value.kind === "ping") return { ...info };
    if (value.kind !== "send" || typeof value.from !== "string" || !ID.test(value.from)
      || typeof value.id !== "string" || !ID.test(value.id) || typeof value.body !== "string"
      || !value.body.trim() || Buffer.byteLength(value.body) > MAX_MESSAGE) throw new Error("Invalid peer message (limit 16 KiB)");
    if (value.from === instanceId) throw new Error("Cannot message yourself");
    const from = await liveRecord(directory, value.from);
    if (closed) throw new Error("Peer is shutting down");
    const key = `${from.instanceId}:${value.id}`;
    const previous = accepted.get(key);
    if (previous !== undefined && previous !== value.body) throw new Error("Message ID already used for different content");
    if (previous === undefined) {
      options.receive({ id: value.id, from, body: value.body });
      accepted.set(key, value.body);
      if (accepted.size > 1024) {
        const oldest = accepted.keys().next().value;
        if (oldest !== undefined) accepted.delete(oldest);
      }
    }
    return { status: "accepted", messageId: value.id, to: info.address };
  }

  const server = createServer((socket) => {
    sockets.add(socket);
    socket.on("error", () => {});
    socket.once("close", () => sockets.delete(socket));
    socket.unref();
    void readFrame(socket).then(handle).then(
      (result) => socket.end(JSON.stringify({ ok: true, result }) + "\n"),
      (error: unknown) => socket.end(JSON.stringify({ ok: false, error: error instanceof Error ? error.message : "Peer delivery failed" }) + "\n"),
    );
  });
  await new Promise<void>((resolveListen, reject) => {
    server.once("error", reject);
    server.listen(socketPath, () => { server.off("error", reject); resolveListen(); });
  });
  server.unref();

  async function close(): Promise<void> {
    if (closed) return;
    closed = true;
    for (const socket of sockets) socket.destroy();
    await new Promise<void>((resolveClose) => server.close(() => resolveClose()));
    await Promise.all([registryPath, socketPath].map(async (path) => {
      try { await unlink(path); }
      catch (error) { if (!object(error) || error.code !== "ENOENT") throw error; }
    }));
  }

  try {
    await chmod(socketPath, 0o600);
    await writeFile(registryPath, JSON.stringify(info), { flag: "wx", mode: 0o600 });
  } catch (error) { await close(); throw error; }

  return {
    self: (): PeerInfo => ({ ...info }),
    rename: (name: string): void => { info.name = (name || "(unnamed)").slice(0, 160); },
    async list(): Promise<PeerInfo[]> {
      if (closed) throw new Error("Peer is closed");
      return listPeers(directory);
    },
    async send({ to, message, messageId = randomUUID() }: { to: string; message: string; messageId?: string }): Promise<Receipt> {
      if (closed) throw new Error("Peer is closed");
      if (!to.startsWith("pi:") || !ID.test(to.slice(3))) throw new Error("Use an exact pi:<instance-id> address from peer_sessions list");
      if (to === info.address) throw new Error("Cannot message yourself");
      if (!ID.test(messageId) || !message.trim() || Buffer.byteLength(message) > MAX_MESSAGE) throw new Error("Message must be nonempty, at most 16 KiB, with a UUID messageId");
      try {
        const target = await liveRecord(directory, to.slice(3));
        const result = await request(target.socketPath, { version: PROTOCOL, kind: "send", to: target.instanceId, from: instanceId, id: messageId, body: message });
        if (!object(result) || result.status !== "accepted" || result.messageId !== messageId || result.to !== to) throw new Error("Invalid delivery receipt");
        return { status: "accepted", messageId, to };
      } catch (error) {
        throw new Error(`No acceptance confirmed for messageId=${messageId} to=${to}: ${error instanceof Error ? error.message : String(error)}. A timeout does not cancel delivery; inspect before retrying.`, { cause: error });
      }
    },
    close,
  };
}
