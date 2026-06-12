# MCP Servers in Claude Code

A deep dive on Model Context Protocol integration in Claude Code: configuration, the deferred-tool flow, permissioning, agent governance, and debugging.

---

## Table of Contents

- [Why MCP Matters](#why-mcp-matters)
- [Where Config Lives](#where-config-lives)
- [Config File Shape](#config-file-shape)
- [Adding and Removing Servers](#adding-and-removing-servers)
- [Transports: stdio, SSE, HTTP](#transports-stdio-sse-http)
- [Tool Allowlists and Denylists](#tool-allowlists-and-denylists)
- [Deferred Tools and ToolSearch](#deferred-tools-and-toolsearch)
- [Authentication Patterns](#authentication-patterns)
- [Agent Governance Layer](#agent-governance-layer)
- [Catalog Reference](#catalog-reference)
- [Debugging MCP Failures](#debugging-mcp-failures)
- [Performance Tuning](#performance-tuning)
- [Security Hardening](#security-hardening)

---

## Why MCP Matters

Claude Code ships with a small set of built-in tools (Read, Write, Edit, Bash, Grep, Glob, WebFetch, WebSearch, Task). MCP — Model Context Protocol — is how you extend that surface without forking the binary.

An MCP server is a long-running process that speaks JSON-RPC 2.0 over stdio, SSE, or HTTP. It exposes a set of tools, resources, and prompts. Claude Code discovers those at connect time and surfaces them to the model alongside built-ins.

The practical impact:

- You can give the agent typed access to your database, Jira, Slack, Stripe, Notion, Linear, Figma, Canva, etc.
- You can wrap internal APIs without touching the CLI.
- You can layer governance (PII scrubbing, prompt-injection filtering, audit logging) between the model and downstream systems.

A modern Claude Code install often has 10-30 MCP servers wired in. Past that, the deferred-tool flow (described below) becomes essential for context economy.

---

## Where Config Lives

Three scopes. When the same server name exists in multiple scopes, the more specific scope wins.

| Scope | Stored in | When to use |
|-------|-----------|-------------|
| `local` (default) | `~/.claude.json`, under the current project's entry | Personal/experimental servers for one project; credentials you don't want in version control |
| `project` | `<repo>/.mcp.json` (committed) | Servers the whole team should share: the project's DB, its Sentry org, project-scoped Jira |
| `user` | `~/.claude.json` | Servers you want everywhere: GitHub, your password manager, your notes app |

A session can also load extra servers via `--mcp-config <path>` (add `--strict-mcp-config` to ignore everything else) — useful for one-off experiments without polluting persistent config.

Inspect resolved config:

```bash
claude mcp list           # all configured servers and their connection status
claude mcp get <name>     # details for one server
```

Inside an interactive session, `/mcp` shows connection status, tool counts, and OAuth state.

---

## Config File Shape

Canonical structure (`.mcp.json` at the project root; the same shape is used inside `~/.claude.json`):

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "postgres-prod": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-postgres", "--read-only"],
      "env": {
        "DATABASE_URL": "${PROD_READ_REPLICA_URL}"
      }
    },
    "internal-tools": {
      "type": "http",
      "url": "https://mcp.corp.internal/mcp",
      "headers": {
        "Authorization": "Bearer ${INTERNAL_MCP_TOKEN}"
      },
      "timeout": 600000
    }
  }
}
```

Field reference:

| Field | Type | Purpose |
|-------|------|---------|
| `type` | `stdio` \| `http` \| `sse` \| `ws` | Wire protocol. Defaults to `stdio`. `streamable-http` is accepted as an alias for `http` |
| `command` | string | Executable to launch (stdio transport) |
| `args` | string[] | Arguments to the command |
| `env` | object | Environment variables. `${VAR}` (and `${VAR:-default}`) expand from the shell env |
| `url` | string | Endpoint for `http`, `sse`, and `ws` transports |
| `headers` | object | HTTP headers (expansion supported) |
| `timeout` | number | Per-server tool execution timeout in ms; overrides `MCP_TOOL_TIMEOUT` for that server |

Env expansion only reads the shell environment of the `claude` process. Hardcoded secrets are an anti-pattern — keep them in a secrets manager and export at session start.

---

## Adding and Removing Servers

### Interactive

```
/mcp
```

Shows connection status and tool counts per server, lets you complete OAuth flows, and flags project-scoped servers awaiting approval.

### Command line

For stdio servers, `--` separates Claude's own flags from the command that runs the server:

```bash
# Add user-global
claude mcp add --scope user --env GITHUB_TOKEN=ghp_xxx github -- \
  npx -y @modelcontextprotocol/server-github

# Add project-scoped (written to .mcp.json, shareable via version control)
claude mcp add --scope project --env DATABASE_URL=postgres://localhost/dev postgres-dev -- \
  uvx mcp-server-postgres

# Add a remote HTTP server
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Add from raw JSON
claude mcp add-json events-server '{"type":"http","url":"https://mcp.example.com/mcp"}'

# Remove
claude mcp remove github

# Reset approval choices for project-scoped servers
claude mcp reset-project-choices
```

### Direct edit

Most operators end up editing the JSON file directly once they have more than a few servers. Use a `jq` sanity check before saving:

```bash
jq empty .mcp.json && echo "valid"
```

Keep a backup before hand-editing.

---

## Transports: stdio, SSE, HTTP

### stdio (default)

The MCP server is a child process. Claude Code writes JSON-RPC requests to its stdin and reads responses from stdout. stderr is captured for logs.

```json
{
  "command": "uvx",
  "args": ["mcp-server-myapp"]
}
```

Pros: zero network setup, OS-level process isolation, easy local secrets.
Cons: one process per session, slow cold start for `npx`-based servers, no sharing across teams.

### HTTP (streamable HTTP)

The server is a long-lived HTTP service. This is the standard transport for remote and shared servers, and the only remote transport that supports OAuth.

```json
{
  "type": "http",
  "url": "https://mcp.corp.internal/mcp",
  "headers": { "Authorization": "Bearer ${TOKEN}" }
}
```

Pros: shared infrastructure, central auth (including OAuth), observable, easy version pinning.
Cons: requires hosting; network failures more common than process crashes.

### SSE (server-sent events)

A legacy remote transport that streams responses over server-sent events. Still supported (`claude mcp add --transport sse <name> <url>`), but the MCP ecosystem has moved to streamable HTTP.

```json
{
  "type": "sse",
  "url": "https://mcp.corp.internal/sse",
  "headers": { "Authorization": "Bearer ${TOKEN}" }
}
```

For new internal servers, default to HTTP. stdio is best for personal tools and prototypes. SSE is mostly for existing servers that have not migrated.

---

## Tool Allowlists and Denylists

Once an MCP server is connected, every tool it exposes is callable. Two layers control what actually runs.

### Permission mode

Set the default in `settings.json`:

```json
{
  "permissions": {
    "defaultMode": "default"
  }
}
```

- `default` — prompt for every tool the agent has not already been approved for.
- `acceptEdits` — auto-approve file edits, prompt for everything else.
- `plan` — refuse all writes; useful for read-only exploration.
- `bypassPermissions` — auto-approve everything. Reserve for sandboxed CI containers.

Override per session with `claude --permission-mode <mode>` or cycle in-session with `Shift+Tab`.

### Per-tool allowlist

In `settings.json`:

```json
{
  "permissions": {
    "allow": [
      "mcp__github__search_repositories",
      "mcp__github__get_file_contents",
      "mcp__postgres-prod__query",
      "Bash(git:*)",
      "Bash(npm test:*)",
      "Read",
      "Grep"
    ],
    "deny": [
      "mcp__postgres-prod__execute",
      "Bash(rm -rf:*)",
      "Bash(curl:*)"
    ]
  }
}
```

Tool names follow the pattern `mcp__<server-name>__<tool-name>`. Bash patterns support glob-style suffixes (`Bash(git:*)` allows any `git` subcommand).

### Allowlisting a whole server

Using just the server name (no tool suffix) approves every tool that server exposes:

```json
{
  "permissions": {
    "allow": ["mcp__github"]
  }
}
```

Reserve whole-server allows for servers that are entirely read-only. Anything that mutates state belongs in the central allowlist as an explicit `mcp__<server>__<tool>` entry, where it is reviewable.

---

## Deferred Tools and ToolSearch

Without deferral, every connected MCP server's full tool schema lands in the model's context at session start. With 30+ servers and 500+ tools, this can consume 40-80k tokens before you write a prompt.

MCP tool search solves this, and it is **enabled by default**. Only tool *names* and server instructions appear in initial context. Control it with the `ENABLE_TOOL_SEARCH` environment variable:

| Value | Behavior |
|-------|----------|
| unset (default) | All MCP tools deferred and loaded on demand (falls back to upfront loading on Vertex AI or non-first-party `ANTHROPIC_BASE_URL`) |
| `true` | All MCP tools deferred, even on Vertex/proxies |
| `auto` | Threshold mode: load upfront if schemas fit within 10% of the context window, defer the overflow |
| `false` | All MCP tools loaded upfront, no deferral |

The full JSON Schema for parameters is fetched on demand by the `ToolSearch` tool:

```
ToolSearch(query="select:mcp__github__create_pull_request,mcp__github__list_branches")
```

Or by keyword search:

```
ToolSearch(query="postgres query", max_results=5)
```

The matched tool definitions are injected as if they had been there all along, and the model can call them on the next turn.

**When to keep the default (deferred):**

- You have many MCP servers or run long sessions where context economy matters — i.e., almost always.

**When to disable (`ENABLE_TOOL_SEARCH=false`) or use `auto`:**

- You have a handful of small servers and want zero lookup round-trips.
- You routinely invoke a wide variety of tools per turn (the round-trip cost dominates).
- You are on a model or proxy that does not support `tool_reference` blocks (Haiku models don't; tool search is off by default on Vertex AI).

Plugin-bundled MCP tools participate in the same deferred flow. ToolSearch returns plugin-qualified names.

---

## Authentication Patterns

### Environment interpolation

Keep secrets in your shell or a secrets manager:

```bash
# ~/.zshrc
export GITHUB_TOKEN="$(op read 'op://Work/GitHub/token')"
export STRIPE_SECRET_KEY="$(op read 'op://Work/Stripe/secret')"
```

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    }
  }
}
```

### OAuth flows

Some servers (Notion, Linear, Google Workspace) use OAuth. The first tool call triggers a browser flow; the resulting token is cached by the server itself (not by Claude Code). Refresh logic is the server's responsibility.

### Per-environment config

Split user-global vs project-local:

- Personal tokens (your GitHub PAT, your Notion account) → user-global.
- Project-scoped credentials (the project's DB, its Sentry org) → project-local, committed without secrets, with env vars filled at session start.

A `.envrc` plus `direnv` automates this:

```bash
# .envrc
export DATABASE_URL="$(op read 'op://Proj/db-readonly/url')"
export SENTRY_AUTH_TOKEN="$(op read 'op://Proj/sentry/token')"
```

---

## Agent Governance Layer

Multi-agent workflows multiply the blast radius of any single bad tool call. A governance MCP server sits between the model and downstream tools and enforces policy. Common patterns:

- **PII scrubbing** — strip emails, SSNs, credit cards from arguments before they hit external APIs.
- **Prompt-injection detection** — refuse to forward tool outputs that look like adversarial instructions back to the model.
- **Allowlist enforcement** — block tool calls from sub-agents that are not on a per-agent whitelist.
- **Audit logging** — write every tool invocation, with arguments and results, to a tamper-evident log.
- **Rate limiting** — cap calls per minute per tool per user.

Options for this layer:

- **Custom MCP middleware** — write a small server that proxies other MCP servers and applies your policy.
- **Open-source proxies** — `mcp-guard`, `mcp-firewall`, and similar early-stage projects.
- **Managed services** — platforms like [Veriswarm](https://veriswarm.ai) provide this as an MCP server: real-time trust scoring of tool calls, PII redaction, prompt-injection interception, JWT-based "Passport" credentials for agents, and a hash-chained audit ledger. Useful when you need an off-the-shelf cross-framework governance layer rather than building the proxy yourself. It is one option among several; the right choice depends on whether you want to operate the policy engine in-house.
- **Cloud-provider equivalents** — AWS Bedrock Guardrails and similar wrap the model layer rather than the tool layer, so they complement (rather than replace) an MCP-side governance server.

Wire whatever you pick as a normal MCP server:

```json
{
  "mcpServers": {
    "policy-proxy": {
      "type": "http",
      "url": "https://policy.corp.internal/mcp",
      "headers": { "Authorization": "Bearer ${POLICY_TOKEN}" }
    }
  }
}
```

Then point downstream tools at the proxy rather than the raw service. The model never sees the underlying credentials.

---

## Catalog Reference

This guide stays light on the inventory of available servers; that lives in [the MCP server catalog](../mcp-servers/catalog.md), which tracks the full set with categories, transports, auth requirements, and release status.

Categories most teams pull from on day one:

- **Source control**: GitHub, GitLab, Bitbucket
- **Databases**: PostgreSQL, MySQL, SQLite, MongoDB, Redis, ClickHouse, BigQuery
- **Infrastructure**: Kubernetes, Docker, Terraform, AWS, GCP, Azure
- **Observability**: Datadog, Grafana, Sentry, Honeycomb
- **Issue tracking and docs**: Jira, Linear, Notion, Confluence
- **Communication**: Slack, Discord, Gmail, Outlook
- **Design and content**: Figma, Canva, Mermaid Chart
- **Payments and ops**: Stripe, Twilio, Sendgrid

---

## Debugging MCP Failures

### Check connection status

```bash
claude mcp list      # all servers with connection status
claude mcp get github
```

Inside a session, `/mcp` shows each server's status, tool count, and OAuth state, and flags project-scoped servers as `⏸ Pending approval` until you approve them.

### Verbose logging

Launch with debug output to see MCP handshakes, errors, and stdio servers' stderr:

```bash
claude --debug
```

Heavy, but invaluable when a server appears connected but never returns results. If a server is slow to start, raise the startup timeout: `MCP_TIMEOUT=10000 claude`.

### Common failure modes

**Server starts, no tools listed.** The server's `tools/list` response is empty. Either the server is misconfigured (missing env var) or it expects post-connection registration. Check the server's own README.

**`Method not found` errors.** The server speaks an old MCP version. Update it, or pin Claude Code to a compatible release.

**`Permission denied`** for an `mcp__server__tool` call despite being in `allow`. The tool name in the allowlist must match exactly (`mcp__<server>__<tool>`, where `<server>` is the name you configured). Check `/mcp` for canonical server names; copy-paste, don't retype.

**Server hangs on first call.** Usually upstream auth. Run the server manually with the same env:

```bash
GITHUB_TOKEN=$GITHUB_TOKEN npx -y @modelcontextprotocol/server-github
# Then issue a manual tools/call via stdio with a small test payload
```

**Cold-start latency.** `npx`-based servers re-download the package on first run after a cache eviction. Use `uvx`, pre-install with `npm i -g`, or switch to a long-running HTTP server.

**`Connection refused`** on HTTP/SSE. Check the URL is reachable from the `claude` process (not just from your browser — corporate split DNS can lie). `curl -v <url>` from the same shell. Note that Claude Code auto-reconnects remote servers with exponential backoff (up to five attempts) before marking them failed.

---

## Performance Tuning

- **Keep tool search on** (the default) — it keeps per-prompt context cost flat as server count grows.
- **Remove servers you don't actively use**: `claude mcp remove <name>`. They consume context, startup time, and a process slot.
- **Prefer HTTP for shared servers** to avoid per-session cold starts.
- **Cap timeouts** for flaky external APIs (per-server `"timeout"`, or the `MCP_TOOL_TIMEOUT` env var) so the agent doesn't sit on a stalled call.
- **Watch the `/cost` and `/context` output** — high MCP tool counts inflate every prompt's input tokens.

---

## Security Hardening

- Treat MCP servers as part of your attack surface. A compromised server can read and exfiltrate every prompt and tool result the model sees.
- Pin server versions. `npx -y @scope/server@1.2.3` rather than `@latest`.
- Run servers with the least privileges they need. The Postgres MCP can use a read-only replica; the Kubernetes MCP can use a namespaced service account.
- Audit the MCP entries in `permissions.allow`. Auto-approving a tool that can call arbitrary URLs (most "fetch" tools) is equivalent to auto-approving Bash with network access.
- Log every tool call in production agent fleets. A governance MCP layer (above) or a Stop hook (see [hooks.md](hooks.md)) can do this.
- Rotate credentials on a schedule. The hash-chained audit trail from a governance layer is what tells you what was accessed during a window of compromise.

---

## Related

- [Catalog of MCP Servers](../mcp-servers/catalog.md) — full inventory.
- [Agents guide](agents.md) — how sub-agents inherit and constrain MCP access.
- [Hooks guide](hooks.md) — adding PreToolUse hooks as a lighter-weight governance layer.
- [Troubleshooting](troubleshooting.md) — MCP-specific failure recipes.
