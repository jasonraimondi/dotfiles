import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import process from "node:process";

import { Client as McpClient } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const EXTENSION_VERSION = "0.1.0";
const MAX_OUTPUT_LINES = 2000;
const MAX_OUTPUT_BYTES = 50 * 1024;
const STDERR_TAIL_LIMIT = 12_000;
const DEFAULT_REQUEST_TIMEOUT_MS = 120_000;
const DIRECT_TOOL_STATUS_NAME = "serena_mcp_status";
const DIRECT_TOOL_LIST_NAME = "serena_mcp_list_tools";
const DIRECT_TOOL_CALL_NAME = "serena_mcp_call_tool";
const DIRECT_TOOL_RESTART_NAME = "serena_mcp_restart";
const DEFAULT_BASIC_TOOL_EXCLUDES = [
  "create_text_file",
  "read_file",
  "execute_shell_command",
  "replace_content",
  "find_file",
  "list_dir",
];

const EmptyParamsSchema = {
  type: "object",
  properties: {},
  additionalProperties: false,
} as const;

const StatusParamsSchema = {
  type: "object",
  properties: {
    connect: {
      type: "boolean",
      description: "Attempt to connect to Serena before returning status. Defaults to false.",
    },
  },
  additionalProperties: false,
} as const;

const ListToolsParamsSchema = {
  type: "object",
  properties: {
    refresh: {
      type: "boolean",
      description: "Refresh the tool list from Serena before returning it. Defaults to false.",
    },
    includeSchemas: {
      type: "boolean",
      description: "Include full MCP input/output schemas in the response. Defaults to true.",
    },
  },
  additionalProperties: false,
} as const;

const CallToolParamsSchema = {
  type: "object",
  properties: {
    tool: {
      type: "string",
      description: "Exact Serena MCP tool name to call, without the pi wrapper prefix.",
    },
    argumentsJson: {
      type: "string",
      description: "JSON object string containing the MCP tool arguments.",
    },
    refreshToolsFirst: {
      type: "boolean",
      description: "Refresh the Serena tool list before validating the tool name. Defaults to false.",
    },
  },
  required: ["tool", "argumentsJson"],
  additionalProperties: false,
} as const;

type JsonRecord = Record<string, unknown>;
type McpClientInstance = InstanceType<typeof McpClient>;
type McpTransportInstance = InstanceType<typeof StdioClientTransport>;

type McpTool = {
  name: string;
  title?: string;
  description?: string;
  inputSchema?: JsonRecord;
  outputSchema?: JsonRecord;
  annotations?: JsonRecord;
  execution?: JsonRecord;
  _meta?: JsonRecord;
};

type SerenaConfig = {
  command: string;
  args: string[];
  cwd: string;
  env: Record<string, string>;
  display: {
    command: string;
    args: string[];
    cwd: string;
    languageBackend: string;
    context: string;
    project?: string;
    projectFromCwd: boolean;
    toolPrefix: string;
    envOverrideKeys: string[];
  };
  key: string;
  requestTimeoutMs: number;
  toolPrefix: string;
  includeTools?: Set<string>;
  excludeTools: Set<string>;
};

type Truncation = {
  content: string;
  truncated: boolean;
  totalBytes: number;
  totalLines: number;
  outputBytes: number;
  outputLines: number;
};

type RegisteredSerenaTool = {
  piToolName: string;
  mcpToolName: string;
  description?: string;
};

let client: McpClientInstance | undefined;
let transport: McpTransportInstance | undefined;
let connectPromise: Promise<McpClientInstance> | undefined;
let activeConfigKey: string | undefined;
let connectingConfigKey: string | undefined;
let stderrTail = "";
let cachedTools: McpTool[] = [];
let registeredSerenaTools: RegisteredSerenaTool[] = [];
let instructions: string | undefined;
let connectedAt: string | undefined;
let lastError: string | undefined;

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

function parseCommaList(value: string | undefined): Set<string> | undefined {
  const items = value
    ?.split(",")
    .map((item) => item.trim())
    .filter(Boolean);
  if (!items || items.length === 0) return undefined;
  return new Set(items);
}

function envFlag(name: string, defaultValue: boolean): boolean {
  const value = process.env[name];
  if (value === undefined) return defaultValue;
  return !/^(0|false|no|off)$/i.test(value.trim());
}

function envNumber(name: string, defaultValue: number): number {
  const value = process.env[name];
  if (!value) return defaultValue;
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : defaultValue;
}

function getConfig(cwd: string): SerenaConfig {
  const command = trimToUndefined(process.env.SERENA_COMMAND) ?? "serena";
  const languageBackend = trimToUndefined(process.env.SERENA_LANGUAGE_BACKEND) ?? "JetBrains";
  const context = trimToUndefined(process.env.SERENA_CONTEXT) ?? "ide";
  const project = trimToUndefined(process.env.SERENA_PROJECT);
  const toolPrefix = trimToUndefined(process.env.SERENA_TOOL_PREFIX) ?? "serena_";
  const extraArgs = parseStringArrayEnv(process.env.SERENA_EXTRA_ARGS_JSON, "SERENA_EXTRA_ARGS_JSON");
  const extraEnv = parseStringRecordEnv(process.env.SERENA_ENV_JSON, "SERENA_ENV_JSON");
  const requestTimeoutMs = envNumber("SERENA_REQUEST_TIMEOUT_MS", DEFAULT_REQUEST_TIMEOUT_MS);
  const enableDashboard = envFlag("SERENA_ENABLE_WEB_DASHBOARD", false);
  const openDashboard = envFlag("SERENA_OPEN_WEB_DASHBOARD", false);
  const includeBasicTools = envFlag("SERENA_INCLUDE_BASIC_TOOLS", false);

  const args = [
    "start-mcp-server",
    "--transport",
    "stdio",
    "--language-backend",
    languageBackend,
    "--context",
    context,
    "--enable-web-dashboard",
    String(enableDashboard),
    "--open-web-dashboard",
    String(openDashboard),
  ];

  if (project) {
    args.push("--project", project);
  } else {
    args.push("--project-from-cwd");
  }

  args.push(...extraArgs);

  const configuredExcludes = parseCommaList(process.env.SERENA_EXCLUDE_TOOLS) ?? new Set<string>();
  const excludeTools = new Set<string>(configuredExcludes);
  if (!includeBasicTools) {
    for (const toolName of DEFAULT_BASIC_TOOL_EXCLUDES) excludeTools.add(toolName);
  }

  const display = {
    command,
    args,
    cwd,
    languageBackend,
    context,
    project,
    projectFromCwd: project === undefined,
    toolPrefix,
    envOverrideKeys: Object.keys(extraEnv).sort(),
  };

  return {
    command,
    args,
    cwd,
    env: {
      ...getProcessEnv(),
      ...extraEnv,
    },
    display,
    key: JSON.stringify(display),
    requestTimeoutMs,
    toolPrefix,
    includeTools: parseCommaList(process.env.SERENA_INCLUDE_TOOLS),
    excludeTools,
  };
}

function shellQuote(value: string): string {
  if (/^[A-Za-z0-9_./:=@+-]+$/.test(value)) return value;
  return JSON.stringify(value);
}

function formatCommand(config: SerenaConfig): string {
  return [config.command, ...config.args].map(shellQuote).join(" ");
}

function isRecord(value: unknown): value is JsonRecord {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
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
  instructions = undefined;
  connectedAt = undefined;
  cachedTools = [];
  registeredSerenaTools = [];
}

async function disconnect(): Promise<void> {
  const currentClient = client;
  const currentTransport = transport;
  clearConnectionState();

  if (currentClient) {
    await currentClient.close().catch(() => undefined);
    return;
  }

  if (currentTransport) {
    await currentTransport.close().catch(() => undefined);
  }
}

function normalizeTool(raw: unknown): McpTool | undefined {
  if (!isRecord(raw) || typeof raw.name !== "string" || raw.name.trim() === "") return undefined;

  return {
    name: raw.name,
    title: typeof raw.title === "string" ? raw.title : undefined,
    description: typeof raw.description === "string" ? raw.description : undefined,
    inputSchema: isRecord(raw.inputSchema) ? raw.inputSchema : undefined,
    outputSchema: isRecord(raw.outputSchema) ? raw.outputSchema : undefined,
    annotations: isRecord(raw.annotations) ? raw.annotations : undefined,
    execution: isRecord(raw.execution) ? raw.execution : undefined,
    _meta: isRecord(raw._meta) ? raw._meta : undefined,
  };
}

function isToolSelected(tool: McpTool, config: SerenaConfig): boolean {
  if (config.includeTools && !config.includeTools.has(tool.name)) return false;
  if (config.excludeTools.has(tool.name)) return false;
  return true;
}

async function refreshTools(currentClient: McpClientInstance, config: SerenaConfig): Promise<McpTool[]> {
  const tools: McpTool[] = [];
  let cursor: string | undefined;

  do {
    const result = await currentClient.listTools(
      cursor ? { cursor } : undefined,
      { timeout: config.requestTimeoutMs },
    );
    for (const rawTool of result.tools) {
      const tool = normalizeTool(rawTool);
      if (tool && isToolSelected(tool, config)) tools.push(tool);
    }
    cursor = typeof result.nextCursor === "string" ? result.nextCursor : undefined;
  } while (cursor);

  cachedTools = tools;
  return tools;
}

function safePiToolName(prefix: string, mcpToolName: string, used: Set<string>): string {
  const safePrefix = prefix.replace(/[^A-Za-z0-9_-]+/g, "_") || "serena_";
  const safeName = mcpToolName.replace(/[^A-Za-z0-9_-]+/g, "_");
  const base = `${safePrefix}${safeName}`.replace(/_+/g, "_");
  let candidate = base;
  let suffix = 2;
  while (used.has(candidate)) {
    candidate = `${base}_${suffix}`;
    suffix += 1;
  }
  used.add(candidate);
  return candidate;
}

function firstLine(value: string | undefined, fallback: string): string {
  const line = value?.split("\n").map((part) => part.trim()).find(Boolean);
  return line || fallback;
}

function normalizeInputSchema(tool: McpTool): JsonRecord {
  const schema = tool.inputSchema;
  if (schema && schema.type === "object") return schema;
  return {
    type: "object",
    properties: {},
    additionalProperties: true,
  };
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

function truncateHead(text: string): Truncation {
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
  const directory = mkdtempSync(join(tmpdir(), "pi-serena-mcp-"));
  const safeLabel = label.replace(/[^a-z0-9-_]+/gi, "-").toLowerCase();
  const path = join(directory, `${safeLabel || "output"}.txt`);
  writeFileSync(path, text, "utf8");
  return path;
}

function truncateForTool(label: string, text: string): { text: string; truncation?: Truncation; fullOutputPath?: string } {
  const truncation = truncateHead(text);
  if (!truncation.truncated) return { text: truncation.content };

  const fullOutputPath = writeFullOutput(label, text);
  const notice = [
    "",
    `[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines`,
    `(${formatBytes(truncation.outputBytes)} of ${formatBytes(truncation.totalBytes)}).`,
    `Full output saved to: ${fullOutputPath}]`,
  ].join(" ");

  return {
    text: `${truncation.content}\n${notice}`,
    truncation,
    fullOutputPath,
  };
}

function stringifyJson(label: string, value: unknown): { text: string; truncation?: Truncation; fullOutputPath?: string } {
  return truncateForTool(label, JSON.stringify(value, null, 2));
}

function mcpContentItemToText(item: unknown): string {
  if (!isRecord(item)) return JSON.stringify(item);

  if (item.type === "text" && typeof item.text === "string") return item.text;

  if (item.type === "image") {
    const mimeType = typeof item.mimeType === "string" ? item.mimeType : "image/*";
    const bytes = typeof item.data === "string" ? Buffer.byteLength(item.data, "base64") : undefined;
    return `[MCP image content: ${mimeType}${bytes === undefined ? "" : `, ${formatBytes(bytes)}`}]`;
  }

  if (item.type === "audio") {
    const mimeType = typeof item.mimeType === "string" ? item.mimeType : "audio/*";
    return `[MCP audio content: ${mimeType}]`;
  }

  if (item.type === "resource") {
    return `MCP resource content:\n${JSON.stringify(item.resource ?? item, null, 2)}`;
  }

  if (item.type === "resource_link") {
    return `MCP resource link:\n${JSON.stringify(item, null, 2)}`;
  }

  return JSON.stringify(item, null, 2);
}

function renderMcpResult(toolName: string, result: unknown): { text: string; truncation?: Truncation; fullOutputPath?: string } {
  const parts = [`Serena MCP tool: ${toolName}`];

  if (isRecord(result) && Array.isArray(result.content)) {
    const contentText = result.content.map(mcpContentItemToText).filter(Boolean).join("\n");
    if (contentText) parts.push("", contentText);

    if (result.structuredContent !== undefined) {
      parts.push("", "Structured content:", JSON.stringify(result.structuredContent, null, 2));
    }

    const extraKeys = Object.keys(result).filter(
      (key) => !["content", "structuredContent", "isError", "_meta"].includes(key),
    );
    if (extraKeys.length > 0) {
      const extras: JsonRecord = {};
      for (const key of extraKeys) extras[key] = result[key];
      parts.push("", "Additional result fields:", JSON.stringify(extras, null, 2));
    }
  } else {
    parts.push("", JSON.stringify(result, null, 2));
  }

  return truncateForTool(`serena-${toolName}`, parts.join("\n"));
}

function isMcpToolError(result: unknown): boolean {
  return isRecord(result) && result.isError === true;
}

function getKnownMcpToolNames(): string[] {
  return cachedTools.map((tool) => tool.name).sort((a, b) => a.localeCompare(b));
}

function buildStatus(connectivity: "connected" | "disconnected" | "connecting"): JsonRecord {
  return {
    status: connectivity,
    connectedAt,
    cachedToolCount: cachedTools.length,
    registeredPiToolCount: registeredSerenaTools.length,
    registeredPiTools: registeredSerenaTools,
    server: client
      ? {
          version: client.getServerVersion(),
          capabilities: client.getServerCapabilities(),
          instructionsAvailable: Boolean(instructions),
        }
      : undefined,
    stderrTail: stderrTail.trim() || undefined,
    lastError,
    config: activeConfigKey ? JSON.parse(activeConfigKey) : undefined,
  };
}

function buildStatusText(config: SerenaConfig | undefined, connectivity: "connected" | "disconnected" | "connecting"): string {
  const backend = config?.display.languageBackend ?? "JetBrains";
  const lines = [
    `Serena MCP bridge: ${connectivity}`,
    `Backend: ${backend} (via serena start-mcp-server --language-backend ${backend})`,
  ];

  if (config) {
    lines.push(`Command: ${formatCommand(config)}`);
    lines.push(`Working directory: ${config.display.cwd}`);
    lines.push(`Context: ${config.display.context}`);
    lines.push(`Project: ${config.display.project ?? "from cwd"}`);
    lines.push(`Pi tool prefix: ${config.display.toolPrefix}`);
  }

  if (connectedAt) lines.push(`Connected at: ${connectedAt}`);
  lines.push(`Cached Serena tools: ${cachedTools.length}`);
  lines.push(`Registered pi wrappers: ${registeredSerenaTools.length}`);

  if (lastError) {
    lines.push("", "Last error:", lastError);
  }

  if (stderrTail.trim()) {
    lines.push("", "Serena stderr tail:", stderrTail.trim());
  }

  return lines.join("\n");
}

async function callSerenaTool({
  currentClient,
  config,
  toolName,
  args,
  signal,
  onUpdate,
}: {
  currentClient: McpClientInstance;
  config: SerenaConfig;
  toolName: string;
  args: JsonRecord;
  signal?: AbortSignal;
  onUpdate?: (partialResult: { content: Array<{ type: "text"; text: string }>; details?: JsonRecord }) => void;
}) {
  const result = await currentClient.callTool(
    {
      name: toolName,
      arguments: args,
    },
    undefined,
    {
      signal,
      timeout: config.requestTimeoutMs,
      resetTimeoutOnProgress: true,
      onprogress(progress) {
        const parts = ["Serena is working"];
        if (typeof progress.message === "string") parts.push(progress.message);
        if (typeof progress.progress === "number") {
          parts.push(
            typeof progress.total === "number"
              ? `${progress.progress}/${progress.total}`
              : String(progress.progress),
          );
        }
        onUpdate?.({ content: [{ type: "text", text: parts.join(" · ") }] });
      },
    },
  );

  const rendered = renderMcpResult(toolName, result);
  const details = {
    mcpTool: toolName,
    isError: isMcpToolError(result),
    truncation: rendered.truncation,
    fullOutputPath: rendered.fullOutputPath,
  };

  if (isMcpToolError(result)) {
    throw new Error(rendered.text);
  }

  return {
    content: [{ type: "text" as const, text: rendered.text }],
    details,
  };
}

function registerMcpTools(pi: ExtensionAPI, tools: McpTool[], config: SerenaConfig): void {
  const reserved = new Set([
    DIRECT_TOOL_STATUS_NAME,
    DIRECT_TOOL_LIST_NAME,
    DIRECT_TOOL_CALL_NAME,
    DIRECT_TOOL_RESTART_NAME,
  ]);
  const registered: RegisteredSerenaTool[] = [];

  for (const tool of tools) {
    const piToolName = safePiToolName(config.toolPrefix, tool.name, reserved);
    registered.push({
      piToolName,
      mcpToolName: tool.name,
      description: tool.description,
    });

    pi.registerTool({
      name: piToolName,
      label: `Serena ${tool.title ?? tool.name}`,
      description: [
        `Call Serena MCP tool '${tool.name}' through a JetBrains-backed Serena server.`,
        tool.description,
      ]
        .filter(Boolean)
        .join("\n\n"),
      promptSnippet: `Serena JetBrains MCP: ${tool.name} — ${firstLine(tool.description, "symbol-aware code operation")}`,
      parameters: normalizeInputSchema(tool) as any,
      async execute(_toolCallId, params, signal, onUpdate, ctx) {
        const { currentClient, config: currentConfig } = await ensureClient(pi, ctx.cwd);
        const args = isRecord(params) ? params : {};
        return callSerenaTool({
          currentClient,
          config: currentConfig,
          toolName: tool.name,
          args,
          signal,
          onUpdate,
        });
      },
    });
  }

  registeredSerenaTools = registered;
}

async function connect(config: SerenaConfig, pi: ExtensionAPI): Promise<McpClientInstance> {
  stderrTail = "";
  lastError = undefined;

  const nextClient = new McpClient(
    { name: "pi-serena-jetbrains", version: EXTENSION_VERSION },
    {
      capabilities: {},
      listChanged: {
        tools: {
          async onChanged(error, updatedTools) {
            if (error) {
              appendStderr(`\n[tools/list_changed] ${String(error)}\n`);
              return;
            }
            const normalized = updatedTools
              .map(normalizeTool)
              .filter((tool): tool is McpTool => Boolean(tool))
              .filter((tool) => isToolSelected(tool, config));
            cachedTools = normalized;
            registerMcpTools(pi, cachedTools, config);
          },
        },
      },
    },
  );

  nextClient.onerror = (error) => {
    appendStderr(`\n[client] ${error.message}\n`);
  };

  nextClient.onclose = () => {
    if (client === nextClient) {
      clearConnectionState();
    }
  };

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

  try {
    await nextClient.connect(nextTransport, { timeout: config.requestTimeoutMs });
    transport = nextTransport;
    client = nextClient;
    activeConfigKey = config.key;
    connectedAt = new Date().toISOString();
    instructions = nextClient.getInstructions();
    await refreshTools(nextClient, config);
    registerMcpTools(pi, cachedTools, config);
    return nextClient;
  } catch (error) {
    await nextClient.close().catch(() => undefined);
    await nextTransport.close().catch(() => undefined);

    const stderrBlock = stderrTail.trim()
      ? `\n\nSerena stderr:\n${stderrTail.trim()}`
      : "";
    const message = `Failed to connect to Serena MCP server via stdio (${formatCommand(config)}). ${String(error)}${stderrBlock}`;
    lastError = message;
    throw new Error(message);
  }
}

async function ensureClient(pi: ExtensionAPI, cwd: string): Promise<{ currentClient: McpClientInstance; config: SerenaConfig }> {
  const config = getConfig(cwd);

  if (client && activeConfigKey === config.key) {
    return { currentClient: client, config };
  }

  if (connectPromise && connectingConfigKey === config.key) {
    const currentClient = await connectPromise;
    return { currentClient, config };
  }

  await disconnect();

  connectingConfigKey = config.key;
  connectPromise = connect(config, pi);
  try {
    const currentClient = await connectPromise;
    return { currentClient, config };
  } finally {
    connectPromise = undefined;
    connectingConfigKey = undefined;
  }
}

function activeSerenaToolNames(pi: ExtensionAPI): string[] {
  const active = new Set(pi.getActiveTools());
  return [
    DIRECT_TOOL_STATUS_NAME,
    DIRECT_TOOL_LIST_NAME,
    DIRECT_TOOL_CALL_NAME,
    DIRECT_TOOL_RESTART_NAME,
    ...registeredSerenaTools.map((tool) => tool.piToolName),
  ].filter((toolName) => active.has(toolName));
}

function buildSerenaPromptGuidance(config: SerenaConfig | undefined): string {
  const backend = config?.display.languageBackend ?? "JetBrains";
  const parts = [
    `Serena MCP bridge is available. It starts Serena with the ${backend} backend (\`--language-backend ${backend}\`).`,
    "Prefer direct `serena_*` tools for symbol-aware code navigation, reference lookup, diagnostics, and refactors. Use Pi's built-in read/edit/bash tools for ordinary file, text, or shell work.",
    "If a direct wrapper is unavailable or you need to inspect raw MCP metadata, use `serena_mcp_list_tools` then `serena_mcp_call_tool`.",
  ];

  if (config) {
    parts.push(
      `The current Serena context is \`${config.display.context}\` and project is \`${config.display.project ?? "derived from pi's cwd"}\`.`,
    );
  }

  if (instructions) {
    const trimmed = instructions.length > 4000 ? `${instructions.slice(0, 4000)}\n[Serena instructions truncated]` : instructions;
    parts.push(`Serena server instructions:\n${trimmed}`);
  }

  return parts.join("\n");
}

export default function serenaJetBrainsExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: DIRECT_TOOL_STATUS_NAME,
    label: "Serena MCP Status",
    description: "Show the status of the Serena MCP bridge and its JetBrains-backed server connection.",
    promptSnippet: "Show Serena MCP bridge status and connection diagnostics",
    parameters: StatusParamsSchema as any,
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      let config: SerenaConfig | undefined;
      let connectivity: "connected" | "disconnected" | "connecting" = connectPromise ? "connecting" : client ? "connected" : "disconnected";

      if (isRecord(params) && params.connect === true) {
        const result = await ensureClient(pi, ctx.cwd);
        config = result.config;
        connectivity = "connected";
      } else {
        config = client || connectPromise ? getConfig(ctx.cwd) : undefined;
      }

      const status = buildStatus(connectivity);
      const text = buildStatusText(config, connectivity);
      return {
        content: [{ type: "text", text }],
        details: status,
      };
    },
  });

  pi.registerTool({
    name: DIRECT_TOOL_LIST_NAME,
    label: "Serena MCP List Tools",
    description: "List the Serena MCP tools exposed by the JetBrains-backed Serena server.",
    promptSnippet: "List available Serena MCP tools and schemas",
    promptGuidelines: [
      "Use serena_mcp_list_tools when you need to discover Serena MCP tool names or raw argument schemas.",
    ],
    parameters: ListToolsParamsSchema as any,
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const { currentClient, config } = await ensureClient(pi, ctx.cwd);
      const shouldRefresh = isRecord(params) && params.refresh === true;
      const includeSchemas = !isRecord(params) || params.includeSchemas !== false;
      const tools = shouldRefresh || cachedTools.length === 0 ? await refreshTools(currentClient, config) : cachedTools;
      registerMcpTools(pi, tools, config);

      const payload = {
        transport: "stdio",
        config: config.display,
        toolPrefix: config.toolPrefix,
        toolCount: tools.length,
        tools: includeSchemas
          ? tools
          : tools.map((tool) => ({
              name: tool.name,
              title: tool.title,
              description: tool.description,
              piToolName: registeredSerenaTools.find((registered) => registered.mcpToolName === tool.name)?.piToolName,
            })),
      };

      const names = tools.map((tool) => {
        const piToolName = registeredSerenaTools.find((registered) => registered.mcpToolName === tool.name)?.piToolName;
        return `- ${tool.name}${piToolName ? ` (pi: ${piToolName})` : ""}`;
      });

      const rendered = stringifyJson("serena-tools", payload);
      const text = [
        "Serena MCP bridge connected via stdio.",
        `Backend: ${config.display.languageBackend}`,
        `Command: ${formatCommand(config)}`,
        `Available Serena tools: ${tools.length}`,
        ...names,
        "",
        "Tool metadata JSON:",
        rendered.text,
      ].join("\n");

      return {
        content: [{ type: "text", text }],
        details: {
          toolCount: tools.length,
          truncation: rendered.truncation,
          fullOutputPath: rendered.fullOutputPath,
        },
      };
    },
  });

  pi.registerTool({
    name: DIRECT_TOOL_CALL_NAME,
    label: "Serena MCP Call Tool",
    description: "Call a raw Serena MCP tool through the JetBrains-backed Serena server. Prefer direct serena_* wrappers when available.",
    promptSnippet: "Call a raw Serena MCP tool by name with a JSON arguments object",
    promptGuidelines: [
      "Prefer direct serena_* tools over serena_mcp_call_tool when a direct wrapper exists.",
      "Use serena_mcp_list_tools before serena_mcp_call_tool if you do not know the exact Serena MCP tool name and argument schema.",
      "Pass argumentsJson to serena_mcp_call_tool as a JSON object string.",
    ],
    parameters: CallToolParamsSchema as any,
    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      if (!isRecord(params) || typeof params.tool !== "string" || typeof params.argumentsJson !== "string") {
        throw new Error("tool and argumentsJson are required.");
      }

      const { currentClient, config } = await ensureClient(pi, ctx.cwd);
      if (params.refreshToolsFirst === true) {
        await refreshTools(currentClient, config);
        registerMcpTools(pi, cachedTools, config);
      }

      const knownToolNames = getKnownMcpToolNames();
      if (knownToolNames.length > 0 && !knownToolNames.includes(params.tool)) {
        throw new Error(
          [
            `Unknown Serena MCP tool: ${params.tool}`,
            "Known tools:",
            ...knownToolNames.map((toolName) => `- ${toolName}`),
            "Run serena_mcp_list_tools with refresh=true if the server changed.",
          ].join("\n"),
        );
      }

      const args = parseArgumentsJson(params.argumentsJson);
      return callSerenaTool({
        currentClient,
        config,
        toolName: params.tool,
        args,
        signal,
        onUpdate,
      });
    },
  });

  pi.registerTool({
    name: DIRECT_TOOL_RESTART_NAME,
    label: "Serena MCP Restart",
    description: "Restart the JetBrains-backed Serena MCP server and refresh direct serena_* tool wrappers.",
    promptSnippet: "Restart the Serena MCP bridge if the server disconnected or configuration changed",
    parameters: EmptyParamsSchema as any,
    async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
      await disconnect();
      const { config } = await ensureClient(pi, ctx.cwd);
      const text = buildStatusText(config, "connected");
      return {
        content: [{ type: "text", text }],
        details: buildStatus("connected"),
      };
    },
  });

  pi.registerCommand("serena-status", {
    description: "Show Serena MCP bridge status",
    handler: async (_args, ctx) => {
      const connectivity = connectPromise ? "connecting" : client ? "connected" : "disconnected";
      const config = client || connectPromise ? getConfig(ctx.cwd) : undefined;
      const text = buildStatusText(config, connectivity);
      ctx.ui.notify(text.split("\n")[0] ?? "Serena status unavailable", connectivity === "connected" ? "info" : "warning");
      pi.sendMessage({
        customType: "serena-mcp-status",
        content: text,
        display: true,
        details: buildStatus(connectivity),
      });
    },
  });

  pi.registerCommand("serena-restart", {
    description: "Restart Serena MCP bridge and refresh tools",
    handler: async (_args, ctx) => {
      ctx.ui.setStatus("serena", "Serena: restarting");
      await disconnect();
      try {
        const { config } = await ensureClient(pi, ctx.cwd);
        ctx.ui.setStatus("serena", `Serena: ${cachedTools.length} tools`);
        ctx.ui.notify(`Serena restarted (${cachedTools.length} tools, ${config.display.languageBackend})`, "info");
      } catch (error) {
        ctx.ui.setStatus("serena", "Serena: offline");
        ctx.ui.notify(`Serena restart failed: ${error instanceof Error ? error.message : String(error)}`, "error");
      }
    },
  });

  pi.registerCommand("serena-tools", {
    description: "Connect to Serena and show available MCP tools",
    handler: async (_args, ctx) => {
      try {
        const { currentClient, config } = await ensureClient(pi, ctx.cwd);
        await refreshTools(currentClient, config);
        registerMcpTools(pi, cachedTools, config);
        const names = registeredSerenaTools.map((tool) => `- ${tool.mcpToolName} (pi: ${tool.piToolName})`).join("\n");
        const text = `Serena tools (${cachedTools.length}):\n${names}`;
        pi.sendMessage({
          customType: "serena-mcp-tools",
          content: text,
          display: true,
          details: { tools: registeredSerenaTools },
        });
        ctx.ui.notify(`Serena has ${cachedTools.length} tools`, "info");
      } catch (error) {
        ctx.ui.notify(`Serena tool listing failed: ${error instanceof Error ? error.message : String(error)}`, "error");
      }
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    if (!envFlag("SERENA_CONNECT_ON_START", true)) {
      ctx.ui.setStatus("serena", "Serena: lazy");
      return;
    }

    ctx.ui.setStatus("serena", "Serena: connecting");
    try {
      const { config } = await ensureClient(pi, ctx.cwd);
      ctx.ui.setStatus("serena", `Serena: ${cachedTools.length} tools`);
      if (ctx.hasUI) {
        ctx.ui.notify(`Serena connected using ${config.display.languageBackend} backend (${cachedTools.length} tools)`, "info");
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      lastError = message;
      ctx.ui.setStatus("serena", "Serena: offline");
      if (ctx.hasUI) {
        ctx.ui.notify(
          `Serena JetBrains backend is offline. Start JetBrains with the Serena plugin, then run /serena-restart.`,
          "warning",
        );
      }
    }
  });

  pi.on("before_agent_start", (event, _ctx) => {
    const activeNames = activeSerenaToolNames(pi);
    if (activeNames.length === 0) return undefined;

    const config = client || connectPromise ? getConfig(event.systemPromptOptions.cwd) : undefined;
    return {
      systemPrompt: `${event.systemPrompt}\n\n${buildSerenaPromptGuidance(config)}`,
    };
  });

  pi.on("session_shutdown", async () => {
    await disconnect();
  });
}
