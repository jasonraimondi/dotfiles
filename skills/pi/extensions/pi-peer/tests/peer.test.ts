import assert from "node:assert/strict";
import { chmod, mkdtemp, readFile, rm, stat, symlink, writeFile } from "node:fs/promises";
import { randomUUID } from "node:crypto";
import { join } from "node:path";
import { createConnection } from "node:net";
import { once } from "node:events";
import { setImmediate } from "node:timers/promises";
import { test } from "node:test";
import { startPeer, type PeerMessage } from "../peer.ts";

async function fixture(t: { after: (callback: () => Promise<void>) => void }) {
  const directory = await mkdtemp("/tmp/pi-peer-test-");
  t.after(() => rm(directory, { recursive: true, force: true }));
  const received: PeerMessage[] = [];
  const replies: PeerMessage[] = [];
  const sender = await startPeer({ directory, sessionId: "sender", name: "planner", cwd: "/a", receive: (message) => { replies.push(message); } });
  const receiver = await startPeer({ directory, sessionId: "receiver", name: "worker", cwd: "/b", receive: (message) => { received.push(message); } });
  t.after(() => sender.close());
  t.after(() => receiver.close());
  return { directory, received, replies, sender, receiver };
}

test("independent peers discover one another, exchange replies, and disappear on close", async (t) => {
  const { sender: parent, receiver: worker, received, replies } = await fixture(t);
  assert.deepEqual((await parent.list()).map((peer) => peer.name).sort(), ["planner", "worker"]);
  const receipt = await parent.send({ to: worker.self().address, message: "Review without editing." });
  assert.equal(receipt.status, "accepted");
  assert.equal(received[0]?.body, "Review without editing.");
  assert.equal(received[0]?.from.address, parent.self().address);
  await worker.send({ to: parent.self().address, message: "Review complete." });
  assert.equal(replies[0]?.body, "Review complete.");
  await worker.close();
  assert.deepEqual((await parent.list()).map((peer) => peer.name), ["planner"]);
  await assert.rejects(parent.send({ to: worker.self().address, message: "Are you there?" }));
});

test("duplicate names require exact addresses and retries inject the same message only once", async (t) => {
  const { received, sender, receiver } = await fixture(t);
  sender.rename("same");
  receiver.rename("same");
  assert.equal((await sender.list()).length, 2);
  await assert.rejects(sender.send({ to: "same", message: "ambiguous" }), /exact/);
  await assert.rejects(sender.send({ to: sender.self().address, message: "loop" }), /yourself/);
  const messageId = randomUUID();
  const request = { to: receiver.self().address, message: "one request\nwith unicode 💬", messageId };
  await Promise.all([sender.send(request), sender.send(request)]);
  assert.equal(received.length, 1);
  await assert.rejects(sender.send({ ...request, message: "changed" }), /different content/);
});

test("rejects oversized/empty messages and reports receiver refusal without acceptance", async (t) => {
  const { directory, received, sender, receiver } = await fixture(t);
  for (const message of [" ", "x".repeat(16385)]) {
    await assert.rejects(sender.send({ to: receiver.self().address, message }), /16 KiB/);
  }
  assert.equal(received.length, 0);
  const refusing = await startPeer({ directory, sessionId: "restricted", name: "restricted", cwd: "/", receive: () => { throw new Error("Messaging disabled"); } });
  t.after(() => refusing.close());
  await assert.rejects(sender.send({ to: refusing.self().address, message: "request" }), /Messaging disabled/);
});

test("private registry validates liveness and ignores malformed/stale records", async (t) => {
  const { directory, sender, receiver } = await fixture(t);
  const info = receiver.self();
  const record = join(directory, `${info.instanceId}.json`);
  assert.equal((await stat(record)).mode & 0o777, 0o600);
  assert.equal((await stat(info.socketPath)).mode & 0o777, 0o600);
  const stale = randomUUID();
  await writeFile(join(directory, `${stale}.json`), JSON.stringify({ ...info, instanceId: stale, address: `pi:${stale}`, socketPath: join(directory, `${stale}.sock`) }), { mode: 0o600 });
  await writeFile(join(directory, `${randomUUID()}.json`), "[]", { mode: 0o600 });
  assert.equal((await sender.list()).length, 2);
  const original = await readFile(record, "utf8");
  await writeFile(record, JSON.stringify({ ...info, sessionId: "wrong-session" }));
  assert.equal((await sender.list()).length, 1);
  await writeFile(record, original);
  receiver.rename("new-name");
  assert.equal((await sender.list()).find((peer) => peer.address === info.address)?.name, "new-name");
});

test("wire protocol handles fragmentation and rejects malformed or unregistered senders", async (t) => {
  const { receiver, received } = await fixture(t);
  async function exchange(parts: string[]): Promise<unknown> {
    const socket = createConnection(receiver.self().socketPath);
    await once(socket, "connect");
    try {
      for (const part of parts) { socket.write(part); await setImmediate(); }
      let response = "";
      for await (const chunk of socket) response += String(chunk);
      return JSON.parse(response);
    } finally { socket.destroy(); }
  }
  const ping = JSON.stringify({ version: 1, kind: "ping", to: receiver.self().instanceId }) + "\n";
  const live = await exchange([ping.slice(0, 12), ping.slice(12)]);
  assert.ok(typeof live === "object" && live !== null && "ok" in live && live.ok === true);
  for (const value of ["[broken]\n", "[]\n", JSON.stringify({ version: 2, kind: "ping", to: receiver.self().instanceId }) + "\n", JSON.stringify({ version: 1, kind: "send", to: receiver.self().instanceId, from: randomUUID(), id: randomUUID(), body: "not registered" }) + "\n"]) {
    const error = await exchange([value]);
    assert.ok(typeof error === "object" && error !== null && "ok" in error && error.ok === false);
  }
  assert.equal(received.length, 0);
});

test("fails closed for public or symlinked registry directories", async (t) => {
  const root = await mkdtemp("/tmp/pi-peer-test-");
  t.after(() => rm(root, { recursive: true, force: true }));
  const options = { directory: root, sessionId: "x", name: "x", cwd: "/", receive: () => {} };
  await chmod(root, 0o755);
  await assert.rejects(startPeer(options), /0700/);
  await chmod(root, 0o700);
  const link = join(root, "alias");
  await symlink(root, link);
  await assert.rejects(startPeer({ ...options, directory: link }), /symlink/);
});
