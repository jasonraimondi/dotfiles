import { mkdtempSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import process from "node:process";

import { Client as McpClient } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { Type } from "@sinclair/typebox";

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const MAX_OUTPUT_LINES = 2000;
const MAX_OUTPUT_BYTES = 50 * 1024;
const STDERR_TAIL_LIMIT = 8000;

type JsonRecord = Record<string, unknown>;

type FigmaMcpConfig = {
  command: string;
  args: string[];
  cwd?: string;
  env: Record<string, string>;
};

let client: InstanceType<typeof McpClient> | undefined;
let transport: InstanceType<typeof StdioClientTransport> | undefined;
let connectPromise: Promise<InstanceType<typeof McpClient>> | undefined;
let activeConfigKey: string | undefined;
let connectingConfigKey: string | undefined;
let stderrTail = "";
let cachedTools: unknown[] = [];

function trimToUndefined(value: string | undefined): string | undefined {
  const trimmed = value?.trim();
  return trimmed ? trimmed : undefined;
}

function getProcessEnv(): Record<string, string> {
  return Object.fromEntries(
    Object.entries(process.env).flatMap(([key, value]) =>
      typeof value === "string" ? [[key, value]] : [],
    ),
  );
}

function parseStringArrayEnv(value: string | undefined, variableName: string): string[] {
  if (!value) return [];

  let parsed: unknown;
  try {
    parsed = JSON.parse(value);
  } catch (error) {
    throw new Error(`${variableName} must be valid JSON. ${String(error)}`);
  }

  if (!Array.isArray(parsed) || parsed.some((item) => typeof item !== "string")) {
    throw new Error(`${variableName} must be a JSON array of strings.`);
  }

  return parsed;
}

function parseStringRecordEnv(value: string | undefined, variableName: string): Record<string, string> {
  if (!value) return {};

  let parsed: unknown;
  try {
    parsed = JSON.parse(value);
  } catch (error) {
    throw new Error(`${variableName} must be valid JSON. ${String(error)}`);
  }

  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error(`${variableName} must be a JSON object with string values.`);
  }

  const entries = Object.entries(parsed);
  if (entries.some(([, entryValue]) => typeof entryValue !== "string")) {
    throw new Error(`${variableName} must be a JSON object with string values.`);
  }

  return Object.fromEntries(entries) as Record<string, string>;
}

function parseArgumentsJson(argumentsJson: string): JsonRecord {
  let parsed: unknown;
  try {
    parsed = JSON.parse(argumentsJson);
  } catch (error) {
    throw new Error(`argumentsJson must be valid JSON. ${String(error)}`);
  }

  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("argumentsJson must be a JSON object.");
  }

  return parsed as JsonRecord;
}

function getConfig(): FigmaMcpConfig {
  const command = trimToUndefined(process.env.FIGMA_MCP_COMMAND);

  if (!command) {
    throw new Error(
      [
        "Figma MCP is not configured.",
        "Set FIGMA_MCP_COMMAND and FIGMA_MCP_ARGS_JSON before using this extension.",
        "Example:",
        "  export FIGMA_MCP_COMMAND='npx'",
        "  export FIGMA_MCP_ARGS_JSON='[\"-y\", \"YOUR_FIGMA_MCP_SERVER\"]'",
        "Then restart pi or run /reload.",
      ].join("\n"),
    );
  }

  const args = parseStringArrayEnv(process.env.FIGMA_MCP_ARGS_JSON, "FIGMA_MCP_ARGS_JSON");
  const extraEnv = parseStringRecordEnv(process.env.FIGMA_MCP_ENV_JSON, "FIGMA_MCP_ENV_JSON");
  const cwd = trimToUndefined(process.env.FIGMA_MCP_CWD);

  return {
    command,
    args,
    cwd,
    env: {
      ...getProcessEnv(),
      ...extraEnv,
    },
  };
}

function getConfigKey(config: FigmaMcpConfig): string {
  return JSON.stringify({
    command: config.command,
    args: config.args,
    cwd: config.cwd,
  });
}

function getDisplayConfig(config: FigmaMcpConfig) {
  return {
    command: config.command,
    args: config.args,
    cwd: config.cwd,
  };
}

function formatCommand(config: FigmaMcpConfig): string {
  return [config.command, ...config.args].join(" ").trim();
}

function appendStderr(chunk: string): void {
  stderrTail = `${stderrTail}${chunk}`;
  if (stderrTail.length > STDERR_TAIL_LIMIT) {
    stderrTail = stderrTail.slice(-STDERR_TAIL_LIMIT);
  }
}

function clearConnectionState(): void {
  client = undefined;
  transport = undefined;
  connectPromise = undefined;
  activeConfigKey = undefined;
  connectingConfigKey = undefined;
  cachedTools = [];
}

async function disconnect(): Promise<void> {
  const currentTransport = transport;
  clearConnectionState();
  if (currentTransport) {
    await currentTransport.close().catch(() => undefined);
  }
}

async function refreshTools(currentClient: InstanceType<typeof McpClient>): Promise<unknown[]> {
  const result = await currentClient.listTools();
  cachedTools = result.tools.map((tool) => ({
    name: tool.name,
    title: tool.title,
    description: tool.description,
    inputSchema: tool.inputSchema,
    outputSchema: tool.outputSchema,
    annotations: tool.annotations,
    execution: tool.execution,
  }));
  return cachedTools;
}

async function connect(config: FigmaMcpConfig): Promise<InstanceType<typeof McpClient>> {
  stderrTail = "";

  const nextClient = new McpClient(
    { name: "pi-figma-mcp", version: "0.1.0" },
    { capabilities: {} },
  );

  const nextTransport = new StdioClientTransport({
    command: config.command,
    args: config.args,
    cwd: config.cwd,
    env: config.env,
    stderr: "pipe",
  });

  nextTransport.stderr?.on("data", (chunk) => {
    appendStderr(String(chunk));
  });

  nextTransport.onclose = () => {
    if (transport === nextTransport) {
      clearConnectionState();
    }
  };

  try {
    await nextClient.connect(nextTransport);
    transport = nextTransport;
    client = nextClient;
    activeConfigKey = getConfigKey(config);
    await refreshTools(nextClient);
    return nextClient;
  } catch (error) {
    await nextTransport.close().catch(() => undefined);

    const stderrBlock = stderrTail.trim()
      ? `\n\nMCP server stderr:\n${stderrTail.trim()}`
      : "";

    throw new Error(
      `Failed to connect to Figma MCP server via stdio (${formatCommand(config)}). ${String(error)}${stderrBlock}`,
    );
  }
}

async function ensureClient(): Promise<{ currentClient: InstanceType<typeof McpClient>; config: FigmaMcpConfig }> {
  const config = getConfig();
  const configKey = getConfigKey(config);

  if (client && activeConfigKey === configKey) {
    return { currentClient: client, config };
  }

  if (connectPromise && connectingConfigKey === configKey) {
    const currentClient = await connectPromise;
    return { currentClient, config };
  }

  await disconnect();

  connectingConfigKey = configKey;
  connectPromise = connect(config);
  try {
    const currentClient = await connectPromise;
    return { currentClient, config };
  } finally {
    connectPromise = undefined;
    connectingConfigKey = undefined;
  }
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes}B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)}MB`;
}

function sliceUtf8ByBytes(text: string, maxBytes: number): string {
  if (Buffer.byteLength(text, "utf8") <= maxBytes) return text;

  let low = 0;
  let high = text.length;
  while (low < high) {
    const mid = Math.ceil((low + high) / 2);
    if (Buffer.byteLength(text.slice(0, mid), "utf8") <= maxBytes) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }

  return text.slice(0, low);
}

function truncateHead(text: string) {
  const totalBytes = Buffer.byteLength(text, "utf8");
  const totalLines = text === "" ? 0 : text.split("\n").length;

  let content = text;

  const lines = content.split("\n");
  if (lines.length > MAX_OUTPUT_LINES) {
    content = lines.slice(0, MAX_OUTPUT_LINES).join("\n");
  }

  if (Buffer.byteLength(content, "utf8") > MAX_OUTPUT_BYTES) {
    content = sliceUtf8ByBytes(content, MAX_OUTPUT_BYTES);
  }

  const outputBytes = Buffer.byteLength(content, "utf8");
  const outputLines = content === "" ? 0 : content.split("\n").length;

  return {
    content,
    truncated: content !== text,
    totalBytes,
    totalLines,
    outputBytes,
    outputLines,
  };
}

function writeFullOutput(label: string, text: string): string {
  const directory = mkdtempSync(join(tmpdir(), "pi-figma-mcp-"));
  const safeLabel = label.replace(/[^a-z0-9-_]+/gi, "-").toLowerCase();
  const path = join(directory, `${safeLabel || "output"}.json`);
  writeFileSync(path, text, "utf8");
  return path;
}

function renderJson(label: string, value: unknown): string {
  const fullText = JSON.stringify(value, null, 2);
  const truncated = truncateHead(fullText);

  if (!truncated.truncated) {
    return truncated.content;
  }

  const fullPath = writeFullOutput(label, fullText);
  return [
    truncated.content,
    "",
    `[Output truncated: ${truncated.outputLines} of ${truncated.totalLines} lines (${formatBytes(truncated.outputBytes)} of ${formatBytes(truncated.totalBytes)}). Full JSON saved to: ${fullPath}]`,
  ].join("\n");
}

function getKnownToolNames(): string[] {
  return cachedTools
    .map((tool) => (typeof tool === "object" && tool && "name" in tool ? tool.name : undefined))
    .filter((name): name is string => typeof name === "string");
}

export default function figmaMcpExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: "figma_mcp_list_tools",
    label: "Figma MCP List Tools",
    description: "List the tools exposed by the configured Figma MCP server",
    promptSnippet: "Inspect the configured Figma MCP server and list its available tools",
    promptGuidelines: [
      "Use this tool first when you need Figma MCP but do not know the exact MCP tool name or argument schema yet.",
    ],
    parameters: Type.Object({
      refresh: Type.Optional(Type.Boolean({ description: "Refresh the tool list from the MCP server before returning." })),
    }),
    async execute(_toolCallId, params) {
      const { currentClient, config } = await ensureClient();
      const tools = params.refresh ? await refreshTools(currentClient) : cachedTools.length > 0 ? cachedTools : await refreshTools(currentClient);

      const toolNames = getKnownToolNames();
      const summaryLines = [
        "Figma MCP bridge connected via stdio.",
        `Command: ${formatCommand(config)}`,
        `Available tools: ${toolNames.length}`,
        ...toolNames.map((toolName) => `- ${toolName}`),
      ];

      const payload = {
        transport: "stdio",
        config: getDisplayConfig(config),
        tools,
      };

      const text = `${summaryLines.join("\n")}\n\nFull tool metadata JSON:\n${renderJson("figma-tools", payload)}`;

      return {
        content: [{ type: "text", text }],
        details: payload,
      };
    },
  });

  pi.registerTool({
    name: "figma_mcp_call_tool",
    label: "Figma MCP Call Tool",
    description: "Call a specific tool on the configured Figma MCP server",
    promptSnippet: "Call a specific tool on the configured Figma MCP server using a JSON arguments object",
    promptGuidelines: [
      "Use figma_mcp_list_tools before this tool if you do not already know the exact Figma MCP tool name and its argument schema.",
      "Pass argumentsJson as a JSON object string.",
    ],
    parameters: Type.Object({
      tool: Type.String({ description: "Exact MCP tool name to call." }),
      argumentsJson: Type.String({ description: "JSON object string with the MCP tool arguments." }),
      refreshToolsFirst: Type.Optional(
        Type.Boolean({ description: "Refresh the MCP tool list before validating the tool name." }),
      ),
    }),
    async execute(_toolCallId, params) {
      const { currentClient, config } = await ensureClient();

      if (params.refreshToolsFirst) {
        await refreshTools(currentClient);
      }

      const argumentsObject = parseArgumentsJson(params.argumentsJson);
      const knownToolNames = getKnownToolNames();

      if (knownToolNames.length > 0 && !knownToolNames.includes(params.tool)) {
        throw new Error(
          [
            `Unknown Figma MCP tool: ${params.tool}`,
            "Known tools:",
            ...knownToolNames.map((toolName) => `- ${toolName}`),
            "Run figma_mcp_list_tools with refresh=true if the server changed.",
          ].join("\n"),
        );
      }

      const result = await currentClient.callTool({
        name: params.tool,
        arguments: argumentsObject,
      });

      const payload = {
        transport: "stdio",
        config: getDisplayConfig(config),
        tool: params.tool,
        arguments: argumentsObject,
        result,
      };

      const text = [
        `Called Figma MCP tool: ${params.tool}`,
        `Command: ${formatCommand(config)}`,
        "",
        renderJson(`figma-tool-${params.tool}`, payload),
      ].join("\n");

      if ("isError" in result && result.isError) {
        throw new Error(text);
      }

      return {
        content: [{ type: "text", text }],
        details: payload,
      };
    },
  });

  pi.on("session_shutdown", async () => {
    await disconnect();
  });
}
