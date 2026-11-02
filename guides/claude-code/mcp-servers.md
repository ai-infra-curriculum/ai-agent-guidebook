# MCP Servers in Claude Code

A deep dive on Model Context Protocol integration in Claude Code: configuration, the deferred-tool flow, permissioning, agent governance, and debugging.

Last verified: 2026-10 (against code.claude.com/docs/en/mcp, Claude Code v2.1.306).

---

## Table of Contents

- [Why MCP Matters](#why-mcp-matters)
- [Where Config Lives](#where-config-lives)
- [Config File Shape](#config-file-shape)
- [Adding and Removing Servers](#adding-and-removing-servers)
- [Transports: stdio, HTTP, SSE, WebSocket](#transports-stdio-http-sse-websocket)
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

Claude Code ships with a set of built-in tools (Read, Write, Edit, Bash, WebFetch, WebSearch, Agent, and more; see the [tools reference](https://code.claude.com/docs/en/tools-reference)). MCP — Model Context Protocol — is how you extend that surface without forking the binary.

An MCP server is a process or service that speaks JSON-RPC 2.0 over stdio, streamable HTTP, SSE, or WebSocket. It exposes a set of tools, resources, and prompts. Claude Code discovers those at connect time and surfaces them to the model alongside built-ins.

The practical impact:

- You can give the agent typed access to your database, Jira, Slack, Stripe, Notion, Linear, Figma, Canva, etc.
- You can wrap internal APIs without touching the CLI.
- You can layer governance (PII scrubbing, prompt-injection filtering, audit logging) between the model and downstream systems.

A modern Claude Code install often has 10-30 MCP servers wired in. Past that, the deferred-tool flow (described below) becomes essential for context economy.

---

## Where Config Lives

Three scopes you configure, plus servers that arrive from plugins, claude.ai connectors, and your organization. When the same server is defined in more than one place, Claude Code connects once using the highest-precedence definition (entries are not merged): an org's `managedMcpServers` first, then **local > project > user**, then plugin-provided servers, then claude.ai connectors. Scopes match duplicates by name; plugins and connectors match by endpoint.

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

Inside an interactive session, `/mcp` shows connection status, tool counts, and OAuth state, and lets you toggle a server off without deleting its config. If you're signed in with a claude.ai account, connectors you've enabled there can also appear in Claude Code.

---

## Config File Shape

Canonical structure (`.mcp.json` at the project root; the same shape is used inside `~/.claude.json`):

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_TOKEN}"
      }
    },
    "postgres-prod": {
      "type": "stdio",
      "command": "uvx",
      "args": ["postgres-mcp", "--access-mode=restricted"],
      "env": {
        "DATABASE_URI": "${PROD_READ_REPLICA_URL}"
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

(GitHub's official hosted server replaces the archived `@modelcontextprotocol/server-github` npm package; `postgres-mcp` is the community "Postgres MCP Pro" server, whose restricted mode limits it to read-only access. See the [MCP catalog](../mcp-servers/catalog.md) for current packages.)

Field reference:

| Field | Type | Purpose |
|-------|------|---------|
| `type` | `stdio` \| `http` \| `sse` \| `ws` | Wire protocol. Defaults to `stdio`. `streamable-http` is accepted as an alias for `http` in JSON config |
| `command` | string | Executable to launch (stdio transport) |
| `args` | string[] | Arguments to the command |
| `env` | object | Environment variables. `${VAR}` (and `${VAR:-default}`) expand from the shell env |
| `url` | string | Endpoint for `http`, `sse`, and `ws` transports |
| `headers` | object | HTTP headers (expansion supported) |
| `headersHelper` | string | Command that generates headers at connect time (for SSO, Kerberos, short-lived tokens) |
| `timeout` | number | Per-server tool execution timeout in ms (a hard wall-clock limit per call); overrides `MCP_TOOL_TIMEOUT` for that server |
| `alwaysLoad` | boolean | Keep this server's tools visible without a tool-search step |

Env expansion only reads the shell environment of the `claude` process. Hardcoded secrets are an anti-pattern — keep them in a secrets manager and export at session start.

---

## Adding and Removing Servers

### Interactive

```
/mcp
```

Shows connection status and tool counts per server, lets you complete OAuth flows, toggle servers on/off, and flags project-scoped servers awaiting approval. `/mcp reconnect <server>` (or `all`) retries failed servers.

### Command line

For stdio servers, `--` separates Claude's own flags from the command that runs the server:

```bash
# Add user-global (local git server from the MCP reference servers, via uvx)
claude mcp add --scope user git -- uvx mcp-server-git

# Add project-scoped (written to .mcp.json, shareable via version control)
claude mcp add --scope project --env DATABASE_URI=postgres://localhost/dev postgres-dev -- \
  uvx postgres-mcp --access-mode=restricted

# Add a remote HTTP server
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Add from raw JSON (also the only way to add a WebSocket server)
claude mcp add-json events-server '{"type":"http","url":"https://mcp.example.com/mcp"}'

# Authenticate an OAuth server from the shell (v2.1.186+)
claude mcp login notion
claude mcp logout notion

# Remove (also deletes stored OAuth tokens for a remote server)
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

## Transports: stdio, HTTP, SSE, WebSocket

### stdio (default)

The MCP server is a child process. Claude Code writes JSON-RPC requests to its stdin and reads responses from stdout. stderr is captured for logs.

```json
{
  "command": "uvx",
  "args": ["mcp-server-git", "--repository", "/path/to/repo"]
}
```

When a session ends, Claude Code stops its stdio servers.

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

### WebSocket

`"type": "ws"` holds a persistent bidirectional connection, suited to remote servers that push events unprompted. Configure it in JSON (`claude mcp add --transport` doesn't accept `ws`). Authentication is header-only (`headers` or `headersHelper`) — no OAuth.

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

- `default` (Manual) — prompt for every tool the agent has not already been approved for.
- `acceptEdits` — auto-approve file edits, prompt for everything else.
- `plan` — read and plan; edits wait for an approved plan.
- `auto` — a classifier reviews each call (the interactive default since v2.1.283). Organizations can mark specific connector tools `ask`, which prompts in every mode.
- `dontAsk` — deny anything not pre-approved; good for CI.
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
      "Bash(git *)",
      "Bash(npm test *)",
      "Read"
    ],
    "deny": [
      "mcp__postgres-prod__execute",
      "Bash(rm -rf *)",
      "Bash(curl *)"
    ]
  }
}
```

Tool names follow the pattern `mcp__<server-name>__<tool-name>`. Allow rules accept globs only after a literal `mcp__<server>__` prefix (the server segment can't be a glob), and since v2.1.299 an allow rule matches only the named server — so for server names containing `__`, use `mcp__<server>__*`. Bash patterns support wildcards (`Bash(git *)` allows any `git` subcommand).

### Allowlisting a whole server

Using just the server name (no tool suffix), or the `__*` wildcard, approves every tool that server exposes:

```json
{
  "permissions": {
    "allow": ["mcp__github", "mcp__linear__*"]
  }
}
```

Reserve whole-server allows for servers that are entirely read-only. Anything that mutates state belongs in the central allowlist as an explicit `mcp__<server>__<tool>` entry, where it is reviewable.

---

## Deferred Tools and ToolSearch

Without deferral, every connected MCP server's full tool schema lands in the model's context at session start. With dozens of servers and hundreds of tools, that can consume tens of thousands of tokens before you write a prompt.

MCP tool search solves this, and it is **enabled by default**. Only tool *names* and server instructions appear in initial context. Control it with the `ENABLE_TOOL_SEARCH` environment variable:

| Value | Behavior |
|-------|----------|
| unset or `true` (default) | MCP tools deferred and loaded on demand — including behind an `ANTHROPIC_BASE_URL` gateway since v2.1.304 (a gateway 400/422 triggers a retry without it) |
| `auto` | Threshold mode: tool search turns on once definitions reach 10% of the context window |
| `auto:N` | Same, with a custom threshold (e.g. `auto:5` for 5%) |
| `false` | All MCP tools loaded upfront, no deferral |

Tool search is unavailable on models older than Claude Opus 4 / Sonnet 4 / Haiku 4.5 (Opus/Sonnet/Haiku 4.5 on Google Cloud's Agent Platform), on Foundry deployments hosted on Azure, and when `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` is set; Claude Code loads tools upfront there regardless of the variable.

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
- You want a few servers always visible: set `"alwaysLoad": true` on those servers instead of turning tool search off globally.

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
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${GITHUB_TOKEN}" }
    }
  }
}
```

`${VAR}` and `${VAR:-default}` expand in `command`, `args`, `env`, `url`, and `headers`. An unset variable with no default still loads: `claude mcp list` warns about it and the literal `${VAR}` text is used. In a remote server's `url` and `headers`, Claude Code's own and cloud-provider credential variables (such as `ANTHROPIC_API_KEY`) deliberately expand to empty, so a project's `.mcp.json` can't exfiltrate them.

### OAuth flows

Remote HTTP/SSE servers that return `401`/`403` are flagged in `/mcp` for sign-in. Complete the browser flow from `/mcp`, or run `claude mcp login <server>` from your shell. **Claude Code stores the OAuth tokens** (securely, per server) and refreshes them automatically; on a rejected refresh token it shows a notice pointing at `/mcp` → **Re-authenticate**. `claude mcp remove` deletes the stored tokens.

`claude -p` and Agent SDK runs can't run an OAuth flow, so sign in from an interactive session first. If you configured an `Authorization` header yourself and the server rejects it, Claude Code reports a failed connection rather than falling back to OAuth.

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
- **Open-source proxies** — a growing number of community MCP gateway/proxy projects exist; most are early-stage, so evaluate maturity and maintenance before depending on one.
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

**`Method not found` errors.** The server speaks an old MCP version. Update it. (Since v2.1.299 Claude Code negotiates MCP protocol revision 2026-07-28 by default; `MCP_PROTOCOL_NEGOTIATION=legacy` opts out for servers that choke on it.)

**`Permission denied`** for an `mcp__server__tool` call despite being in `allow`. The tool name in the allowlist must match exactly (`mcp__<server>__<tool>`, where `<server>` is the name you configured). Check `/mcp` for canonical server names; copy-paste, don't retype.

**Server hangs on first call.** Usually upstream auth. Run the server manually with the same env:

```bash
DATABASE_URI=$DATABASE_URI uvx postgres-mcp --access-mode=restricted
# Then issue a manual tools/call via stdio with a small test payload
```

**Cold-start latency.** `npx`-based servers re-download the package on first run after a cache eviction. Use `uvx`, pre-install with `npm i -g`, or switch to a long-running HTTP server.

**`Connection refused`** on HTTP/SSE. Check the URL is reachable from the `claude` process (not just from your browser — corporate split DNS can lie). `curl -v <url>` from the same shell. Claude Code retries a failed first HTTP/SSE connection up to three times, and reconnects a remote server that drops mid-session up to five times with exponential backoff before marking it failed. Stdio servers are not reconnected automatically.

**Long-running call blocks the session.** It shouldn't anymore: main-conversation MCP calls still running after two minutes move to a background task (see `/tasks`). Tune with `CLAUDE_CODE_MCP_AUTO_BACKGROUND_MS`.

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
- Remember that `-p`, Agent SDK, and cloud sessions load a repo's project-scoped `.mcp.json` servers **without** the approval prompt interactive sessions show. Review `.mcp.json` before scripting Claude Code over an untrusted repo, or use `--strict-mcp-config`.
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
