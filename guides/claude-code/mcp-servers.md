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

Three scopes, evaluated in order. Later scopes override earlier ones for the same server name.

| Scope | Path | When to use |
|-------|------|-------------|
| User-global | `~/.claude/mcp.json` (or `~/.config/claude-code/mcp.json`) | Servers you want everywhere: GitHub, your password manager, your notes app |
| Project-local | `<repo>/.claude/mcp.json` | Servers specific to a codebase: that project's DB, its Docker daemon, project-scoped Jira |
| Session | passed via `--mcp-config <path>` | One-off experiments without polluting persistent config |

Inspect resolved config:

```bash
claude mcp list           # all configured servers
claude mcp list --json    # machine-readable
claude mcp status         # which are connected, which failed
```

Inside an interactive session, `/mcp` opens the same UI.

---

## Config File Shape

Canonical structure:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      },
      "disabled": false,
      "autoApprove": ["search_repositories", "get_file_contents"],
      "timeout": 30000
    },
    "postgres-prod": {
      "command": "uvx",
      "args": ["mcp-server-postgres", "--read-only"],
      "env": {
        "DATABASE_URL": "${PROD_READ_REPLICA_URL}"
      },
      "transport": "stdio"
    },
    "internal-tools": {
      "transport": "sse",
      "url": "https://mcp.corp.internal/sse",
      "headers": {
        "Authorization": "Bearer ${INTERNAL_MCP_TOKEN}"
      }
    },
    "kubernetes-staging": {
      "command": "kubectl-mcp",
      "args": ["--context", "staging"],
      "disabled": true
    }
  }
}
```

Field reference:

| Field | Type | Purpose |
|-------|------|---------|
| `command` | string | Executable to launch (stdio transport) |
| `args` | string[] | Arguments to the command |
| `env` | object | Environment variables. `${VAR}` interpolates from shell env |
| `transport` | `stdio` \| `sse` \| `http` | Wire protocol. Defaults to `stdio` |
| `url` | string | Endpoint for `sse` and `http` transports |
| `headers` | object | HTTP headers (interpolation supported) |
| `disabled` | bool | Skip during startup. Useful for parked servers |
| `autoApprove` | string[] | Tool names that bypass the permission prompt |
| `timeout` | number | Per-tool-call timeout in ms. Default 30000 |
| `cwd` | string | Working directory for stdio commands |

Env interpolation only reads the shell environment of the `claude` process. Hardcoded secrets are an anti-pattern — keep them in a secrets manager and export at session start.

---

## Adding and Removing Servers

### Interactive

```
/mcp
```

The TUI lets you add, edit, disable, restart, and inspect servers. Changes write back to the appropriate config file based on the scope you choose.

### Command line

```bash
# Add user-global
claude mcp add github \
  --command npx \
  --args "-y,@modelcontextprotocol/server-github" \
  --env "GITHUB_TOKEN=\${GITHUB_TOKEN}"

# Add project-local
claude mcp add --scope project postgres-dev \
  --command "uvx" \
  --args "mcp-server-postgres" \
  --env "DATABASE_URL=postgres://localhost/dev"

# Remove
claude mcp remove github

# Toggle
claude mcp disable github
claude mcp enable github

# Restart a single server
claude mcp restart github
```

### Direct edit

Most operators end up editing the JSON file directly once they have more than a few servers. Use a `jq` sanity check before saving:

```bash
jq empty ~/.claude/mcp.json && echo "valid"
```

If invalid JSON ships, Claude Code refuses to start. Keep a backup.

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

### SSE (server-sent events)

The server is a long-lived HTTP service that streams responses.

```json
{
  "transport": "sse",
  "url": "https://mcp.corp.internal/sse",
  "headers": { "Authorization": "Bearer ${TOKEN}" }
}
```

Pros: shared infrastructure, central auth, observable, easy version pinning.
Cons: requires hosting; network failures more common than process crashes.

### HTTP (request/response)

Plain HTTP for servers that do not stream:

```json
{
  "transport": "http",
  "url": "https://mcp.example.com/rpc"
}
```

For new internal servers, default to SSE. stdio is best for personal tools and prototypes. HTTP is mostly used for legacy or stateless integrations.

---

## Tool Allowlists and Denylists

Once an MCP server is connected, every tool it exposes is callable. Two layers control what actually runs.

### Permission mode

Set globally in `settings.json`:

```json
{
  "permissionMode": "ask"
}
```

- `ask` — prompt for every tool the agent has not already been approved for this session.
- `accept-edits` — auto-approve file edits, prompt for everything else.
- `plan` — refuse all writes; useful for read-only exploration.
- `bypass-permissions` — auto-approve everything. Reserve for sandboxed CI containers.

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

### Per-server `autoApprove`

Per-server `autoApprove` is a convenience that adds entries to the allowlist without listing them in the central permissions config:

```json
{
  "mcpServers": {
    "github": {
      "autoApprove": ["search_repositories", "list_issues"]
    }
  }
}
```

Use `autoApprove` for safe read-only operations. Anything that mutates state belongs in the central allowlist where it is reviewable.

---

## Deferred Tools and ToolSearch

By default, every connected MCP server's full tool schema lands in the model's context at session start. With 30+ servers and 500+ tools, this can consume 40-80k tokens before you write a prompt.

Deferred-tool mode solves this. Enable it:

```json
{
  "mcp": {
    "deferredTools": true
  }
}
```

With deferred tools on, only tool *names* appear in initial context. The full JSON Schema for parameters is fetched on demand by the `ToolSearch` tool:

```
ToolSearch(query="select:mcp__github__create_pull_request,mcp__github__list_branches")
```

Or by keyword search:

```
ToolSearch(query="postgres query", max_results=5)
```

The matched tool definitions are injected as if they had been there all along, and the model can call them on the next turn.

**When to enable deferred tools:**

- You have more than 15 MCP servers, or
- Initial context usage exceeds 30k tokens before the first user prompt, or
- You run long sessions where context economy matters.

**When to leave it off:**

- You have fewer than 10 small servers.
- You routinely invoke a wide variety of tools per turn (the round-trip cost dominates).

Plugin-namespaced tools (`plugin:serena:find_symbol`) participate in the same deferred flow. ToolSearch returns plugin-qualified names.

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
      "transport": "sse",
      "url": "https://policy.corp.internal/sse",
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
claude mcp status
```

```
github            connected (12 tools)
postgres-prod     connected (3 tools)
internal-tools    failed: ECONNREFUSED
kubernetes-stag   disabled
```

### Inspect server logs

stdio servers' stderr is captured to:

```
~/.claude/logs/mcp/<server-name>.log
```

Tail in another terminal during a session:

```bash
tail -f ~/.claude/logs/mcp/github.log
```

### Verbose protocol logging

Set the env var before launching:

```bash
MCP_DEBUG=1 claude
```

This dumps every JSON-RPC frame to `~/.claude/logs/mcp/protocol.log`. Heavy, but invaluable when a server appears connected but never returns results.

### Common failure modes

**Server starts, no tools listed.** The server's `tools/list` response is empty. Either the server is misconfigured (missing env var) or it expects post-connection registration. Check the server's own README.

**`Method not found` errors.** The server speaks an old MCP version. Update it, or pin Claude Code to a compatible release.

**`Permission denied`** for an `mcp__server__tool` call despite being in `allow`. The tool name in the allowlist must match exactly. Run `claude mcp list --json` to get the canonical names; copy-paste, don't retype.

**Server hangs on first call.** Usually upstream auth. Run the server manually with the same env:

```bash
GITHUB_TOKEN=$GITHUB_TOKEN npx -y @modelcontextprotocol/server-github
# Then issue a manual tools/call via stdio with a small test payload
```

**Cold-start latency.** `npx`-based servers re-download the package on first run after a cache eviction. Use `uvx`, pre-install with `npm i -g`, or switch to a long-running SSE server.

**`Connection refused`** on SSE/HTTP. Check the URL is reachable from the `claude` process (not just from your browser — corporate split DNS can lie). `curl -v <url>` from the same shell.

---

## Performance Tuning

- **Enable deferred tools** above ~15 servers.
- **Disable servers you don't actively use** in a given session. `claude mcp disable <name>`. They consume context, startup time, and a process slot.
- **Prefer SSE/HTTP for shared servers** to avoid per-session cold starts.
- **Cap timeouts** for flaky external APIs so the agent doesn't sit on a stalled call.
- **Watch the `/cost` output** — high MCP tool counts inflate every prompt's input tokens.

---

## Security Hardening

- Treat MCP servers as part of your attack surface. A compromised server can read and exfiltrate every prompt and tool result the model sees.
- Pin server versions. `npx -y @scope/server@1.2.3` rather than `@latest`.
- Run servers with the least privileges they need. The Postgres MCP can use a read-only replica; the Kubernetes MCP can use a namespaced service account.
- Audit `autoApprove` lists. Auto-approving a tool that can call arbitrary URLs (most "fetch" tools) is equivalent to auto-approving Bash with network access.
- Log every tool call in production agent fleets. A governance MCP layer (above) or a Stop hook (see [hooks.md](hooks.md)) can do this.
- Rotate credentials on a schedule. The hash-chained audit trail from a governance layer is what tells you what was accessed during a window of compromise.

---

## Related

- [Catalog of MCP Servers](../mcp-servers/catalog.md) — full inventory.
- [Agents guide](agents.md) — how sub-agents inherit and constrain MCP access.
- [Hooks guide](hooks.md) — adding PreToolUse hooks as a lighter-weight governance layer.
- [Troubleshooting](troubleshooting.md) — MCP-specific failure recipes.
