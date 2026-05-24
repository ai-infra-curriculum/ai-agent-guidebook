# MCP Configuration Reference

The full shape of an MCP config file, how scoping works, how to allow/deny individual tools, how to run multiple instances of the same server safely, and the configuration pitfalls that bite people in production.

> **Last updated**: 2026-05-24 · Tracks MCP spec **2025-06-18**.

---

## Table of Contents

- [Anatomy of an MCP config entry](#anatomy-of-an-mcp-config-entry)
- [Field reference](#field-reference)
- [Scoping: project vs. user vs. system](#scoping-project-vs-user-vs-system)
- [Tool allow / deny lists](#tool-allow--deny-lists)
- [Multiple instances of the same server](#multiple-instances-of-the-same-server)
- [Conditional / environment-driven config](#conditional--environment-driven-config)
- [Concurrency and parallel tool calls](#concurrency-and-parallel-tool-calls)
- [Timeouts and lifecycle tuning](#timeouts-and-lifecycle-tuning)
- [Common pitfalls](#common-pitfalls)
- [Reference: full annotated config](#reference-full-annotated-config)

---

## Anatomy of an MCP config entry

Every host's config converges on the same shape under different keys. Conceptually each server entry has:

```
mcpServers.<name>:
  ├── transport: stdio | http             (defaults to stdio)
  ├── command + args + env                (stdio)
  ├── url + headers                       (http)
  ├── disabled                            (boolean, default false)
  ├── autoApprove / permissions           (allowlists / denylists)
  ├── timeout / startupTimeout            (ms)
  └── cwd                                 (working directory for stdio)
```

A minimal stdio entry:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/code"]
    }
  }
}
```

A minimal HTTP entry:

```json
{
  "mcpServers": {
    "context7": {
      "transport": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": { "Authorization": "Bearer ${CONTEXT7_API_KEY}" }
    }
  }
}
```

---

## Field reference

### `transport`

`"stdio"` (default) or `"http"`. Some hosts also accept `"sse"` for the legacy split SSE transport — prefer `"http"` (Streamable HTTP, introduced in spec revision 2025-03-26) when the server supports it.

### `command` + `args` (stdio only)

The executable and its arguments. `command` should be an absolute path or an executable on the host's `PATH`. GUI-launched hosts on macOS often don't inherit your shell PATH; prefer absolute paths (`/opt/homebrew/bin/npx`) or set `PATH` in `env`.

`args` is a list of strings. Arguments are passed verbatim — no shell interpolation is applied to elements beyond the host's `${VAR}` expansion.

### `env` (stdio only)

Object of environment variables passed to the child process. Values support `${VAR}` substitution from the host's environment. Hosts typically *replace* rather than *extend* the child's environment; if your server needs `PATH`, `HOME`, or `LANG`, pass them explicitly.

```json
{
  "env": {
    "PATH": "${PATH}",
    "HOME": "${HOME}",
    "POSTGRES_CONNECTION_STRING": "${POSTGRES_CONNECTION_STRING}"
  }
}
```

### `cwd` (stdio only)

Working directory for the child process. Defaults to the host's working directory (usually `$HOME` for GUI launches). Set this if the server reads relative paths.

### `url` + `headers` (HTTP only)

Endpoint for Streamable HTTP servers. `headers` is the most common place to attach a bearer token, an API key, or a tenant identifier.

```json
{
  "transport": "http",
  "url": "https://mcp.internal.example.com/mcp",
  "headers": {
    "Authorization": "Bearer ${INTERNAL_MCP_TOKEN}",
    "X-Tenant-Id": "${TENANT_ID}"
  }
}
```

### `disabled`

Boolean. Set `true` to keep the entry in the file but stop the host from launching it. Useful for staging changes or temporarily silencing a noisy server.

### `autoApprove` (Cline, Cursor, Windsurf) / `permissions` (Claude Code)

Lists of tool names that the host will run without prompting. The exact shape varies by host (see [Tool allow / deny lists](#tool-allow--deny-lists)).

### `timeout` / `startupTimeout`

Milliseconds. Some hosts let you tune the per-call timeout and the initialization timeout independently. Default startup is typically 30–60s; per-call timeouts default to 60–120s.

### Host-specific keys

A few hosts add fields:

- Claude Code: `permissions.allow`, `permissions.deny` (uses pattern matching against `mcp__<server>__<tool>`), `enableAllProjectMcpServers` (boolean).
- Cline: `autoApprove` (array of tool names), `disabled` (boolean).
- Continue: nested under `mcpServers:` in YAML; supports `${{ secrets.NAME }}` interpolation from the hub.

Stick to the universal fields when you can — anything host-specific won't port if you change hosts.

---

## Scoping: project vs. user vs. system

Most hosts support at least two scopes. The conventions:

| Scope | Lives at | Travels with | Use for |
|---|---|---|---|
| **Project** | `<repo>/.mcp.json`, `<repo>/.cursor/mcp.json`, etc. | The repo | Servers specific to this codebase (project DB, project filesystem path, project-specific internal MCP) |
| **User** | `~/.claude/settings.json`, `~/.cursor/mcp.json`, etc. | The developer's machine | Personal preferences (your GitHub account, your Linear workspace, your Notion) |
| **System** / **Enterprise** | `/etc/claude/managed.json` (Claude Code), MDM-deployed JSON (Cursor enterprise) | The fleet | Org-mandated servers and policies, deny-by-default lists |

Precedence (highest → lowest) on most hosts:

```
System / enterprise   →   Project   →   User
```

So an enterprise denylist wins over a project allow, and a project entry overrides a user entry with the same name. **Caveat**: precedence semantics vary across hosts and across versions; always test by looking at the resolved server list in the host UI rather than reasoning about layering on paper.

### Commit-safe project config

A `.mcp.json` is safe to commit if and only if:

1. It contains no literal secrets — only `${VAR}` placeholders.
2. The servers it references are ones every developer on the team should run, not ones that depend on a developer-specific path.

For project-specific filesystem mounts, prefer a template:

```json
// .mcp.json.example  (committed)
{
  "mcpServers": {
    "project-fs": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${PROJECT_ROOT}"]
    }
  }
}
```

Document `cp .mcp.json.example .mcp.json && export PROJECT_ROOT=$(pwd)` in the onboarding README.

---

## Tool allow / deny lists

Every MCP server exposes a set of tools. Some are read-only and cheap (`get_file`, `list_issues`); others are destructive (`delete_repo`, `execute_sql`, `send_email`). You almost always want to allow some and gate others behind explicit user confirmation.

### Claude Code

Claude Code's permission system uses pattern strings of the form `mcp__<server>__<tool>`:

```json
{
  "permissions": {
    "allow": [
      "mcp__filesystem__read_file",
      "mcp__filesystem__list_directory",
      "mcp__github__list_issues",
      "mcp__github__get_pull_request",
      "mcp__postgres__query"
    ],
    "deny": [
      "mcp__postgres__execute",
      "mcp__github__delete_repository"
    ],
    "ask": [
      "mcp__filesystem__write_file",
      "mcp__github__create_issue"
    ]
  }
}
```

- `allow` — invoked without prompting.
- `deny` — refused outright; tool isn't even surfaced.
- `ask` — surfaced, but each invocation requires user approval.

Wildcards work: `mcp__filesystem__*` allows the whole server's tool surface. Use sparingly — that's the same shape as "I trust this server completely," which is rarely what you mean.

### Cline / Windsurf

`autoApprove` per server:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "...",
      "args": [...],
      "autoApprove": ["read_file", "list_directory"]
    }
  }
}
```

Anything not in `autoApprove` prompts every invocation. Empty `autoApprove` (the default) means everything prompts.

### Cursor

Cursor surfaces a per-tool toggle in Settings → MCP. There's no first-class config-file allowlist as of late 2026; the UI is the source of truth. Enterprise plans add a centrally managed policy.

### Recommended default posture

A conservative starting point that works across hosts:

1. **Allow** all read-only tools by name.
2. **Ask** for all create / update tools.
3. **Deny** all destructive (delete / drop / force-push / overwrite) tools, then re-enable individual ones explicitly only when a workflow needs them.

Audit logs eat the rest of the risk — see [`advanced.md`](./advanced.md) for telemetry patterns.

---

## Multiple instances of the same server

Common when one server can front multiple targets — filesystem (different roots), Postgres (different databases), GitHub (different accounts). Each instance gets a unique entry name; the underlying package is the same.

```json
{
  "mcpServers": {
    "fs-work": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/work"]
    },
    "fs-personal": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/personal"]
    },
    "pg-staging": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": { "POSTGRES_CONNECTION_STRING": "${PG_STAGING_URL}" }
    },
    "pg-prod-readonly": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": { "POSTGRES_CONNECTION_STRING": "${PG_PROD_READONLY_URL}" }
    }
  }
}
```

Tool names will be `mcp__fs-work__read_file`, `mcp__fs-personal__read_file`, etc. Allow/deny lists scope cleanly:

```json
{
  "permissions": {
    "allow": ["mcp__pg-staging__*"],
    "ask":   ["mcp__pg-prod-readonly__query"],
    "deny":  ["mcp__pg-prod-readonly__execute"]
  }
}
```

Naming convention: include the *environment* in the server name (`pg-prod`, `pg-staging`, `gh-org-acme`, `gh-personal`) so the model sees the right hint in every tool description.

---

## Conditional / environment-driven config

Most hosts don't evaluate logic in the config file, but you can fake it with:

### 1. Env-var gated entries via wrapper script

```bash
#!/usr/bin/env bash
# scripts/mcp-pg-prod.sh
if [[ "$ENABLE_PROD_MCP" != "1" ]]; then
  echo "prod MCP disabled" >&2
  exit 1
fi
exec npx -y @modelcontextprotocol/server-postgres "$@"
```

```json
{
  "pg-prod": {
    "command": "/Users/me/scripts/mcp-pg-prod.sh",
    "env": { "POSTGRES_CONNECTION_STRING": "${PG_PROD_URL}" }
  }
}
```

### 2. Per-profile config files

Keep `~/.claude/settings.work.json` and `~/.claude/settings.personal.json` and symlink the active one:

```bash
ln -sf settings.work.json ~/.claude/settings.json
```

A `claude-profile work` shell alias makes this ergonomic.

### 3. Direnv-managed `.envrc`

For project-scoped servers, drive env vars from `.envrc`:

```bash
# .envrc
export PROJECT_ROOT="$PWD"
export POSTGRES_CONNECTION_STRING="$(op read 'op://Work/$(basename $PWD)/db_url')"
```

`.mcp.json` references `${PROJECT_ROOT}` and `${POSTGRES_CONNECTION_STRING}`. Direnv loads them when you `cd` in; the host inherits them at launch.

### 4. Enterprise config templating

For org-wide deployments, render the final JSON from a template at provision time (Ansible, Chef, MDM payload). The host always sees a static file; the templating happens upstream where you have access to a real secrets manager.

---

## Concurrency and parallel tool calls

Most hosts now issue tool calls **in parallel** by default when the model emits multiple independent calls in one turn. This is a 2–5× latency win on multi-tool tasks but it stresses MCP servers in three ways:

1. **Request concurrency**: a server must handle interleaved `tools/call` requests on the same session. The reference SDKs do this correctly; check third-party servers' READMEs.
2. **Resource contention**: a Postgres server hit with 8 parallel queries may exhaust the underlying pool. Configure the pool with at least as many connections as the host's max parallel calls.
3. **Rate limits**: 8 parallel GitHub API calls trip the secondary rate limit much faster than 8 sequential calls. Hosted MCPs usually back off correctly; self-hosted ones often don't.

Hosts expose knobs:

- **Claude Code**: `--max-parallel-tool-calls N` (CLI flag) or `maxParallelToolCalls` in settings. Default 4.
- **Cursor**: configurable in Settings → Agent → "Parallel tool calls".
- **OpenAI Agents SDK**: `parallel_tool_calls=False` to force sequential.

If a server misbehaves under parallel load, the quick fix is to drop max parallel to 1 for that server's session. The right fix is to file an issue against the server.

---

## Timeouts and lifecycle tuning

Defaults are usually fine; the cases where you'll tune:

- **Long-running tools** (large SQL queries, full repo scans, browser automation): bump per-call timeout. Some hosts let you set this per-server.
- **Slow-starting servers** (Docker images pulling on first launch, JVM warmup): bump startup timeout to 90–120s.
- **Hosted servers behind a slow network**: bump HTTP request timeout and consider retries.

Claude Code:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp"],
      "timeout": 300000,
      "startupTimeout": 120000
    }
  }
}
```

For HTTP servers, hosts usually expose a request timeout and a per-tool override under the same key.

---

## Common pitfalls

### Secret leakage in committed config

The single most common incident. A `.mcp.json` with a literal token gets pushed, exposed publicly via a fork, and the token is abused within hours. Mitigations:

- Pre-commit hook: `gitleaks protect --staged`.
- CI scanner: `trufflehog filesystem .`.
- Always use `${VAR}` placeholders; commit a `.mcp.json.example`.
- If you're committing real config, gate it through `git-crypt` or a similar at-rest encryption layer.

### PATH surprises on macOS

A GUI-launched host (Claude Desktop, Cursor, Zed) inherits a minimal `PATH` — typically `/usr/bin:/bin:/usr/sbin:/sbin`. `npx`, `node`, `uvx` installed via Homebrew or asdf aren't on that path. Symptoms: server fails to launch with `ENOENT`. Fixes:

- Use absolute paths in `command`.
- Or set `PATH` in `env`: `"PATH": "/opt/homebrew/bin:/usr/local/bin:${PATH}"`.

### Working directory surprises

`cwd` defaults to `$HOME` (or wherever the host was launched from). Servers that read relative paths (`./tsconfig.json`, `package.json`) break. Always set `cwd` explicitly for stdio servers that care about the working directory.

### Stale env after rotating a secret

stdio servers re-read env at launch; if your host keeps the subprocess alive across reloads, your rotated token isn't picked up until you fully quit the host. Restart the host (or kill the specific subprocess) after rotation.

### Mixed transports for the same server

Some servers ship both stdio and Streamable HTTP. Don't configure both in the same host — you'll get duplicate tool names and the model gets confused about which to use. Pick one transport per host.

### Over-broad allowlists

`mcp__github__*` is convenient and the wrong default. Allow specific tool names; widen the list when a workflow hits friction. The friction is a signal, not a bug.

### Unicode and quoting in args

JSON requires strings; if your `args` array contains paths with spaces or unicode, the host passes them as-is. Don't shell-escape (no `\ `, no `\"`) — JSON does that for you.

### Multiple hosts fighting over the same stdio server

If you run two Claude Desktop windows or one Claude Desktop and one Cursor, both will spawn their own subprocess for the same server entry. That's usually fine, but for servers that hold an exclusive lock (some file-backed memory servers, SQLite databases opened in WAL mode by a single writer) it causes races. Prefer the HTTP transport for servers that need a shared backing store.

### Server upgrades silently breaking workflows

`npx -y <pkg>` pulls the latest version every launch. A breaking change in tool naming or argument shape will silently break agent workflows that the model has memorized. Pin versions for any server you depend on in production: `npx -y <pkg>@1.2.3`.

### Forgetting to delete entries

A removed-but-still-configured server quietly stays in the host's tool catalog, polluting context. Audit `claude mcp list` (or the equivalent UI) every couple of months and prune.

---

## Reference: full annotated config

A realistic Claude Code `~/.claude/settings.json` covering most of the patterns above:

```json
{
  "mcpServers": {
    // Local stdio: filesystem rooted in the user's code directory
    "fs": {
      "command": "/opt/homebrew/bin/npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem@2025.11.0",
        "/Users/me/code"
      ]
    },

    // Local stdio: Postgres against staging
    "pg-staging": {
      "command": "/opt/homebrew/bin/npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres@1.4.0"],
      "env": {
        "PATH": "/opt/homebrew/bin:/usr/local/bin:${PATH}",
        "POSTGRES_CONNECTION_STRING": "${PG_STAGING_URL}"
      },
      "timeout": 120000
    },

    // Local stdio via uvx: git server
    "git": {
      "command": "/opt/homebrew/bin/uvx",
      "args": ["mcp-server-git==2025.11.0", "--repository", "/Users/me/code/project"]
    },

    // Docker-isolated: kubernetes
    "k8s": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "/Users/me/.kube:/home/mcp/.kube:ro",
        "quay.io/containers/kubernetes-mcp-server:0.6.0"
      ],
      "startupTimeout": 90000
    },

    // Hosted HTTP: GitHub (OAuth handled by Claude Code on first connect)
    "github": {
      "transport": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },

    // Hosted HTTP with bearer token: Context7 docs lookup
    "context7": {
      "transport": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "Authorization": "Bearer ${CONTEXT7_API_KEY}"
      }
    },

    // Staged for rollout but not active yet
    "linear": {
      "transport": "http",
      "url": "https://mcp.linear.app/mcp",
      "disabled": true
    }
  },

  "permissions": {
    "allow": [
      "mcp__fs__read_file",
      "mcp__fs__list_directory",
      "mcp__fs__search_files",
      "mcp__git__*",
      "mcp__pg-staging__query",
      "mcp__github__list_issues",
      "mcp__github__get_pull_request",
      "mcp__github__list_pull_requests",
      "mcp__context7__*",
      "mcp__k8s__pods_list",
      "mcp__k8s__pods_get"
    ],
    "ask": [
      "mcp__fs__write_file",
      "mcp__fs__edit_file",
      "mcp__github__create_issue",
      "mcp__github__create_pull_request",
      "mcp__k8s__pods_delete",
      "mcp__k8s__resources_create_or_update"
    ],
    "deny": [
      "mcp__pg-staging__execute",
      "mcp__github__delete_repository",
      "mcp__github__merge_pull_request"
    ]
  },

  "maxParallelToolCalls": 4
}
```

Notes on the above:

- Absolute paths for `command` to survive GUI launches.
- Versions pinned for production-relevant servers (`fs`, `pg-staging`, `git`, `k8s`).
- Postgres read-only at staging; no prod connection at all — prod access lives in a separate profile that requires an explicit shell switch.
- GitHub via hosted MCP — no token in the config file.
- Allow / ask / deny tiered by destructiveness; wildcards used only on namespaces where everything is genuinely read-only.

This is roughly the shape you want every team to be running by the time MCP is wired into critical workflows.

---

## Next

- [`building.md`](./building.md) — build your own MCP server.
- [`advanced.md`](./advanced.md) — sampling, notifications, security, federation.
- [`catalog.md`](./catalog.md) — the server catalog.
