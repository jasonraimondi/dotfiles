# Figma MCP bridge for pi

This global pi extension exposes a configured Figma MCP server through two pi tools:

- `figma_mcp_list_tools`
- `figma_mcp_call_tool`

## Location

- Extension: `~/.pi/agent/extensions/figma-mcp/index.ts`
- Package: `~/.pi/agent/extensions/figma-mcp/package.json`

## Configure

Set these environment variables in your shell config:

```bash
export FIGMA_MCP_COMMAND='npx'
export FIGMA_MCP_ARGS_JSON='["-y", "YOUR_FIGMA_MCP_SERVER_PACKAGE_OR_COMMAND"]'
```

Optional:

```bash
export FIGMA_MCP_CWD="$HOME"
export FIGMA_MCP_ENV_JSON='{"FIGMA_TOKEN":"your-token-if-your-server-needs-it"}'
```

Notes:

- `FIGMA_MCP_COMMAND` is the executable pi should spawn.
- `FIGMA_MCP_ARGS_JSON` must be a JSON array of strings.
- The extension also forwards your current process environment to the MCP server, so exported vars like `FIGMA_TOKEN` are available automatically.
- `FIGMA_MCP_ENV_JSON` lets you add or override env vars for the server process.

## Reload pi

After updating config:

```text
/reload
```

## Example prompts

- `List the available Figma MCP tools.`
- `Use the Figma MCP tools to inspect the design file.`
- `Call the right Figma MCP tool to fetch node ABC123 and summarize it.`

If the model does not know the exact MCP tool name yet, it should call `figma_mcp_list_tools` first.
