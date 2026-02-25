import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@mariozechner/pi-ai";

const DEFAULT_LINEAR_API_URL = "https://api.linear.app/graphql";
const MAX_OUTPUT_CHARS = 40_000;

type LinearRateLimit = {
  requestsLimit?: number;
  requestsRemaining?: number;
  requestsResetEpochMs?: number;
};

type LinearGraphQLError = {
  message?: string;
  extensions?: Record<string, unknown>;
  path?: Array<string | number>;
};

type LinearGraphQLResponse = {
  data?: unknown;
  errors?: LinearGraphQLError[];
};

function truncate(text: string): string {
  if (text.length <= MAX_OUTPUT_CHARS) return text;
  return `${text.slice(0, MAX_OUTPUT_CHARS)}\n\n[Output truncated: ${text.length - MAX_OUTPUT_CHARS} chars omitted]`;
}

function getLinearToken(): string | undefined {
  return (
    process.env.LINEAR_API_KEY ??
    process.env.LINEAR_TOKEN ??
    process.env.LINEAR_ACCESS_TOKEN
  );
}

function toAuthorizationHeaderValue(token: string): string {
  if (/^Bearer\s+/i.test(token)) return token;

  // Linear personal API keys are passed directly as Authorization: <API_KEY>.
  // OAuth access tokens should be passed as Authorization: Bearer <ACCESS_TOKEN>.
  if (token.startsWith("lin_api_")) return token;
  return `Bearer ${token}`;
}

function parseRateLimit(headers: Headers): LinearRateLimit {
  const toNumber = (value: string | null): number | undefined => {
    if (!value) return undefined;
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  };

  return {
    requestsLimit: toNumber(headers.get("X-RateLimit-Requests-Limit")),
    requestsRemaining: toNumber(headers.get("X-RateLimit-Requests-Remaining")),
    requestsResetEpochMs: toNumber(headers.get("X-RateLimit-Requests-Reset")),
  };
}

async function callLinearApi({
  query,
  variables,
  operationName,
}: {
  query: string;
  variables?: Record<string, unknown>;
  operationName?: string;
}): Promise<{ body: LinearGraphQLResponse; rateLimit: LinearRateLimit }> {
  const token = getLinearToken();
  if (!token) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TOKEN, or LINEAR_ACCESS_TOKEN env var. Create one in Linear > Settings > Security & access > Personal API keys, or provide an OAuth access token.",
    );
  }

  const response = await fetch(
    process.env.LINEAR_API_URL ?? DEFAULT_LINEAR_API_URL,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: toAuthorizationHeaderValue(token),
      },
      body: JSON.stringify({ query, variables, operationName }),
    },
  );

  const rateLimit = parseRateLimit(response.headers);
  const bodyText = await response.text();
  let body: LinearGraphQLResponse;

  try {
    body = JSON.parse(bodyText) as LinearGraphQLResponse;
  } catch {
    throw new Error(
      `Linear returned non-JSON response (${response.status}): ${truncate(bodyText)}`,
    );
  }

  if (!response.ok) {
    throw new Error(
      `Linear request failed (${response.status}): ${truncate(JSON.stringify({ body, rateLimit }, null, 2))}`,
    );
  }

  if (Array.isArray(body.errors) && body.errors.length > 0) {
    throw new Error(
      `Linear GraphQL error: ${truncate(JSON.stringify({ errors: body.errors, data: body.data, rateLimit }, null, 2))}`,
    );
  }

  return { body, rateLimit };
}

export default function linearToolsExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: "linear_whoami",
    label: "Linear Who Am I",
    description:
      "Fetch the authenticated Linear viewer profile to verify API access.",
    parameters: Type.Object({}),
    async execute() {
      const { body, rateLimit } = await callLinearApi({
        query: `query Viewer { viewer { id name email displayName admin } }`,
      });

      const text = truncate(JSON.stringify(body, null, 2));
      return {
        content: [{ type: "text", text }],
        details: { result: body, rateLimit },
      };
    },
  });

  pi.registerTool({
    name: "linear_api",
    label: "Linear API",
    description:
      "Execute a Linear GraphQL query or mutation. Requires LINEAR_API_KEY, LINEAR_TOKEN, or LINEAR_ACCESS_TOKEN.",
    parameters: Type.Object({
      query: Type.String({ description: "GraphQL query or mutation string" }),
      variablesJson: Type.Optional(
        Type.String({
          description: "Optional JSON object string for GraphQL variables",
        }),
      ),
      operationName: Type.Optional(
        Type.String({ description: "Optional GraphQL operation name" }),
      ),
    }),
    async execute(_toolCallId, params) {
      let variables: Record<string, unknown> | undefined;
      if (params.variablesJson) {
        try {
          const parsed = JSON.parse(params.variablesJson);
          if (
            typeof parsed !== "object" ||
            parsed === null ||
            Array.isArray(parsed)
          ) {
            throw new Error("variablesJson must be a JSON object");
          }
          variables = parsed as Record<string, unknown>;
        } catch (error) {
          throw new Error(
            `Invalid variablesJson: ${error instanceof Error ? error.message : "Could not parse JSON"}`,
          );
        }
      }

      const { body, rateLimit } = await callLinearApi({
        query: params.query,
        variables,
        operationName: params.operationName,
      });

      const text = truncate(JSON.stringify(body, null, 2));
      return {
        content: [{ type: "text", text }],
        details: { result: body, rateLimit },
      };
    },
  });
}
