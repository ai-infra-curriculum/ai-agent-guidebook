# Installing MCP Servers

How to install Model Context Protocol servers across the major hosts, the three main packaging models (npm, uvx, Docker), where each host stores config, how to manage secrets, and how to verify a server end-to-end with the Inspector.

> **Last updated**: 2026-06-11 · Tracks MCP spec **2025-11-25**.

---

## Table of Contents

- [Before you install](#before-you-install)
- [Three packaging models](#three-packaging-models)
- [Per-host installation](#per-host-installation)
  - [Claude Code](#claude-code)
  - [Claude Desktop](#claude-desktop)
  - [Cursor](#cursor)
  - [Cline](#cline)
  - [Continue](#continue)
  - [Windsurf](#windsurf)
  - [Zed](#zed)
  - [Custom clients (SDK)](#custom-clients-sdk)
- [Secrets and environment variables](#secrets-and-environment-variables)
- [Verifying an install with the Inspector](#verifying-an-install-with-the-inspector)
- [Common install failures and how to debug them](#common-install-failures-and-how-to-debug-them)

---

## Before you install

A pre-flight checklist that prevents most "it just doesn't work" reports:

1. **Pin runtimes.** Node ≥ 22 (24 is the active LTS; Node 20 hit end-of-life in April 2026), Python ≥ 3.11 (3.14 is current), `uv` ≥ 0.5.0, Docker ≥ 24. MCP SDKs drop support for old runtimes faster than most ecosystems.
2. **Check the server's transport.** stdio servers need to be spawnable as a subprocess; HTTP servers need a reachable URL. Don't paste an HTTP config into a stdio slot.
3. **Read the server's README.** Required env vars (tokens, connection strings, project IDs), scopes for OAuth tokens, and any "destructive ops require flag X" notes live there.
4. **Know your host's config path.** Different hosts read different files; see [Per-host installation](#per-host-installation).
5. **Have a test harness ready.** Install the [Inspector](https://github.com/modelcontextprotocol/inspector) before you wire a new server into your daily driver. Trying to debug a broken server through chat UI is miserable.

---

## Three packaging models

Almost every MCP server in the wild ships as one of:

### 1. npm (Node-based servers)

The dominant model for reference servers and most third-party JS/TS servers.

```bash
# One-shot run (no install)
npx -y @modelcontextprotocol/server-filesystem /path/to/workspace

# Global install
npm install -g @modelcontextprotocol/server-filesystem
```

`npx -y` is the most common pattern in MCP configs because the host re-runs it every session and you implicitly get the latest published version. The downside is supply-chain exposure on every launch; pin a version when that matters:

```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem@2026.1.14", "/path/to/workspace"]
}
```

### 2. uvx (Python-based servers)

`uvx` (from [`uv`](https://github.com/astral-sh/uv)) is the Python equivalent of `npx` — it runs a PyPI package in an ephemeral virtualenv. The reference Python servers and most newer Python servers use it.

```bash
# One-shot run
uvx mcp-server-git --repository /path/to/repo

# Pin version
uvx mcp-server-git==2026.6.4 --repository /path/to/repo
```

If you don't have `uv` installed:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh    # macOS / Linux
# or
brew install uv
# or
pipx install uv
```

For environments that don't allow `uvx`, the `pipx run` equivalent works for most servers:

```bash
pipx run mcp-server-git --repository /path/to/repo
```

### 3. Docker

Used when a server has heavy native dependencies (Playwright/Puppeteer, kubectl, full Postgres client) or when you want strict isolation.

```bash
docker run -i --rm \
  -v ~/.kube:/home/mcp/.kube:ro \
  quay.io/manusa/kubernetes_mcp_server
```

Notes for Docker-based MCP servers:

- Use `-i` (interactive) so the container keeps stdin open for stdio transport.
- Use `--rm` so leftover containers don't pile up across host restarts.
- Mount the minimum filesystem the server needs (`:ro` where possible).
- Avoid `-t` (TTY) — it corrupts the framing on some hosts.

A growing pattern is **Docker MCP Toolkit** (Docker Desktop ≥ 4.40) which provides a vetted catalog of containerized servers with a one-click install UX and a built-in OAuth flow. If you're managing many servers across a team, it's worth a look.

---

## Per-host installation

### Claude Code

Claude Code reads MCP config from a project-scoped `.mcp.json` (project scope) and from `~/.claude.json` (local and user scopes). The recommended workflow is the `claude mcp` CLI — stdio servers take the command after a `--` separator, HTTP servers take a URL:

```bash
# Add an stdio server (everything after -- is the launch command)
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem "$(pwd)"

# Add it to the project scope instead (writes .mcp.json, shareable with the team)
claude mcp add --scope project filesystem -- npx -y @modelcontextprotocol/server-filesystem "$(pwd)"

# Add a hosted HTTP server
claude mcp add --transport http github-hosted https://api.githubcopilot.com/mcp/

# Add with env vars (don't put secrets on the command line — see below)
claude mcp add fetch --env EXAMPLE_VAR='${EXAMPLE_VAR}' -- uvx mcp-server-fetch

# List installed servers
claude mcp list

# Remove a server
claude mcp remove filesystem
```

The resulting `.mcp.json` (project-scoped, commit-safe if it contains only `${VAR}` references) looks like:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/code/project"]
    },
    "github-hosted": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"],
      "env": {
        "EXAMPLE_VAR": "${EXAMPLE_VAR}"
      }
    }
  }
}
```

User-scoped and local-scoped servers live in `~/.claude.json` under the same `mcpServers` shape (`~/.claude/settings.json` holds permissions and other settings, never MCP server definitions). Project-scoped takes precedence on name collisions.

To restrict which tools a server may expose, use `permissions.allow` / `permissions.deny` in settings (see [`configuration.md`](./configuration.md)).

### Claude Desktop

Claude Desktop uses a single JSON file per platform:

| Platform | Config path |
|---|---|
| macOS | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Windows | `%APPDATA%\Claude\claude_desktop_config.json` |

(There is no official Claude Desktop build for Linux; on Linux use Claude Code or another MCP host.)

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/Documents"]
    },
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@brave/brave-search-mcp-server"],
      "env": { "BRAVE_API_KEY": "BSA_xxx" }
    }
  }
}
```

After editing, fully quit and relaunch Claude Desktop (the menu bar icon must disappear on macOS). The Settings → Developer pane shows server status and lets you tail logs at:

- macOS: `~/Library/Logs/Claude/mcp*.log`
- Windows: `%LOCALAPPDATA%\Claude\Logs\mcp*.log`

### Cursor

Cursor reads from `~/.cursor/mcp.json` (global) and `<project>/.cursor/mcp.json` (project). The schema matches Claude Desktop's `mcpServers` object. Cursor also supports the `type: "http"` transport for hosted servers and an inline UI under Settings → MCP.

```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": { "Authorization": "Bearer ${CONTEXT7_API_KEY}" }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/code"]
    }
  }
}
```

### Cline

Cline (VS Code extension) stores MCP config at:

| Platform | Config path |
|---|---|
| macOS | `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` |
| Linux | `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` |
| Windows | `%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json` |

The Cline MCP panel (Server icon in the Cline sidebar) provides a UI to add servers. Each server entry supports an `autoApprove` array — names of tools that don't require user confirmation. Keep this list tight; it is the most common cause of accidental destructive ops.

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/code"],
      "disabled": false,
      "autoApprove": ["read_file", "list_directory"]
    }
  }
}
```

### Continue

Continue (VS Code / JetBrains) configures MCP via `~/.continue/config.yaml` (or `config.json` for legacy installs):

```yaml
name: my-config
version: 1.0.0
schema: v1

mcpServers:
  - name: filesystem
    command: npx
    args:
      - "-y"
      - "@modelcontextprotocol/server-filesystem"
      - "/Users/me/code"
  - name: mongodb
    command: npx
    args:
      - "-y"
      - "mongodb-mcp-server"
    env:
      MDB_MCP_CONNECTION_STRING: ${{ secrets.MDB_MCP_CONNECTION_STRING }}
```

Continue resolves `${{ secrets.NAME }}` from its hub-managed secrets store, which is the cleanest way to keep tokens out of the YAML.

### Windsurf

Windsurf reads `~/.codeium/windsurf/mcp_config.json`. Same `mcpServers` shape as Claude Desktop. Windsurf's "Cascade" agent surfaces MCP tools in the chat alongside its native tools; tool-level allow/deny lives in Settings → Cascade → MCP.

### Zed

Zed configures MCP via `~/.config/zed/settings.json`:

```json
{
  "context_servers": {
    "filesystem": {
      "command": {
        "path": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/code"]
      }
    }
  }
}
```

Note Zed uses `context_servers` rather than `mcpServers` for historical reasons — same protocol, different config key.

### Custom clients (SDK)

If you're building an in-house host, the SDKs handle all the wire details. Minimal TypeScript client connecting to a local stdio server:

```ts
// package.json: "@modelcontextprotocol/sdk": "^1.29.0"
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

const transport = new StdioClientTransport({
  command: "npx",
  args: ["-y", "@modelcontextprotocol/server-filesystem", process.cwd()],
});

const client = new Client(
  { name: "my-host", version: "0.1.0" },
  { capabilities: {} }
);

await client.connect(transport);

const { tools } = await client.listTools();
console.log("Available tools:", tools.map((t) => t.name));

const result = await client.callTool({
  name: "read_file",
  arguments: { path: "README.md" },
});
console.log(result.content);

await client.close();
```

Python equivalent:

```python
# pip install "mcp>=1.27.0"
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def main():
    params = StdioServerParameters(
        command="uvx",
        args=["mcp-server-git", "--repository", "."],
    )
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = await session.list_tools()
            print([t.name for t in tools.tools])
            result = await session.call_tool("git_status", {})
            print(result.content)

asyncio.run(main())
```

For Streamable HTTP servers, swap the transport: `StreamableHTTPClientTransport` (TS) or `streamablehttp_client` (Python).

---

## Secrets and environment variables

Never commit a token to an MCP config file. The three good patterns:

### 1. `${VAR}` substitution

All major hosts expand `${VAR}` in `env` and `args` values from the host's environment at launch time. Pair this with a `.env` file or your shell's secret manager:

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}",
    "POSTGRES_CONNECTION_STRING": "${POSTGRES_CONNECTION_STRING}"
  }
}
```

Then export from your shell init:

```bash
# ~/.zshrc or ~/.bashrc
export GITHUB_PERSONAL_ACCESS_TOKEN=$(security find-generic-password -s "github-mcp" -w)
export POSTGRES_CONNECTION_STRING=$(op read "op://Personal/postgres/connection_string")
```

### 2. OS keychain via helper command

Some servers accept secrets via a helper command instead of an env var:

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN_COMMAND": "security find-generic-password -s github-mcp -w"
  }
}
```

(Server-specific — check the README. It's a clean pattern when supported.)

### 3. Hosted MCP servers with OAuth

The cleanest path: no token in your config at all. Hosted MCP servers (GitHub's, Sentry's, Stripe's, Linear's, Notion's, Atlassian's) use OAuth 2.1 — on first connect the host opens a browser, you authorize, and the host stores the resulting token in its keychain. The 2025-06-18 spec revision added Resource Indicators (RFC 8707), so tokens are scoped to a specific MCP server URL and can't be replayed against unrelated APIs.

```json
{
  "github": {
    "type": "http",
    "url": "https://api.githubcopilot.com/mcp/"
  }
}
```

### Anti-patterns to avoid

- **Hard-coded tokens** in a config file that's tracked by git. `git secrets`, `gitleaks`, and `trufflehog` exist for a reason — wire them into pre-commit.
- **Shared team tokens** instead of per-developer tokens. You lose attribution in the underlying service's audit log.
- **Over-scoped tokens** (e.g. `repo` when `public_repo` would do, full `admin:org` instead of `read:org`). Scope down to the minimum the agent needs.
- **Long-lived PATs** when fine-grained, expiring tokens are available. GitHub's fine-grained PATs and Stripe's restricted keys are the right defaults now.

---

## Verifying an install with the Inspector

The [`@modelcontextprotocol/inspector`](https://github.com/modelcontextprotocol/inspector) is the indispensable tool for verifying a server before you wire it into a host. It's a browser-based debugger that speaks MCP and shows you exactly what a host sees.

```bash
# Run against an stdio server
npx @modelcontextprotocol/inspector npx -y @modelcontextprotocol/server-filesystem /tmp

# Run against an stdio server with env vars
npx @modelcontextprotocol/inspector \
  -e BRAVE_API_KEY=BSA_xxx \
  npx -y @brave/brave-search-mcp-server

# Run against a Streamable HTTP server (CLI mode)
npx @modelcontextprotocol/inspector \
  --cli https://api.githubcopilot.com/mcp/ \
  --transport http
```

The Inspector opens a UI at `http://localhost:6274` (proxy server on 6277). The UI shows five tabs that map directly to the protocol surface:

1. **Connect** — capability negotiation. Confirm protocol version and the server's advertised capabilities.
2. **Resources** — list, read, and subscribe to resources.
3. **Prompts** — list and invoke prompts with arguments.
4. **Tools** — list tools, inspect schemas, invoke with sample inputs, view results.
5. **Notifications & logs** — server-side log messages and progress updates.

A standard verification flow for a new server:

1. Connect — see the capabilities banner; confirm spec version.
2. List tools — confirm count and names match the README.
3. Click each tool — verify the schema renders sensibly.
4. Invoke a low-risk read-only tool (e.g. `list_files`, `git_status`, `get_user`) — confirm a clean response.
5. Invoke one write tool with a throwaway target — confirm the side effect actually lands.
6. Inspect logs for warnings the host UI would normally swallow.

If the Inspector can't connect, the host won't either; debug here first.

---

## Common install failures and how to debug them

| Symptom | Likely cause | Fix |
|---|---|---|
| `spawn npx ENOENT` in host logs | Node not on PATH the host sees | Hosts launched from GUI on macOS don't see your shell's PATH. Use absolute paths: `"command": "/opt/homebrew/bin/npx"` or set `PATH` in `env`. |
| `Connection closed` immediately after launch | Server crashed during init | Run the same command in a terminal. Often a missing env var or unsupported Node version. Tail the host's MCP log. |
| Tools appear but every call returns "auth failed" | Token not being passed | Verify the env var is set in the *host's* environment (not just your shell). Confirm `${VAR}` substitution actually fired by hardcoding for a moment, then revert. |
| Server initializes but `tools/list` returns empty | Server advertised tools capability but registers no tools | Almost always a server-side bug; file an issue. As a workaround pin to an earlier working version. |
| Streamable HTTP returns 401 from a hosted server | OAuth flow never completed or token expired | Remove the server entry, re-add it, walk through the browser auth flow again. Check that your system clock is correct (OAuth is unforgiving about skew). |
| Server works in Inspector but not in Claude Desktop | Different working directory or env between the two | Hosts usually launch servers from `$HOME` with a minimal env. Either pass everything explicitly in `env` or wrap the command in a small shell script that sets up the environment. |
| `npx` re-downloads on every launch and it's slow | Cold cache | `npm install -g <pkg>` once, then point the config at the global install: `"command": "node", "args": ["/path/to/global/install/dist/index.js"]`. Or pre-warm the npx cache. |
| Server holds a stale token after rotation | Cached process | Restart the host. For stdio servers the process is per-session, but the host may keep it alive across reloads. |
| Tool calls hang forever | Server isn't writing newline-terminated JSON-RPC | stdio framing is line-delimited; a misbehaving server (often one that printed to stdout from a dependency) breaks the stream. Send all logs to stderr only. |

When all else fails, launch with `claude --debug` (Claude Code) or check the equivalent verbose-log flag for your host, run the server standalone in a terminal, and compare the JSON-RPC traffic against the spec. Claude Code also honors `MCP_TIMEOUT` (server startup timeout, ms) and `MCP_TOOL_TIMEOUT` (tool execution timeout, ms) env vars when slow servers look like failures.

---

## Next

- [`configuration.md`](./configuration.md) — full config reference, allowlists, per-project vs global, multi-instance.
- [`building.md`](./building.md) — build your own server in TypeScript or Python.
- [`catalog.md`](./catalog.md) — the catalog of available servers.
