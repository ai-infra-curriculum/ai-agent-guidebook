# MCP Servers in VS Code

How VS Code consumes the Model Context Protocol: the two config formats (portable `mcpServers` and VS Code-native `servers`), which harness reads which file, secret prompts via `inputs`, variable substitution, discovery, sandboxing, policy, and the MCP features VS Code surfaces.

---

## Table of Contents

- [VS Code as an MCP Client](#vs-code-as-an-mcp-client)
- [Two Formats, Two Harnesses](#two-formats-two-harnesses)
- [Server Configuration Fields](#server-configuration-fields)
- [stdio Servers](#stdio-servers)
- [HTTP and SSE Servers](#http-and-sse-servers)
- [Secret Prompts: the `inputs` Array](#secret-prompts-the-inputs-array)
- [Variable Substitution](#variable-substitution)
- [User-Level and Auto-Discovered Servers](#user-level-and-auto-discovered-servers)
- [Adding and Managing Servers](#adding-and-managing-servers)
- [The MCP Feature Set](#the-mcp-feature-set)
- [Sandboxing MCP Servers](#sandboxing-mcp-servers)
- [Dev Container MCP Config](#dev-container-mcp-config)
- [Organization Policy](#organization-policy)
- [Security Notes](#security-notes)
- [Related Guides](#related-guides)

---

## VS Code as an MCP Client

VS Code is a **full Model Context Protocol client**. It does not just consume MCP *tools* — resources can be attached as context, prompts surface as slash commands, servers can use sign-in flows, and (experimentally) MCP Apps render interactive UI in chat.

Once a server is connected, its capabilities flow into [agent mode](agent-mode.md): tools become available to the agent and via `#`-references, resources can be attached as context, and prompts show up as `/<server>.<prompt>` slash commands.

If you already run MCP servers under Claude Code, the mental model is the same — long-running processes (or HTTP services) that expose typed tools. What changed in 2026 is that VS Code now has **two config formats**, and which one you want depends on the [harness](README.md#harnesses-who-runs-the-agent) you run.

> Source: [Add MCP servers](https://code.visualstudio.com/docs/agent-customization/mcp-servers), [The Complete MCP Experience: Full Specification Support in VS Code](https://code.visualstudio.com/blogs/2025/06/12/full-mcp-spec-support).

---

## Two Formats, Two Harnesses

| | **Portable format** | **VS Code format** |
|---|---------------------|--------------------|
| Top-level key | **`mcpServers`** | **`servers`** (+ optional `inputs`, `sandbox`) |
| Workspace file | `.mcp.json` at the workspace root | `.vscode/mcp.json` |
| User file | `~/.copilot/mcp-config.json` (or `$COPILOT_HOME/mcp-config.json`) | `mcp.json` in your VS Code user profile |
| Read by | **Copilot harness** (default) and compatible Copilot tools (Copilot CLI, Copilot app) | **Local harness**; eligible servers are forwarded to Copilot sessions |
| `inputs` / `envFile` / sandboxing | Not supported | Supported |
| Transports | stdio, HTTP (user file also SSE) | stdio, HTTP, SSE |

Practical guidance:

- **For the default Copilot harness**, put servers in `~/.copilot/mcp-config.json` (user) or `.mcp.json` (workspace). The workspace-root `.mcp.json` destination is offered when the experimental `chat.mcp.workspaceRootConfig.enabled` setting is on. These files are shared with the Copilot CLI — and `.mcp.json` with `mcpServers` is also the shape Claude Code uses.
- **Use `.vscode/mcp.json`** when you need VS Code-only features: `inputs` secret prompts, `envFile`, or per-server sandboxing. VS Code forwards eligible servers from it to Copilot sessions, but **skips servers that need interactive input** (such as `${input:...}` variables). The guided add flow now labels `.vscode/mcp.json` and the profile `mcp.json` as deprecated destinations, though they still work.
- **Don't copy between formats blindly.** A file with `mcpServers` dropped into `.vscode/mcp.json` won't load (that file expects `servers`), and vice versa. This is still the number-one "my MCP server won't show up" mistake.

Minimal portable file (`.mcp.json` or `~/.copilot/mcp-config.json`):

```json
{
  "mcpServers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@playwright/mcp@0.0.83"]
    }
  }
}
```

Minimal VS Code-format file (`.vscode/mcp.json`):

```json
{
  "servers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@playwright/mcp@0.0.83"]
    }
  }
}
```

VS Code's migration flow moves workspace `.vscode/mcp.json` to `.mcp.json` and the profile `mcp.json` to `~/.copilot/mcp-config.json` where the configuration is compatible.

> Source: [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration), [Add MCP servers](https://code.visualstudio.com/docs/agent-customization/mcp-servers), [Migrate existing customizations](https://code.visualstudio.com/docs/agent-customization/migrate-customizations).

---

## Server Configuration Fields

### stdio fields

| Field | Required | Purpose |
|-------|----------|---------|
| `type` | yes | `"stdio"` — local subprocess transport |
| `command` | yes | Executable on the PATH, or a full path (`npx`, `python`, `uvx`, …) |
| `args` | no | Command arguments |
| `cwd` | no | Working directory (defaults to the workspace folder; in portable format only the Copilot user file supports it) |
| `env` | no | Environment variables (string/number/null) |
| `envFile` | no | Path to an env file (VS Code format only) |
| `dev` | no | `watch` / `debug` development settings (VS Code format only) |
| `sandboxEnabled` | no | Apply filesystem/network restrictions (macOS/Linux, VS Code format) |
| `sandbox` | no | Per-server sandbox rules (see [Sandboxing](#sandboxing-mcp-servers)) |

### http / sse fields

| Field | Required | Purpose |
|-------|----------|---------|
| `type` | yes | `"http"` or `"sse"` — VS Code tries HTTP first and falls back to SSE |
| `url` | yes | Server endpoint (also `unix://` sockets or `pipe://` named pipes) |
| `headers` | no | HTTP headers (auth tokens, etc.) |
| `oauth` | no | Object with a required `clientId`; VS Code drives the OAuth flow (VS Code format only) |

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
      "args": ["-y", "@modelcontextprotocol/server-filesystem@2.0.0", "${workspaceFolder}"]
    },
    "git": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "${workspaceFolder}"]
    }
  }
}
```

stdio is best for personal and local tooling: zero network setup, OS-level process isolation, easy local secrets. The downside is a cold start on `npx`-based servers and one process per workspace.

---

## HTTP and SSE Servers

For remote and shared servers, use `http` (the streamable-HTTP transport). `sse` is the legacy server-sent-events transport, still supported for servers that haven't migrated.

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

For servers that support OAuth, give the `oauth` block a `clientId` and VS Code drives the browser flow; the GitHub MCP server, for instance, can use VS Code's built-in GitHub authentication so you don't manage a token yourself. Note that the second server above uses an `inputs` variable, so it works in the Local harness but will **not** be forwarded to Copilot-harness sessions.

---

## Secret Prompts: the `inputs` Array

Hardcoding API keys in a committed config file is an anti-pattern. In the **VS Code format**, the answer is the **`inputs`** array: VS Code prompts you for the value on first server start, then substitutes it via `${input:id}`. The value is stored securely by VS Code, not in the file.

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

| `type` | Properties | Notes |
|--------|------------|-------|
| `promptString` | `description` (required), `default`, `password` | Set `password: true` to mask the input |
| `pickString` | `description` (required), `options` (required), `default` | Dropdown |
| `command` | `command` (required), `args` | Runs a VS Code command and uses its result |

Every input needs a `type` and a unique `id`. The portable format has **no** `inputs` support — for Copilot-harness servers, pass secrets through the environment the server inherits, or use a server that supports OAuth.

> Source: [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration).

---

## Variable Substitution

Inside VS Code-format server config you can reference:

| Syntax | Resolves to |
|--------|-------------|
| `${input:id}` | An entry from the `inputs` array (prompted/secure) |
| `${workspaceFolder}` | The current workspace root (usable in `cwd`, `envFile`, sandbox paths) |
| `${userHome}` | Your home directory (usable in sandbox paths) |
| Other predefined variables (e.g. `${env:VAR_NAME}`) | See the VS Code [variables reference](https://code.visualstudio.com/docs/reference/variables-reference) |

Use `${input:...}` for secrets you want VS Code to prompt for and store. Avoid putting raw secrets directly in the file regardless.

> Source: [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration), [Variables reference](https://code.visualstudio.com/docs/reference/variables-reference).

---

## User-Level and Auto-Discovered Servers

### User-level config

Servers you want in *every* workspace (your GitHub MCP, your notes app) belong in user-level config, not the per-workspace file. For the Copilot harness that's `~/.copilot/mcp-config.json` (the **Copilot Global** destination in **MCP: Add Server**) — the same file the Copilot CLI reads, so a server added once works in both. For the Local harness, it's the `mcp.json` in your VS Code profile. Remote workspaces have their own user config (**MCP: Open Remote User Configuration**).

### Auto-discovery from other tools

VS Code can reuse MCP server configurations defined by other applications so you don't redefine them:

- **MCP: Add Server → Add from another application...** imports a configuration interactively.
- `chat.mcp.discovery.enabled` (default `false`) turns on automatic discovery.

> Source: [Add MCP servers](https://code.visualstudio.com/docs/agent-customization/mcp-servers), [Manage MCP servers](https://code.visualstudio.com/docs/agents/run/manage-mcp-servers), [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

---

## Adding and Managing Servers

You rarely have to hand-write the JSON.

| Command / surface | What it does |
|-------------------|--------------|
| **MCP: Add Server** | Guided setup: **HTTP** (a URL) or **Command (stdio)**, model-assisted **NPM Package** / **Pip Package** / **Docker Image**, **Browse MCP Servers...**, or **Add from another application...**; then choose a destination |
| **Chat: Open Customizations → MCP Servers** | Same add flow, plus per-server management; in the Copilot harness, tools are enabled on the **Tools** tab here |
| Extensions view, search `@mcp` | Browse the MCP server gallery (Preview) and **Install** / **Install in Workspace** |
| **MCP: List Servers** | Select a server to start/stop/restart it or **Show Output** |
| **MCP: Browse Resources** | View resources exposed by servers |
| **MCP: Reset Trust** | Reset MCP trust decisions (not Workspace Trust) |

When a server misbehaves, **MCP: List Servers → (server) → Show Output** is the first stop — it surfaces the server's stderr and the handshake, the same way `claude --debug` does for Claude Code.

**Trust and startup:** servers from workspace `.vscode/mcp.json` and `.mcp.json` inherit Workspace Trust — Restricted Mode prevents them from starting. `chat.mcp.autostart` (experimental, default `newAndOutdated`) starts servers that have never run or whose config changed when you send a chat message; set `never` to stop that, but note the Copilot harness may still start its own servers — disable a server to keep it off.

> Source: [Add MCP servers](https://code.visualstudio.com/docs/agent-customization/mcp-servers), [Manage MCP servers](https://code.visualstudio.com/docs/agents/run/manage-mcp-servers).

---

## The MCP Feature Set

What each capability means in practice:

| Capability | How it surfaces in VS Code |
|------------|----------------------------|
| **Tools** | Available to the agent; callable via `#` references; selected per request (Local) or on the Customizations **Tools** tab (Copilot) |
| **Resources** | **Add Context → MCP Resources** or **MCP: Browse Resources** |
| **Prompts** | Slash commands: `/<server>.<prompt>` |
| **Authentication** | Servers can trigger sign-in flows; `oauth` + `clientId` in VS Code format |
| **MCP Apps** (Experimental) | Interactive forms or visualizations rendered in chat (`chat.mcp.apps.enabled`) |
| **Sampling** | Supported since VS Code's 2025 full-spec release (servers make their own model requests, with user authorization); not covered in the current harness docs, so verify behavior in your harness |

The practical takeaway: a VS Code MCP server can do more than a tool dump. Resources let you attach a server's documents or screenshots as context; prompts let a server ship reusable workflows as slash commands.

> Source: [Add MCP servers](https://code.visualstudio.com/docs/agent-customization/mcp-servers), [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration), [Full MCP spec support (2025)](https://code.visualstudio.com/blogs/2025/06/12/full-mcp-spec-support).

---

## Sandboxing MCP Servers

Two separate mechanisms:

1. **Copilot-harness agent sandbox.** When `chat.agent.sandbox.enabled` is `"on"`, `chat.agent.sandbox.mcpServers` (default `true`) also sandboxes MCP servers started for the session. See [agent-mode.md](agent-mode.md#agent-sandboxing).
2. **Per-server sandbox (VS Code format, macOS/Linux only — not Windows).** Set `sandboxEnabled: true` on a stdio server, optionally with a `sandbox` block:

```json
{
  "servers": {
    "untrusted-tool": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@your-org/untrusted-mcp-server@1.0.0"],
      "sandboxEnabled": true,
      "sandbox": {
        "filesystem": { "allowWrite": ["${workspaceFolder}/tmp"], "denyRead": ["${userHome}/.ssh"] },
        "network": { "allowedDomains": ["api.example.com"] }
      }
    }
  }
}
```

Server-level `sandbox` supports `filesystem.allowWrite`, `filesystem.denyRead`, `filesystem.denyWrite`, `network.allowedDomains` (wildcards allowed), and `network.deniedDomains`. A top-level `sandbox` block applies **deny** rules only (allow rules there are ignored). Tool confirmations for a sandboxed server are auto-approved — so the sandbox rules are doing the protecting; make them tight.

> Source: [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration), [Manage MCP servers](https://code.visualstudio.com/docs/agents/run/manage-mcp-servers).

---

## Dev Container MCP Config

For reproducible environments, declare MCP servers in `devcontainer.json` under `customizations.vscode.mcp`. When the container is created, VS Code writes the servers into the remote `mcp.json`, so they are available inside the container (forwarding restrictions to Copilot sessions still apply).

```json
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:latest",
  "customizations": {
    "vscode": {
      "mcp": {
        "servers": {
          "playwright": {
            "type": "stdio",
            "command": "npx",
            "args": ["-y", "@playwright/mcp@0.0.83"]
          }
        }
      }
    }
  }
}
```

> Source: [Manage MCP servers](https://code.visualstudio.com/docs/agents/run/manage-mcp-servers).

---

## Organization Policy

In managed environments, admins gate MCP usage centrally rather than per-developer. Local configuration can't override organizational restrictions.

| Policy | Purpose |
|--------|---------|
| `ChatMCP` (`chat.mcp.access`) | Controls access to installed MCP servers |
| `ChatAllowedMcpServers` | Allowlist — only matching servers can be installed or run |
| `ChatDeniedMcpServers` | Denylist — takes precedence over the allowlist |
| `ChatAllowManagedMcpServersOnly` | Only the enterprise-managed allowlist decides what may run |
| `McpGalleryServiceUrl` | Point developers at a private MCP gallery service |
| `McpEnterpriseManagedAuthIdp` | OAuth/OIDC identity provider for enterprise-managed MCP authentication |
| `ChatStrictPluginOnlyCustomization` | Block standalone MCP servers (and other customizations) outside approved plugins |

For Copilot Business/Enterprise, additional MCP controls (including an MCP registry/allowlist) live in GitHub organization and enterprise settings.

> Source: [Enterprise policies](https://code.visualstudio.com/docs/enterprise/policies).

---

## Security Notes

An MCP server sees every prompt and tool result the agent routes through it — treat it as part of your attack surface.

- **Pin versions.** `npx -y @scope/server@1.2.3`, not `@latest`. A compromised upstream release is a supply-chain risk.
- **Least privilege.** Use read-only database roles, namespaced k8s service accounts, scoped tokens.
- **Use `inputs` or OAuth, not hardcoded secrets.** Committing a token in `.vscode/mcp.json` or `.mcp.json` leaks it to everyone with repo access and to git history.
- **Sandbox servers you don't fully trust** — per-server `sandboxEnabled` (macOS/Linux) or the Copilot-harness agent sandbox.
- **Mind Workspace Trust.** Opening an untrusted repo in Restricted Mode keeps its MCP servers from starting — don't trust a folder just to make a server appear.
- **Scrutinize auto-approval.** A "fetch any URL" tool that's been auto-approved is equivalent to unattended network egress. See [best-practices.md](best-practices.md#approvals-and-trust).

The broader governance discussion — PII scrubbing, prompt-injection interception, audit logging in front of MCP servers — is the same regardless of client and is covered in the [Claude Code MCP guide](../claude-code/mcp-servers.md#agent-governance-layer) and the [MCP servers guide](../mcp-servers/guide.md).

> Source: [Manage MCP servers](https://code.visualstudio.com/docs/agents/run/manage-mcp-servers), [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration).

---

## Related Guides

- [VS Code README](README.md) — the agentic surface overview and harnesses
- [Agent Mode](agent-mode.md) — how MCP tools surface in the agent loop; agent sandboxing
- [Customization](customization.md) — instructions, custom agents, skills, plugins
- [Best Practices](best-practices.md) — approvals and security posture
- [MCP Servers Guide](../mcp-servers/guide.md) — protocol-level deep dive
- [Claude Code MCP Servers](../claude-code/mcp-servers.md) — the `.mcp.json`/`mcpServers` counterpart and governance patterns
- [Copilot CLI Guide](../github-copilot/cli-guide.md) — shares `~/.copilot/mcp-config.json` with the Copilot harness

---

**Last Updated**: 2026-10-21
