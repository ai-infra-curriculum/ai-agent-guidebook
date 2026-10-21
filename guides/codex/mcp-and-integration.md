# OpenAI Codex: MCP and Integration

Connecting Codex to external tools with MCP, embedding Codex in other software (SDKs and the app server), running it in CI with the official GitHub Action, and using Codex Cloud and PR review.

---

## Table of Contents

- [Codex as an MCP Client](#codex-as-an-mcp-client)
- [Configuring MCP in config.toml](#configuring-mcp-in-configtoml)
- [MCP Authentication](#mcp-authentication)
- [MCP Tool Approval and Limits](#mcp-tool-approval-and-limits)
- [Running Codex as an MCP Server (Removed)](#running-codex-as-an-mcp-server-removed)
- [Codex SDK](#codex-sdk)
- [CI with codex exec](#ci-with-codex-exec)
- [The Codex GitHub Action](#the-codex-github-action)
- [Pattern: Auto-Fix Failing CI](#pattern-auto-fix-failing-ci)
- [Codex Cloud and Code Review](#codex-cloud-and-code-review)
- [Security Checklist for Automation](#security-checklist-for-automation)
- [Next Steps](#next-steps)

---

## Codex as an MCP Client

Codex connects to MCP servers and exposes their tools to the agent. The CLI, IDE extension, and ChatGPT desktop app share MCP configuration, so you configure a server once.

**Supported:**

- **STDIO servers** — local processes started by a command, with environment variables.
- **Streamable HTTP servers** — bearer-token auth, OAuth (including Client ID Metadata Documents and Dynamic Client Registration), and ChatGPT-session auth for trusted first-party servers.
- **Server instructions** — Codex reads the MCP `instructions` field from initialization and uses it as server-wide guidance. If you maintain a server, keep the first 512 characters self-contained.

### Add servers from the CLI

```bash
# stdio server
codex mcp add context7 -- npx -y @upstash/context7-mcp

# stdio server with environment variables
codex mcp add <server-name> --env VAR1=VALUE1 --env VAR2=VALUE2 -- <stdio server-command>

# Streamable HTTP server with an OAuth client ID
codex mcp add example --url https://mcp.example.com --oauth-client-id my-client

codex mcp list               # configured servers
codex mcp login <server>     # OAuth login (Streamable HTTP servers that support OAuth)
codex mcp --help             # all subcommands
```

Inside a session, `/mcp` lists available tools (`/mcp verbose` for server details).

Source: [Model Context Protocol](https://learn.chatgpt.com/docs/extend/mcp).

---

## Configuring MCP in config.toml

Each server is a `[mcp_servers.<name>]` table in `~/.codex/config.toml`, or in a project's `.codex/config.toml` (loaded only for trusted projects).

### STDIO servers

| Key | Purpose |
|-----|---------|
| `command` (required) | Command that starts the server |
| `args` | Arguments |
| `env` | Environment variables to set for the server |
| `env_vars` | Environment variables to allow and forward from your environment |
| `cwd` | Working directory for the server |

```toml
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
env_vars = ["LOCAL_TOKEN"]

[mcp_servers.context7.env]
MY_ENV_VAR = "MY_ENV_VALUE"
```

### Streamable HTTP servers

| Key | Purpose |
|-----|---------|
| `url` (required) | Server address |
| `bearer_token_env_var` | Name of an env var whose value is sent as a bearer token |
| `http_headers` | Static header map |
| `env_http_headers` | Header names mapped to env var names |
| `http_headers_helper` | Local command that prints a JSON object of headers (local HTTP connections only) |
| `auth` | `oauth` (default, stored MCP OAuth credentials) or `chatgpt` (current ChatGPT session for the trusted first-party origin) |

```toml
[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"
bearer_token_env_var = "FIGMA_OAUTH_TOKEN"
http_headers = { "X-Figma-Region" = "us-east-1" }
```

### Common keys

| Key | Default | Purpose |
|-----|---------|---------|
| `enabled` | `true` | Set `false` to disable without deleting |
| `required` | `false` | Fail startup (and `codex exec`) if this server can't initialize |
| `startup_timeout_sec` | `10` | Server start timeout |
| `tool_timeout_sec` | `60` | Per-tool-call timeout |
| `enabled_tools` / `disabled_tools` | — | Allow list / deny list (deny applied after allow) |
| `default_tools_approval_mode` | — | `auto`, `prompt`, `writes` (prompt for tools not marked read-only), or `approve` |
| `tools.<tool>.approval_mode` | — | Per-tool override |
| `tools.<tool>.output_token_limit` | — | Output token budget for one tool |

The top-level `mcp_optional_startup_grace_ms` (default `1000`) controls how long Codex waits for optional servers while building the initial tool catalog.

Source: [Model Context Protocol](https://learn.chatgpt.com/docs/extend/mcp), [Configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference).

---

## MCP Authentication

- **Bearer tokens** — prefer `bearer_token_env_var` over pasting tokens into `http_headers`, so secrets stay in your environment or secret manager.
- **OAuth** — run `codex mcp login <server>`. To force a client-registration method: `codex mcp login <server> --oauth-client-registration cimd` (or `dcr`). Static client config and callbacks can live in the server table:

```toml
[mcp_servers.example]
url = "https://mcp.example.com"

[mcp_servers.example.oauth]
client_id = "my-client"
callback_url = "http://127.0.0.1/callback"
```

On remote dev boxes, override the callback globally with `mcp_oauth_callback_port` and `mcp_oauth_callback_url`.

---

## MCP Tool Approval and Limits

MCP calls flow through the same approval system as shell commands:

- Destructive tools (those advertising a destructive annotation) **always** require approval unless they also advertise a read annotation.
- Use `default_tools_approval_mode = "writes"` for servers that mix read and write tools, and pin individual tools with `tools.<tool>.approval_mode`.
- Narrow the surface with `enabled_tools` instead of exposing everything a server offers.
- A granular approval policy can keep `mcp_elicitations` prompts interactive while auto-rejecting other categories — see [usage.md](usage.md#sandbox-and-approvals).

```toml
[mcp_servers.chrome_devtools]
url = "http://localhost:3000/mcp"
enabled_tools = ["open", "screenshot"]
default_tools_approval_mode = "prompt"
startup_timeout_sec = 20
tool_timeout_sec = 45

[mcp_servers.chrome_devtools.tools.open]
approval_mode = "approve"
output_token_limit = 30000
```

For cross-tool MCP governance, see the [MCP servers guide](../mcp-servers/installation.md).

---

## Running Codex as an MCP Server (Removed)

Older tutorials show `codex mcp-server` (or a `codex-mcp-server` binary) to let another agent — or the OpenAI Agents SDK — drive Codex as an MCP tool. **Both have been removed.** Integrations that launch either command must migrate before upgrading Codex.

The replacement is the **Codex app server**, which handles authentication, conversation history, approvals, and streamed agent events over its own **JSON-RPC protocol**. It is *not* an MCP server or a drop-in replacement for MCP tool calls, and OpenAI marks the app-server command **experimental and not supported for production workloads**.

```bash
codex app-server                          # JSONL over stdio (default; --stdio is an alias)
codex app-server --listen ws://127.0.0.1:4500   # WebSocket transport
```

For most automation, the [Codex SDK](#codex-sdk) or [`codex exec`](#ci-with-codex-exec) is simpler.

Sources: [Codex MCP server removal](https://learn.chatgpt.com/docs/mcp-server), [Codex app server](https://learn.chatgpt.com/docs/app-server), [Developer commands](https://learn.chatgpt.com/docs/developer-commands?surface=cli).

---

## Codex SDK

Use the SDK to control local Codex agents from your own code — CI pipelines, internal tools, or agents that hand engineering tasks to Codex.

### TypeScript

Server-side only; requires Node.js 18+.

```bash
npm install @openai/codex-sdk
```

```ts
import { Codex } from "@openai/codex-sdk";

const codex = new Codex();
const thread = codex.startThread();

const result = await thread.run("Make a plan to diagnose and fix the CI failures");
console.log(result.finalResponse);

// Continue the same thread
const next = await thread.run("Implement the plan");
console.log(next.finalResponse);

// Resume a past thread by ID
const thread2 = codex.resumeThread("<thread-id>");
const result2 = await thread2.run("Pick up where you left off");
console.log(result2.finalResponse);
```

Pass structured configuration with `config`, and raw TOML overrides (passed as separate `--config` arguments) with `configOverrides`. These don't modify your config files. `CODEX_API_KEY` works with the TypeScript SDK.

### Python

Requires Python 3.10+. The Python SDK drives the local app server over JSON-RPC, and published builds pin a Codex CLI runtime.

```bash
pip install openai-codex
```

```python
from openai_codex import Codex, Sandbox

with Codex() as codex:
    thread = codex.thread_start(sandbox=Sandbox.workspace_write)  # omit model to use your default
    result = thread.run("Make a plan to diagnose and fix the CI failures")
    print(result.final_response)

    # Tighten permissions for a later turn
    review = thread.run("Review the diff only.", sandbox=Sandbox.read_only)
    print(review.final_response)
```

`AsyncCodex` is available for async applications. Sandbox presets: `Sandbox.read_only`, `Sandbox.workspace_write`, `Sandbox.full_access`.

Sources: [Codex SDK](https://learn.chatgpt.com/docs/codex-sdk), [sdk/typescript](https://github.com/openai/codex/tree/main/sdk/typescript), [sdk/python](https://github.com/openai/codex/tree/main/sdk/python).

---

## CI with codex exec

For non-GitHub CI (GitLab, Buildkite, Jenkins), install the CLI and run `codex exec` with explicit permissions:

```bash
npm install -g @openai/codex@0.163.0        # pin a version

CODEX_API_KEY="$OPENAI_API_KEY" codex exec \
  --sandbox read-only \
  --ephemeral \
  --json \
  -o codex-summary.md \
  "Review the changes on this branch against main and list blocking issues only."
```

Guidelines from the docs:

- **API keys are the right default for automation.** Set `CODEX_API_KEY` *only* on the Codex invocation — never as a job-wide env var in a job that also runs repository-controlled code (build scripts, tests, dependency lifecycle hooks can read it).
- **Least privilege:** `read-only` (the exec default) for analysis; `workspace-write` when it must edit; `danger-full-access` only on an isolated runner.
- **Determinism:** `--ignore-user-config` and `--ignore-rules` give a clean, controlled environment; `--output-schema` gives a stable final shape.
- **Running as a ChatGPT account in CI** (instead of an API key) is possible on trusted runners by seeding `~/.codex/auth.json` from secure storage — never for public or open-source repos.

Source: [Non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode).

---

## The Codex GitHub Action

On GitHub, use [`openai/codex-action@v1`](https://github.com/openai/codex-action) instead of installing the CLI and handing it your key. The action installs Codex, starts a **Responses API proxy** so the key isn't exposed to Codex directly, and runs `codex exec` under the permissions you set.

```yaml
name: Codex pull request review
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  codex:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    outputs:
      final_message: ${{ steps.run_codex.outputs.final-message }}
    steps:
      - uses: actions/checkout@v5
        with:
          ref: refs/pull/${{ github.event.pull_request.number }}/merge
          fetch-depth: 0
          persist-credentials: false

      - name: Run Codex
        id: run_codex
        uses: openai/codex-action@v1
        with:
          openai-api-key: ${{ secrets.OPENAI_API_KEY }}
          prompt-file: .github/codex/prompts/review.md
          output-file: codex-output.md

  post_feedback:
    runs-on: ubuntu-latest
    needs: codex
    if: needs.codex.outputs.final_message != ''
    permissions:
      issues: write
      pull-requests: write
    steps:
      - uses: actions/github-script@v7
        with:
          github-token: ${{ github.token }}
          script: |
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.payload.pull_request.number,
              body: process.env.CODEX_FINAL_MESSAGE,
            });
        env:
          CODEX_FINAL_MESSAGE: ${{ needs.codex.outputs.final_message }}
```

Note the split: the Codex job has only `contents: read`; the job that writes to the PR never sees the API key.

### Inputs

| Input | Purpose |
|-------|---------|
| `openai-api-key` | API key (from a secret); starts the proxy |
| `prompt` / `prompt-file` | Inline task or a repo file (use exactly one) |
| `codex-args` | Extra CLI flags as a JSON array or shell string (e.g. `["--ephemeral"]`, `--profile ci`) |
| `model`, `effort` | Model and reasoning effort (empty = defaults) |
| `sandbox` | `workspace-write`, `read-only`, or `danger-full-access` |
| `output-file` | Write the final message to disk |
| `codex-version` | Pin a CLI release |
| `codex-home` | Shared Codex home for config/MCP across steps |
| `safety-strategy` | `drop-sudo` (default), `unprivileged-user` (with `codex-user`), `read-only`, or `unsafe` (required on Windows runners) |
| `allow-users`, `allow-bots` | Who may trigger the action (default: users with write access) |

The action's `final-message` output carries Codex's last message. Run on Linux or macOS runners; on Windows you must set `safety-strategy: unsafe`.

Source: [Codex GitHub Action](https://learn.chatgpt.com/docs/github-action).

---

## Pattern: Auto-Fix Failing CI

The docs' recommended shape for "Codex proposes a fix when CI fails":

1. Trigger on `workflow_run` when your CI workflow completes with `failure`.
2. Check out the failing commit with **`contents: read`** only and `persist-credentials: false`.
3. Install dependencies **before** Codex, so setup steps never see the API key.
4. Run `openai/codex-action@v1` with a narrowly scoped prompt ("reproduce with `npm test`, make the minimal change, don't refactor unrelated files").
5. Save `git diff --binary` as a patch artifact.
6. In a **separate job** with `contents: write` / `pull-requests: write` — and no API key — apply the patch and open a PR for human review.

The full workflow is in [Non-interactive mode → Autofix CI failures](https://learn.chatgpt.com/docs/non-interactive-mode), and the action's [security guidance](https://github.com/openai/codex-action/blob/main/docs/security.md) covers more hardening.

---

## Codex Cloud and Code Review

### Codex Cloud

Codex Cloud runs tasks in **published cloud environments**: Codex inspects your GitHub repos, installs dependencies, tests the workflow, and you publish the environment. Each task gets its own workspace and keeps running while your computer sleeps; review results and open a PR from web, mobile, or the desktop app.

From the terminal:

```bash
codex cloud                                   # interactive picker of cloud chats
codex cloud exec --env <ENV_ID> "Fix the flaky test in tests/test_api.py"
codex cloud exec --env <ENV_ID> --attempts 3 --branch main "Add pagination to /users"
codex cloud list --json                       # recent tasks (tasks[] + cursor)
codex cloud status <TASK_ID>
codex cloud diff <TASK_ID>
codex apply <TASK_ID>                         # apply the task's latest diff locally
```

`codex apply` exits non-zero if `git apply` fails (e.g. conflicts). Cloud features require ChatGPT sign-in — they aren't available with API-key auth.

### PR review on GitHub

1. Connect the repo to Codex and open [Codex code review settings](https://chatgpt.com/settings/code-review).
2. Turn on **Automatic review** for the repo (and choose a **Review trigger**), or request one ad hoc by commenting **`@codex review`** on a PR — optionally with a focus, e.g. `@codex review for issues in the database migration`.
3. Codex posts a standard GitHub review and flags only **P0 and P1** issues.
4. Encode repo-specific checks in a `## Code Review Rules` section of the nearest `AGENTS.md` (see [usage.md](usage.md#agentsmd)). Keep lint/format checks in CI.

**Security Review** (research preview) goes deeper on security risks using the diff, repository context, and configured threat models. Enable **Auto security review** in the same settings page, or comment `@codex security review`.

GitLab merge requests support `@codex review` and automatic reviews as well. Codex also integrates with **Slack** and **Linear** for delegating work to Codex Cloud.

Sources: [Codex Cloud](https://learn.chatgpt.com/docs/cloud), [Developer commands — codex cloud](https://learn.chatgpt.com/docs/developer-commands?surface=cli), [Review GitHub PRs](https://learn.chatgpt.com/docs/third-party/github), [Review GitLab MRs](https://learn.chatgpt.com/docs/third-party/gitlab), [openai/codex cloud-tasks source](https://github.com/openai/codex/tree/main/codex-rs/cloud-tasks).

---

## Security Checklist for Automation

- [ ] Run Codex with the **narrowest sandbox** that completes the task; default to `read-only`.
- [ ] Never use `--yolo` / `danger-full-access` outside an isolated, disposable runner.
- [ ] Scope `CODEX_API_KEY` to the single Codex step; use the GitHub Action's proxy on GitHub.
- [ ] Keep `safety-strategy: drop-sudo` (or `unprivileged-user`); never `unsafe` on shared runners.
- [ ] Restrict who can trigger workflows (`allow-users`, trusted events only).
- [ ] Treat PR titles, bodies, commit messages, and issue text as **untrusted prompt input** (prompt injection); review hidden HTML comments.
- [ ] Separate "Codex proposes" (read-only job) from "write to the repo" (no-key job) and keep a human merge gate.
- [ ] Pin `codex-version` / the npm version so behavior doesn't change under you.
- [ ] Mark must-have MCP servers `required = true` so a missing tool fails loudly instead of silently.
- [ ] Rotate keys immediately if logs or outputs may have exposed them.

---

## Next Steps

- [Usage](usage.md) — interactive mode, sandbox, `AGENTS.md`, config, slash commands
- [Installation](installation.md) — setup and authentication
- [MCP servers guide](../mcp-servers/installation.md)
- [Main Codex README](README.md)

---

**Last Updated**: 2026-10-21
