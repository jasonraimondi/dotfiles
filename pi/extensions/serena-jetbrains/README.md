# Serena JetBrains MCP bridge for pi

This pi extension starts Serena's MCP server and exposes its tools inside pi.

Default server command:

```bash
serena start-mcp-server \
  --transport stdio \
  --language-backend JetBrains \
  --context ide \
  --project-from-cwd \
  --enable-web-dashboard false \
  --open-web-dashboard false
```

`ide` context is used because pi already has file, edit, search, and shell tools. The extension additionally excludes Serena's basic file/shell tools by default, so the exposed `serena_*` wrappers stay focused on symbolic navigation, diagnostics, refactoring, and Serena session setup instructions.

## Prerequisites

1. Install Serena:

   ```bash
   uv tool install -p 3.13 serena-agent@latest --prerelease=allow
   serena init -b JetBrains
   ```

2. Install and enable the Serena JetBrains plugin in your JetBrains IDE.
3. Open the same project in JetBrains that you run pi from.
4. Install this extension's npm dependency once:

   ```bash
   cd pi/extensions/serena-jetbrains
   npm install
   ```

## Load

Temporary test:

```bash
pi -e pi/extensions/serena-jetbrains
```

Normal use in this repo:

```bash
./setup.sh
pi
```

`setup.sh` symlinks `pi/extensions` to `~/.pi/agent/extensions`, so pi auto-discovers this extension. If pi is already open, run:

```text
/reload
```

## Tools

Always available:

- `serena_mcp_status` — connection/status diagnostics
- `serena_mcp_list_tools` — list raw Serena MCP tools and schemas
- `serena_mcp_call_tool` — fallback raw MCP tool caller
- `serena_mcp_restart` — restart the Serena MCP process

After connection, each selected Serena MCP tool is also registered directly with the `serena_` prefix, for example:

- `serena_get_symbols_overview`
- `serena_find_symbol`
- `serena_find_referencing_symbols`
- `serena_rename_symbol`
- `serena_replace_symbol_body`

## Commands

- `/serena-status`
- `/serena-tools`
- `/serena-restart`

## Configuration

Environment variables:

```bash
# Optional path/name. Defaults to --project-from-cwd.
export SERENA_PROJECT="$PWD"

# Defaults shown below.
export SERENA_COMMAND="serena"
export SERENA_LANGUAGE_BACKEND="JetBrains"
export SERENA_CONTEXT="ide"
export SERENA_TOOL_PREFIX="serena_"

# Optional JSON arrays/objects.
export SERENA_EXTRA_ARGS_JSON='["--log-level", "DEBUG"]'
export SERENA_ENV_JSON='{"MY_ENV":"value"}'

# Tool filtering by raw Serena MCP name.
export SERENA_INCLUDE_TOOLS="find_symbol,find_referencing_symbols,rename_symbol"
export SERENA_EXCLUDE_TOOLS="execute_shell_command,read_file"

# Set to 1 if you want Serena's basic file/shell tools too.
export SERENA_INCLUDE_BASIC_TOOLS=1

# Lazy connect instead of connecting during pi startup.
export SERENA_CONNECT_ON_START=0
```

## Troubleshooting

If connection fails, make sure JetBrains is open with the project loaded and the Serena plugin is running, then run:

```text
/serena-restart
```

For diagnostics, ask pi to call `serena_mcp_status` or run `/serena-status`.
