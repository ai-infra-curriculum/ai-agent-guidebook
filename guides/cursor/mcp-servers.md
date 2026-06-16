# MCP Servers in Cursor

How Cursor integrates the Model Context Protocol: where config lives, the config file shape for local and remote servers, one-click install, authentication, tool approval, and security.

---

## Table of Contents

- [What MCP Adds](#what-mcp-adds)
- [Where Config Lives](#where-config-lives)
- [Config File Shape](#config-file-shape)
- [stdio (Local) Servers](#stdio-local-servers)
- [Remote Servers: SSE and Streamable HTTP](#remote-servers-sse-and-streamable-http)
- [Variable Interpolation](#variable-interpolation)
- [Authentication and OAuth](#authentication-and-oauth)
- [One-Click Install and the UI](#one-click-install-and-the-ui)
- [Tool Approval](#tool-approval)
- [Debugging MCP](#debugging-mcp)
- [Security](#security)

---

## What MCP Adds

Cursor ships built-in tools (file ops, terminal, semantic search, web). The **Model Context Protocol** extends that surface with external **tools**, **prompts**, and **resources** — databases, issue trackers, browsers, internal APIs — without modifying Cursor itself. An MCP server is a process (local or remote) that speaks the protocol; Cursor discovers its tools and offers them to the agent.

Source: [Model Context Protocol (MCP)](https://cursor.com/docs/mcp).

---

## Where Config Lives

MCP servers are configured in `mcp.json`, at two scopes:

| Scope | File | When to use |
|-------|------|-------------|
| **Global** | `~/.cursor/mcp.json` | Servers you want in every project (your GitHub, your notes app) |
| **Project** | `<repo>/.cursor/mcp.json` | Servers the whole team should share for this repo (its database, its Sentry org) |

Project-scoped config can be committed to version control — keep secrets in environment variables, not in the file (see [Variable Interpolation](#variable-interpolation)).

Source: [MCP](https://cursor.com/docs/mcp).

---

## Config File Shape

Both files use the same top-level `mcpServers` object, keyed by a server name you choose:

```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "...",
      "args": ["..."],
      "env": { "...": "..." }
    }
  }
}
```

Cursor supports three transports: **stdio** (local), **SSE** (local/remote), and **Streamable HTTP** (local/remote).

---

## stdio (Local) Servers

A local server is a child process Cursor launches. Fields:

| Field | Required | Purpose |
|-------|----------|---------|
| `type` | optional | `"stdio"` (the default for command-based entries) |
| `command` | yes | Executable to run (e.g. `npx`, `python`, `node`, `uvx`) |
| `args` | no | Arguments passed to the command |
| `env` | no | Environment variables for the server process |
| `envFile` | no | Path to a `.env` file to load (stdio only) |

Example — a GitHub server and a read-only Postgres server, both local:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${env:GITHUB_TOKEN}"
      }
    },
    "postgres": {
      "command": "uvx",
      "args": ["mcp-server-postgres", "--read-only"],
      "envFile": "${workspaceFolder}/.env.local"
    }
  }
}
```

Source: [MCP](https://cursor.com/docs/mcp).

---

## Remote Servers: SSE and Streamable HTTP

A remote server is reached over HTTP. Use `url` (and optionally `headers` for auth). Remote servers do **not** support `envFile` — use [variable interpolation](#variable-interpolation) from your shell environment instead.

```json
{
  "mcpServers": {
    "internal-tools": {
      "url": "https://mcp.corp.internal/mcp",
      "headers": {
        "Authorization": "Bearer ${env:INTERNAL_MCP_TOKEN}"
      }
    }
  }
}
```

For an SSE endpoint, set the type explicitly:

```json
{
  "mcpServers": {
    "events": {
      "type": "sse",
      "url": "https://mcp.example.com/sse",
      "headers": { "Authorization": "Bearer ${env:EVENTS_TOKEN}" }
    }
  }
}
```

Prefer remote (HTTP/SSE) servers for anything the team shares; prefer stdio for personal tools and prototypes.

Source: [MCP](https://cursor.com/docs/mcp).

---

## Variable Interpolation

Cursor resolves variables in `command`, `args`, `env`, `url`, and `headers`:

| Variable | Resolves to |
|----------|-------------|
| `${env:NAME}` | Environment variable `NAME` from your shell/system |
| `${userHome}` | Your home directory |
| `${workspaceFolder}` | The project root |
| `${pathSeparator}` | OS path separator (`/` or `\`) |

This is how you keep secrets out of committed config: reference `${env:GITHUB_TOKEN}` in `.cursor/mcp.json` and export the actual value in your shell profile (or a secret manager) before launching Cursor.

Source: [MCP](https://cursor.com/docs/mcp).

---

## Authentication and OAuth

- **Token in header** — the common pattern for remote servers: `"Authorization": "Bearer ${env:TOKEN}"`.
- **Environment variables** — for stdio servers, pass credentials via `env` or `envFile`.
- **OAuth** — remote servers can use static OAuth credentials via an `auth` object (client ID, client secret, scopes). The first connection performs the flow; the server manages refresh.

<!-- needs-research: The exact JSON shape of the `auth`/OAuth object for remote MCP servers is documented but evolving. Confirm the current field names at https://cursor.com/docs/mcp before relying on a specific structure. -->

---

## One-Click Install and the UI

You can add MCP servers without hand-editing JSON:

- Browse the **Cursor MCP marketplace** (and community directories such as cursor.directory) and **one-click install** official and community servers.
- Manage servers in **Cursor Settings → MCP**: see connection status, enable/disable servers, and view the tools each exposes.

Hand-editing `mcp.json` remains the most precise option once you have several servers; validate it with a JSON linter before saving.

Source: [MCP integrations](https://cursor.com/help/customization/mcp).

---

## Tool Approval

When the agent wants to call an MCP tool, Cursor surfaces the call for approval (you can approve once, or trust a server/tool going forward). Treat write-capable tools (anything that mutates a database, files, or external state) more conservatively than read-only ones. On Team/Enterprise plans, admins can apply MCP access controls centrally.

---

## Debugging MCP

- **Server shows no tools.** It connected but `tools/list` is empty — usually a missing env var or a server that needs post-connection setup. Check the server's README and confirm `${env:...}` values are actually set in the shell that launched Cursor.
- **`npx`-based server is slow to start.** First run re-downloads the package. Pre-install it (`npm i -g`), use `uvx`, or switch to a long-running HTTP server.
- **Remote server `Connection refused` / 401.** Verify the URL is reachable from your machine (`curl -v <url>`) and that the token in `headers` is valid and exported.
- **Edited `mcp.json` but nothing changed.** Reload the MCP servers from **Settings → MCP**, or restart Cursor. Validate the JSON first (`jq empty .cursor/mcp.json`).

---

## Security

MCP servers are part of your attack surface — a server sees the prompts, tool arguments, and results the agent routes through it.

- **Pin versions.** Use `@scope/server@1.2.3`, not `@latest`.
- **Least privilege.** Give servers read-only credentials where possible (e.g. a read-only Postgres replica).
- **Keep secrets out of committed config.** Use `${env:...}` interpolation and a secret manager; never hardcode tokens in `.cursor/mcp.json`.
- **Review write-capable tools** before trusting them for unattended use; auto-approving a tool that can call arbitrary URLs is comparable to auto-approving shell access.
- **Audit installed servers** periodically and remove ones you no longer use.

For cross-tool governance (PII scrubbing, prompt-injection filtering, audit logging) across multiple AI assistants, see the governance discussion in the [Claude Code MCP guide](../claude-code/mcp-servers.md#agent-governance-layer).

Source: [MCP](https://cursor.com/docs/mcp).

---

## Related Guides

- [Cursor Guide (README)](README.md)
- [Cursor Installation](installation.md)
- [Cursor Usage](usage.md)
- [Cursor Rules and Context](rules-and-context.md)
- [Cursor Best Practices](best-practices.md)
- [Claude Code MCP Servers](../claude-code/mcp-servers.md)

---

**Last Updated**: 2026-06-16
</content>
