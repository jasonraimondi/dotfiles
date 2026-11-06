import { execFileSync } from "node:child_process";
import net from "node:net";
import { planMove } from "./plan.js";

const herdr = process.env.HERDR_BIN_PATH ?? "herdr";
const delta = Number(process.argv[2]);
const workspaceId = process.env.HERDR_WORKSPACE_ID;

function request(method, params) {
  return new Promise((resolve, reject) => {
    const socket = net.connect(process.env.HERDR_SOCKET_PATH);
    let buffer = "";
    socket.on("connect", () => socket.write(`${JSON.stringify({ id: "move", method, params })}\n`));
    socket.on("data", (chunk) => {
      buffer += chunk;
      if (!buffer.includes("\n")) return;
      socket.end();
      const response = JSON.parse(buffer.split("\n")[0]);
      if (response.error) reject(new Error(JSON.stringify(response.error)));
      else resolve(response.result);
    });
    socket.on("error", reject);
  });
}

const { workspaces } = JSON.parse(execFileSync(herdr, ["workspace", "list"], { encoding: "utf8" })).result;
const plan = planMove(workspaces, workspaceId, delta);
if (!plan) {
  console.log("already at the edge");
} else {
  await request("workspace.move_block", plan);
}
