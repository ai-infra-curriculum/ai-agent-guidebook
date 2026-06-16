# MCP Servers in VS Code

How VS Code consumes the Model Context Protocol: the `.vscode/mcp.json` config shape, secret prompts via `inputs`, variable substitution, user-level and auto-discovered servers, and the full MCP feature set (tools, resources, prompts, sampling, OAuth) that VS Code supports.

---

## Table of Contents

- [VS Code as an MCP Client](#vs-code-as-an-mcp-client)
- [`.vscode/mcp.json` vs Claude Code's `.mcp.json`](#vscodemcpjson-vs-claude-codes-mcpjson)
- [Server Configuration Fields](#server-configuration-fields)
- [stdio Servers](#stdio-servers)
- [HTTP and SSE Servers](#http-and-sse-servers)
- [Secret Prompts: the `inputs` Array](#secret-prompts-the-inputs-array)
- [Variable Substitution](#variable-substitution)
- [User-Level and Auto-Discovered Servers](#user-level-and-auto-discovered-servers)
- [Adding and Managing Servers](#adding-and-managing-servers)
- [The Full MCP Feature Set](#the-full-mcp-feature-set)
- [Dev Container MCP Config](#dev-container-mcp-config)
- [Organization Policy](#organization-policy)
- [Security Notes](#security-notes)
- [Related Guides](#related-guides)

---

## VS Code as an MCP Client

VS Code is a **full Model Context Protocol client**. It does not just consume MCP *tools* — it supports the whole specification: tools, resources, prompts (surfaced as slash commands), sampling (servers making their own model requests), and OAuth-based authorization. As of 2026 it also supports MCP Apps (interactive UI returned by servers).

Once a server is connected, its capabilities flow into [agent mode](agent-mode.md): tools appear in the tools picker and via `#`-references, resources can be attached as context, and prompts show up as `/mcp.server.prompt` slash commands.

If you already run MCP servers under Claude Code, the mental model is the same — long-running processes (or HTTP services) that expose typed tools — but the **config file and its top-level key differ**, which is the single most common source of confusion. That difference is the first thing to get right.

> Source: [Use MCP servers in VS Code](https://code.visualstudio.com/docs/copilot/customization/mcp-servers), [The Complete MCP Experience: Full Specification Support in VS Code](https://code.visualstudio.com/blogs/2025/06/12/full-mcp-spec-support).

---

## `.vscode/mcp.json` vs Claude Code's `.mcp.json`

The workspace MCP config lives at **`.vscode/mcp.json`** and is meant to be committed so the team shares the same servers.

The schema has up to three top-level keys: **`servers`**, `inputs`, and (on macOS/Linux) `sandbox`.

| | VS Code | Claude Code |
|---|---------|-------------|
| Workspace file | `.vscode/mcp.json` | `.mcp.json` (repo root) |
| Top-level server key | **`servers`** | **`mcpServers`** |
| Secret prompts | `inputs` array + `${input:id}` | env interpolation (`${VAR}`) |

If you copy a Claude Code `.mcp.json` into `.vscode/mcp.json` verbatim, **VS Code will not see your servers** — because it looks for `servers`, not `mcpServers`. This is the number-one "my MCP server won't show up" mistake.

Minimal valid file:

```json
{
  "servers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@microsoft/mcp-server-playwright"]
    }
  }
}
```

> Source: [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration).

---

## Server Configuration Fields

### stdio fields

| Field | Required | Type | Purpose |
|-------|----------|------|---------|
| `type` | yes | `"stdio"` | Local subprocess transport |
| `command` | yes | string | Executable (`npx`, `python`, `uvx`, …) |
| `args` | no | string[] | Command arguments |
| `cwd` | no | string | Working directory for the process |
| `env` | no | object | Environment variables (string/number/null) |
| `envFile` | no | string | Path to a `.env` file of variables |
| `dev` | no | object | Development-mode settings |
| `sandboxEnabled` | no | boolean | Apply filesystem/network restrictions to this server |

### http / sse fields

| Field | Required | Type | Purpose |
|-------|----------|------|---------|
| `type` | yes | `"http"` or `"sse"` | Remote transport (`http` is the modern default; `sse` is legacy) |
| `url` | yes | string | Server endpoint |
| `headers` | no | object | HTTP headers (auth tokens, etc.) |
| `oauth` | no | object | OAuth config (`clientId`, optional `enterpriseManaged`) |

> Source: [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration).

---

## stdio Servers

A local subprocess. VS Code launches `command` with `args`, speaks JSON-RPC over the process's stdin/stdout, and captures stderr for logs.

```json
{
  "servers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${workspaceFolder}"]
    },
    "postgres-dev": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-postgres", "--read-only"],
      "env": {
        "DATABASE_URL": "${env:DATABASE_URL}"
      }
    }
  }
}
```

stdio is best for personal and local tooling: zero network setup, OS-level process isolation, easy local secrets. The downside is a cold start on `npx`-based servers and one process per workspace.

---

## HTTP and SSE Servers

For remote and shared servers, use `http` (the modern streamable-HTTP transport). `sse` is the legacy server-sent-events transport, still supported for servers that haven't migrated.

```json
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp"
    },
    "internal-api": {
      "type": "http",
      "url": "https://mcp.corp.internal/mcp",
      "headers": {
        "Authorization": "Bearer ${input:internal-token}"
      }
    }
  }
}
```

For servers that support OAuth, give the `oauth` block a `clientId` and VS Code drives the browser flow; the GitHub MCP server, for instance, integrates with VS Code's built-in GitHub authentication so you don't manage a token at all.

---

## Secret Prompts: the `inputs` Array

Hardcoding API keys in a committed `.vscode/mcp.json` is an anti-pattern. VS Code's answer is the **`inputs`** array: VS Code prompts you for the value at server start, then substitutes it via `${input:id}`. The value is stored securely by VS Code, not in the file.

```json
{
  "inputs": [
    {
      "id": "internal-token",
      "type": "promptString",
      "description": "Internal MCP API token",
      "password": true
    },
    {
      "id": "region",
      "type": "pickString",
      "description": "Select region",
      "options": ["us-east", "eu-west", "asia-pacific"]
    }
  ],
  "servers": {
    "internal-api": {
      "type": "http",
      "url": "https://mcp.corp.internal/mcp",
      "headers": {
        "Authorization": "Bearer ${input:internal-token}",
        "X-Region": "${input:region}"
      }
    }
  }
}
```

Input types:

| `type` | Behavior | Notes |
|--------|----------|-------|
| `promptString` | Free-text prompt | Set `password: true` to mask the input |
| `pickString` | Dropdown | Requires `options: string[]` |
| `command` | Runs a VS Code command and uses its result | Requires `command: <commandId>` |

`id`, `type`, and `description` are required for every input. Input definitions cannot nest variables (no `${input:${env:X}}`), which prevents recursion.

> Source: [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration).

---

## Variable Substitution

Inside server config you can reference:

| Syntax | Resolves to |
|--------|-------------|
| `${input:id}` | An entry from the `inputs` array (prompted/secure) |
| `${env:VAR_NAME}` | An environment variable from VS Code's environment |
| `${workspaceFolder}` | The current workspace root path |
| `${pathSeparator}` or `${/}` | The platform path separator |

Use `${input:...}` for secrets you want VS Code to prompt for and store, and `${env:...}` for values already exported into the environment (e.g. by a shell profile or `direnv`). Avoid putting raw secrets directly in the file regardless.

> Source: [Variables reference](https://code.visualstudio.com/docs/reference/variables-reference), [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration).

---

## User-Level and Auto-Discovered Servers

### User-level config

Servers you want in *every* workspace (your GitHub MCP, your notes app) belong in the **user-level** MCP config, not the per-workspace file. Open it with Command Palette → **MCP: Open User Configuration**. It uses the same `servers`/`inputs` schema.

Precedence follows the usual pattern: workspace config is more specific than user config.

### Auto-discovery from other tools

VS Code can auto-discover MCP server configurations defined by other clients (for example, Claude Desktop) so you don't redefine them. This is governed by:

- `chat.mcp.discovery.enabled` — **disabled by default** (as of v1.104, Aug 2025). Enable it to pick up servers configured elsewhere.

> Source: [Use MCP servers in VS Code](https://code.visualstudio.com/docs/copilot/customization/mcp-servers).

---

## Adding and Managing Servers

You rarely have to hand-write the JSON. Command Palette commands:

| Command | What it does |
|---------|--------------|
| **MCP: Add Server** | Guided setup from an npm / PyPI / Docker package, a URL, or the gallery |
| **MCP: List Servers** | View configured servers, their status, start/stop/restart, and open logs |
| **MCP: Open User Configuration** | Edit the user-level `mcp.json` |
| **MCP: Browse Resources** | View and interact with resources exposed by servers |
| **MCP: Configure Model Access** | Restrict which models a server may use for sampling |

You can also install MCP servers from the Extensions view: open it (`⇧⌘X` / `Ctrl+Shift+X`) and search `@mcp` to browse the gallery.

When a server misbehaves, **MCP: List Servers → (server) → Show Output** is the first stop — it surfaces the server's stderr and the handshake, the same way `claude --debug` does for Claude Code.

> Source: [Add and manage MCP servers in VS Code](https://code.visualstudio.com/docs/agent-customization/mcp-servers).

---

## The Full MCP Feature Set

VS Code implements the complete MCP specification. What each capability means in practice:

| Capability | How it surfaces in VS Code |
|------------|----------------------------|
| **Tools** | Appear in the agent-mode tools picker; callable via `#tool` references |
| **Resources** | Browsable via `MCP: Browse Resources` or "Add Context → MCP Resource"; can be dragged into the workspace |
| **Prompts** | Surface as slash commands: `/mcp.servername.promptname` |
| **Sampling** | Servers can make their own model requests; the first request asks for authorization. Restrict with `MCP: Configure Model Access` |
| **Authorization (OAuth)** | Servers can delegate auth to an external identity provider; integrates with VS Code's built-in auth (e.g. GitHub) |
| **MCP Apps** | Interactive UI components returned by servers (added 2026) |

The practical takeaway: a VS Code MCP server can do more than a tool dump. Resources let you attach a server's documents or screenshots as context; prompts let a server ship reusable workflows as slash commands; sampling lets a server run its own sub-reasoning.

<!-- needs-research: MCP "roots" and "elicitation" are part of the spec but were not explicitly confirmed in the VS Code docs pages reviewed; verify their support status before claiming them. -->

> Source: [The Complete MCP Experience: Full Specification Support in VS Code](https://code.visualstudio.com/blogs/2025/06/12/full-mcp-spec-support), [Use MCP servers in VS Code](https://code.visualstudio.com/docs/copilot/customization/mcp-servers).

---

## Dev Container MCP Config

For reproducible environments, declare MCP servers in `devcontainer.json` under `customizations.vscode.mcp`. When the container is created, VS Code writes the servers into the container's `mcp.json`, so the servers are available inside the containerized environment.

```json
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:latest",
  "customizations": {
    "vscode": {
      "mcp": {
        "servers": {
          "playwright": {
            "command": "npx",
            "args": ["-y", "@microsoft/mcp-server-playwright"]
          }
        }
      }
    }
  }
}
```

> Source: [Use MCP servers in VS Code](https://code.visualstudio.com/docs/copilot/customization/mcp-servers).

---

## Organization Policy

In managed environments, admins gate MCP usage centrally rather than per-developer:

| Control | Purpose |
|---------|---------|
| `chat.mcp.access` | Org policy: `all` (any source), `registry` (only the curated registry), or `none` (MCP disabled). Replaces the deprecated `chat.mcp.enabled` |
| `McpGalleryServiceUrl` | Point developers at a private, curated MCP registry and block the public one |

For Copilot Business/Enterprise, additional MCP controls live in GitHub org settings.

> Source: [Manage AI settings in enterprise environments](https://code.visualstudio.com/docs/enterprise/ai-settings).

---

## Security Notes

An MCP server sees every prompt and tool result the agent routes through it — treat it as part of your attack surface.

- **Pin versions.** `npx -y @scope/server@1.2.3`, not `@latest`. A compromised upstream release is a supply-chain risk.
- **Least privilege.** Use a read-only Postgres replica, a namespaced k8s service account, scoped tokens. The Postgres example above passes `--read-only`.
- **Use `inputs`, not hardcoded secrets.** Committing a token in `.vscode/mcp.json` leaks it to everyone with repo access and to git history.
- **Use the `sandbox` block** (macOS/Linux) to constrain a server's filesystem and network reach when you don't fully trust it.
- **Scrutinize auto-approval.** A "fetch any URL" tool that's been auto-approved is equivalent to unattended network egress. See [best-practices.md](best-practices.md#approvals-and-trust).

The broader governance discussion — PII scrubbing, prompt-injection interception, audit logging in front of MCP servers — is the same regardless of client and is covered in the [Claude Code MCP guide](../claude-code/mcp-servers.md#agent-governance-layer) and the [MCP servers guide](../mcp-servers/guide.md).

> Source: [Use MCP servers in VS Code](https://code.visualstudio.com/docs/copilot/customization/mcp-servers), [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration).

---

## Related Guides

- [VS Code README](README.md) — the agentic surface overview
- [Agent Mode](agent-mode.md) — how MCP tools surface in the agent loop
- [Customization](customization.md) — instructions, custom agents, prompt files
- [Best Practices](best-practices.md) — approvals and security posture
- [MCP Servers Guide](../mcp-servers/guide.md) — protocol-level deep dive
- [Claude Code MCP Servers](../claude-code/mcp-servers.md) — the `.mcp.json`/`mcpServers` counterpart and governance patterns
- [GitHub Copilot Chat Guide](../github-copilot/chat-guide.md) — the Copilot Extensions → MCP migration

---

**Last Updated**: 2026-06-16
