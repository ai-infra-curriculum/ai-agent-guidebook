# Model Context Protocol (MCP): Conceptual Guide

A practitioner's introduction to MCP — what it is, the problem it solves, how it works, and where it fits in the broader agent ecosystem.

> **Spec reference**: This guide tracks the MCP specification revision **2025-06-18** (latest stable), with notes on the **2025-11-05** draft where relevant. Official spec: <https://spec.modelcontextprotocol.io/>.

> **Last updated**: 2026-05-24

---

## Table of Contents

- [What is MCP?](#what-is-mcp)
- [Why MCP exists: the M × N problem](#why-mcp-exists-the-m--n-problem)
- [The client / server / transport model](#the-client--server--transport-model)
- [The three primitives: tools, resources, prompts](#the-three-primitives-tools-resources-prompts)
- [Lifecycle of an MCP session](#lifecycle-of-an-mcp-session)
- [MCP vs. other integration models](#mcp-vs-other-integration-models)
- [Where MCP fits in the agent stack](#where-mcp-fits-in-the-agent-stack)
- [What MCP is not](#what-mcp-is-not)
- [Adoption snapshot (mid-2026)](#adoption-snapshot-mid-2026)
- [Further reading](#further-reading)

---

## What is MCP?

The **Model Context Protocol (MCP)** is an open JSON-RPC 2.0 based protocol that standardizes how an LLM application (the **host**) connects to external **tools**, **data sources**, and **prompt libraries**. It was introduced by Anthropic in late 2024 and quickly adopted across the major coding assistants and agent frameworks.

In one sentence: **MCP is to AI assistants what the Language Server Protocol (LSP) is to code editors.** Instead of every editor implementing a custom integration for every language, LSP gave editors a single protocol; instead of every AI assistant implementing custom integrations for every tool or data source, MCP gives assistants a single protocol.

A minimal mental model:

```
+----------------+        JSON-RPC 2.0         +----------------+
|                | <-------------------------> |                |
|   MCP Host     |     (stdio or HTTP/SSE)     |   MCP Server   |
|  (e.g. Claude) |                             |  (your tools)  |
|                |  initialize, list_tools,    |                |
|                |  call_tool, read_resource…  |                |
+----------------+                             +----------------+
```

The host launches or connects to one or more servers. Each server exposes a small, well-typed surface — tools the model can invoke, resources the model can read, and prompts the user can apply. The host wires those into the model's context.

---

## Why MCP exists: the M × N problem

Before MCP, every AI assistant had to build a custom integration for every tool, and every tool vendor had to build a custom integration for every assistant. If you have **M** assistants and **N** tools, you have **M × N** integrations to maintain. Every new assistant means N new integrations; every new tool means M new integrations.

```
Without MCP (M × N):

  Claude Desktop ── custom ── GitHub
                ── custom ── Postgres
                ── custom ── Slack
  Cursor        ── custom ── GitHub
                ── custom ── Postgres
                ── custom ── Slack
  Cline         ── custom ── GitHub
                ── custom ── Postgres
                ── custom ── Slack
  …             …            …
```

MCP collapses this to **M + N**:

```
With MCP (M + N):

  Claude Desktop ─┐                           ┌── GitHub MCP server
  Cursor         ─┼── MCP protocol ──┼── ─────┼── Postgres MCP server
  Cline          ─┘                           └── Slack MCP server
  …                                              …
```

Each host implements MCP once. Each tool publishes one MCP server. The two sides compose without bilateral knowledge of each other. This is the same shape of leverage that LSP gave editors, OpenAPI gave HTTP clients, and OCI gave container runtimes.

**Practical consequence**: when you build an MCP server for your internal tool, every MCP-aware assistant — Claude Desktop, Claude Code, Cursor, Cline, Continue, Windsurf, Zed, plus framework-side clients in LangGraph, AutoGen, CrewAI, OpenAI Agents SDK, etc. — can use it without bespoke integration code.

---

## The client / server / transport model

MCP defines three roles:

### Host

The application the user interacts with. It owns the conversation, decides which servers to launch, and surfaces tool results to the model. Examples: Claude Desktop, Claude Code, Cursor, Cline, Continue, Zed.

A host can manage **many clients** at once — typically one per connected server.

### Client

A library inside the host that speaks MCP to exactly one server. The client handles protocol negotiation, capability discovery, message framing, and lifecycle. From the host's perspective, a client is the local proxy for a remote (or local subprocess) server.

### Server

A separate process that exposes some capability — file access, database queries, browser automation, ticket creation, anything. Each server speaks MCP to its single connected client. Servers are usually small, focused, and stateless across requests (state lives in the underlying system the server fronts).

### Transports

MCP is transport-agnostic but the spec defines two transports natively:

| Transport | When to use | How it works |
|---|---|---|
| **stdio** | Local servers, subprocess model | Host spawns the server as a child process and exchanges JSON-RPC over stdin/stdout. Stderr is reserved for logs. |
| **Streamable HTTP** | Remote / hosted servers | Single HTTP endpoint that accepts POST (client → server) and uses Server-Sent Events (SSE) for streaming (server → client). Replaced the older split HTTP+SSE transport in the 2025-03-26 spec revision. |

stdio is dominant for local developer tooling. Streamable HTTP is dominant for hosted multi-tenant servers (think: GitHub's hosted MCP, Sentry's hosted MCP, Stripe's hosted MCP).

```
+-----------+        stdio        +-----------+
|   Host    |  ───────────────────│   Server  |    (local subprocess)
+-----------+                     +-----------+

+-----------+   POST + SSE  /mcp  +-----------+
|   Host    |  ───────────────────│   Server  |    (remote, multi-tenant)
+-----------+                     +-----------+
```

### Protocol layer

The wire format is **JSON-RPC 2.0**. Each message is either a *request* (expects a response), a *response* (correlates to a request via `id`), or a *notification* (fire-and-forget). MCP layers a typed message catalog on top: `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get`, plus notifications like `notifications/tools/list_changed` and `notifications/progress`.

---

## The three primitives: tools, resources, prompts

MCP exposes exactly three primitives. Each has a distinct role and a different control model.

### Tools — model-controlled actions

A **tool** is a callable function the model decides to invoke. Tools have a name, a description, and a JSON Schema for inputs. The host normally surfaces them to the model the same way it would surface any function-calling tool.

```json
{
  "name": "create_issue",
  "description": "Create a new GitHub issue in the specified repo.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "repo":  { "type": "string" },
      "title": { "type": "string" },
      "body":  { "type": "string" }
    },
    "required": ["repo", "title"]
  }
}
```

Calling a tool returns content — text, images, or embedded resources. Tools may have side effects; the host should treat every tool call as a sensitive action and apply allowlists, prompts, and audit logging accordingly. The spec's **2025-06-18** revision added structured tool output (`structuredContent` + `outputSchema`), which lets servers return typed JSON that downstream tools can consume without re-parsing.

### Resources — application-controlled data

A **resource** is a piece of data the server can expose by URI. Examples: a file, a database row, a wiki page, a Figma node, the contents of an environment variable. Resources are *application-controlled*: the host (or user) decides which ones to attach to context, not the model directly.

```json
{
  "uri": "file:///repo/README.md",
  "name": "README",
  "mimeType": "text/markdown"
}
```

Hosts typically surface resources as `@mentions`, attachment pickers, or auto-context (e.g. attach the resource the user is currently viewing). Resources can be **subscribed** so the server pushes updates when the underlying data changes.

### Prompts — user-controlled templates

A **prompt** is a parameterized template the *user* explicitly invokes — typically via a slash command or palette. The server returns a sequence of messages (system / user / assistant) that the host injects into the conversation.

```json
{
  "name": "summarize_pr",
  "description": "Summarize a GitHub PR for changelog entry.",
  "arguments": [
    { "name": "pr_number", "required": true }
  ]
}
```

In Claude Code, server prompts surface as `/<server>:<prompt>` slash commands. In Cursor and Cline they appear in the command palette. Prompts are how a server vendor ships expert workflows alongside the raw tool surface.

### Control-model summary

| Primitive | Who decides to invoke it | Typical UX |
|---|---|---|
| Tool | Model | Function calling |
| Resource | Application / user | `@mention`, attachment, auto-context |
| Prompt | User | Slash command, palette entry |

This separation matters for safety and UX. You don't want the model auto-reading every resource in your filesystem, and you don't want the user manually approving every benign `read_file`. Different control models for different threat profiles.

---

## Lifecycle of an MCP session

Every MCP session follows the same four-phase shape.

### 1. Initialization

Host launches (stdio) or connects to (HTTP) the server, then sends an `initialize` request advertising:

- The protocol version it speaks.
- Its **client capabilities** (sampling? roots? elicitation?).
- Client info (name, version).

The server responds with:

- The protocol version it agrees to.
- Its **server capabilities** (tools? resources? prompts? logging? completion?).
- Server info.

The client confirms with a `notifications/initialized` notification. Capability negotiation here is what lets the protocol evolve without breaking old clients — neither side calls a method the other didn't advertise.

```
Host                             Server
 │   initialize(version, caps)    │
 ├───────────────────────────────>│
 │                                │
 │   initialized response         │
 │<───────────────────────────────┤
 │                                │
 │   notifications/initialized    │
 ├───────────────────────────────>│
```

### 2. Discovery

The host queries what's available:

- `tools/list` → list of tools the model can call.
- `resources/list` (and optionally `resources/templates/list`) → list of attachable data.
- `prompts/list` → list of user-invokable templates.

Each is paginated via opaque `cursor` tokens.

### 3. Operation

The active phase. The host:

- Calls tools (`tools/call`) when the model emits a tool use.
- Reads resources (`resources/read`) when the user attaches one.
- Fetches prompts (`prompts/get`) when the user runs a slash command.

The server may push:

- `notifications/tools/list_changed` — refetch tools.
- `notifications/resources/updated` — re-read a subscribed resource.
- `notifications/progress` — long-running operation feedback.
- `notifications/message` — server-side log lines.

### 4. Shutdown

Closing the transport terminates the session. For stdio, the host sends EOF on stdin, gives the server a grace period, then SIGTERMs if needed. For HTTP, the host closes the SSE stream.

---

## MCP vs. other integration models

It helps to be precise about what's the same and what's different.

### vs. OpenAI function calling / Anthropic tool use

Function calling is the **model-level** mechanism: the model emits a structured request to call a named function with arguments. MCP is the **application-level** mechanism for *where those functions come from and how they get registered*. The two compose:

- The server publishes tools via MCP.
- The host fetches them, adapts them to the model provider's tool-use schema (OpenAI `tools`, Anthropic `tools`, Gemini `function_declarations`), and sends them with the request.
- When the model emits a tool call, the host routes it back through MCP to the right server.

You can use function calling without MCP (hard-coded tools), and you can use MCP without exposing tools to a model (e.g. resources only). But the most common pattern is MCP-supplied tools surfaced via the provider's function-calling API.

### vs. ChatGPT plugins (deprecated)

The 2023 ChatGPT plugin spec used OpenAPI + an `ai-plugin.json` manifest, was HTTPS-only, ran inside a single host (ChatGPT), and was deprecated in March 2024. MCP took the lessons — open spec, multi-host, multi-transport, primitives beyond tools — and avoided the lock-in. If you remember plugins fondly: MCP is the version that worked.

### vs. LangChain tools / LlamaIndex tools / framework-native tools

Framework tool abstractions live *inside* a framework's process. Anything written as a LangChain `Tool` only runs in a LangChain agent. MCP tools run in a separate process behind a wire protocol, so a single server is reusable across Claude Desktop, Cursor, LangGraph, CrewAI, AutoGen, and your own custom client.

Modern frameworks have MCP adapters that surface MCP servers as native tools: `langchain-mcp-adapters`, `crewai-tools[mcp]`, AutoGen's `mcp` extension, OpenAI Agents SDK's `MCPServerStdio` / `MCPServerSse`, Bedrock AgentCore's MCP client. Write the server once; consume it everywhere.

### vs. REST / OpenAPI

A REST API is a great wire format for service-to-service traffic but a poor fit for LLM tool surfaces directly: too verbose, no first-class tool/resource/prompt distinction, no streaming notifications, no capability negotiation, and tool descriptions live in human prose rather than model-targeted summaries. MCP servers often *wrap* REST APIs — that's a healthy pattern — but the LLM-facing surface deserves its own protocol shaped around the model's needs.

### vs. gRPC / Thrift / Cap'n Proto

These are excellent for typed RPC between services you control. MCP's value is being a *standard the model ecosystem already speaks*. Even if MCP were technically inferior, the network effect of "every assistant supports it" is the actual product.

### vs. shell commands / direct subprocess execution

You can always tell an agent "run this command." MCP is the structured version: typed inputs, declared side-effects, auditable invocations, allowlists, and consistent error handling. Shell is the lowest-floor / lowest-ceiling option; MCP raises both.

---

## Where MCP fits in the agent stack

A useful way to slice the modern agent stack:

```
+--------------------------------------------------+
|                 Application UX                   |  Claude Desktop, Cursor, your app
+--------------------------------------------------+
|              Agent runtime / harness             |  LangGraph, OpenAI Agents SDK,
|                                                  |  CrewAI, AutoGen, custom loop
+--------------------------------------------------+
|              Model API                           |  Anthropic, OpenAI, Google,
|                                                  |  Bedrock, Azure, local
+--------------------------------------------------+
|              MCP (this layer)                    |  Tool / resource / prompt surface
+--------------------------------------------------+
|              Underlying systems                  |  GitHub, Postgres, your APIs,
|                                                  |  filesystem, browser, …
+--------------------------------------------------+
```

MCP is the *standardized seam* between an agent runtime and the rest of the world. It is intentionally narrow — it does not prescribe how you orchestrate multi-step reasoning, how you manage memory, how you do evals, or how you do tracing. Those live above MCP, in the agent runtime or the application.

This means MCP composes with, rather than replaces:

- **Orchestration frameworks** (LangGraph, Inngest, Temporal): the framework runs the loop; MCP supplies the tools.
- **Memory systems** (Mem0, Letta, Zep): memory is its own concern; MCP can expose memory read/write as tools or resources but doesn't define the memory model.
- **Observability** (LangSmith, Langfuse, Arize Phoenix, OpenTelemetry): tracing wraps the host's tool calls; MCP doesn't mandate a trace format but tool invocations are a natural span boundary.
- **Governance & trust** (policy engines, audit ledgers, identity providers): the host enforces policy *around* MCP calls; MCP itself does not define an authorization model beyond the OAuth 2.1 + Resource Indicators flow added in the 2025-06-18 revision for HTTP transports.

---

## What MCP is not

A few common misconceptions worth flattening up front.

- **MCP is not an agent framework.** It does not implement planning, loops, reflection, or memory. It is a tool/data integration protocol.
- **MCP is not a sandbox.** A tool call runs whatever code the server runs. Sandboxing is the host's and the server author's responsibility.
- **MCP is not an authentication system.** The transport layer carries auth (OAuth 2.1 for HTTP, environment for stdio). MCP doesn't define users, roles, or scopes beyond capability negotiation.
- **MCP is not bound to Anthropic.** It is an open spec with a community-elected governance model. Production deployments run on OpenAI, Google, Mistral, Llama, and local models alike.
- **MCP is not "tools over HTTP."** That phrasing misses resources, prompts, notifications, sampling, and the lifecycle. The protocol's value is the full surface, not just function dispatch.

---

## Adoption snapshot (mid-2026)

A non-exhaustive list of where MCP shows up:

**First-class hosts**: Claude Desktop, Claude Code, Cursor, Cline, Continue, Windsurf, Zed, Sourcegraph Cody, JetBrains AI Assistant, Codeium, Replit, Aider.

**Framework clients**: OpenAI Agents SDK, LangChain / LangGraph (`langchain-mcp-adapters`), CrewAI (`crewai-tools[mcp]`), AutoGen (`autogen-ext[mcp]`), LlamaIndex (`llama-index-tools-mcp`), Pydantic AI, AWS Bedrock AgentCore, Microsoft Semantic Kernel, Microsoft Agent Framework.

**Hosted MCP servers** (you connect via Streamable HTTP, no install): GitHub, GitLab, Sentry, Stripe, Linear, Notion, Atlassian (Jira + Confluence), Cloudflare, Vercel, Neon, Supabase, PlanetScale, Figma, Canva, Plaid.

**Spec governance**: managed under the `modelcontextprotocol` GitHub org with a public spec process (SEP — Specification Enhancement Proposals), regular revisions (2024-11-05 → 2025-03-26 → 2025-06-18 → 2025-11-05 draft), and a multi-vendor steering committee.

---

## Further reading

- **Spec**: <https://spec.modelcontextprotocol.io/>
- **Reference implementation servers**: <https://github.com/modelcontextprotocol/servers>
- **TypeScript SDK**: <https://github.com/modelcontextprotocol/typescript-sdk>
- **Python SDK**: <https://github.com/modelcontextprotocol/python-sdk>
- **Inspector** (debug tool): <https://github.com/modelcontextprotocol/inspector>
- **Awesome MCP**: <https://github.com/punkpeye/awesome-mcp-servers>
- **Catalog (this guide)**: [`catalog.md`](./catalog.md)

Next, see:

- [`installation.md`](./installation.md) — installing servers across hosts.
- [`configuration.md`](./configuration.md) — config file shapes and patterns.
- [`building.md`](./building.md) — building your own server in TypeScript or Python.
- [`advanced.md`](./advanced.md) — sampling, notifications, security, federation.
