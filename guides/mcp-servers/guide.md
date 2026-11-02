# Model Context Protocol (MCP): Conceptual Guide

A practitioner's introduction to MCP — what it is, the problem it solves, how it works, and where it fits in the broader agent ecosystem.

> **Spec reference**: This guide tracks the MCP specification revision **2026-07-28** (current since 2026-07-28), with notes on earlier revisions where features were introduced or changed. Official spec: <https://modelcontextprotocol.io/specification/latest>.

> **Last updated**: 2026-10-21

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
- [Adoption snapshot (late 2026)](#adoption-snapshot-late-2026)
- [Further reading](#further-reading)

---

## What is MCP?

The **Model Context Protocol (MCP)** is an open JSON-RPC 2.0 based protocol that standardizes how an LLM application (the **host**) connects to external **tools**, **data sources**, and **prompt libraries**. It was introduced by Anthropic in late 2024, quickly adopted across the major coding assistants and agent frameworks, and in December 2025 donated to the **Agentic AI Foundation (AAIF)**, a directed fund under the Linux Foundation.

In one sentence: **MCP is to AI assistants what the Language Server Protocol (LSP) is to code editors.** Instead of every editor implementing a custom integration for every language, LSP gave editors a single protocol; instead of every AI assistant implementing custom integrations for every tool or data source, MCP gives assistants a single protocol.

A minimal mental model:

```
+----------------+        JSON-RPC 2.0         +----------------+
|                | <-------------------------> |                |
|   MCP Host     |  (stdio or Streamable HTTP) |   MCP Server   |
|  (e.g. Claude) |                             |  (your tools)  |
|                |  server/discover,           |                |
|                |  tools/list, tools/call,    |                |
|                |  resources/read…            |                |
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

A library inside the host that speaks MCP to exactly one server. The client handles protocol-version negotiation, capability discovery, message framing, and (on older revisions) the connection lifecycle. From the host's perspective, a client is the local proxy for a remote (or local subprocess) server.

### Server

A separate process that exposes some capability — file access, database queries, browser automation, ticket creation, anything. Each server speaks MCP to its single connected client. Servers are usually small, focused, and stateless across requests (state lives in the underlying system the server fronts). As of 2026-07-28 the *protocol itself* is stateless too — there is no handshake or session, so any request can land on any server instance.

### Transports

MCP is transport-agnostic but the spec defines two transports natively:

| Transport | When to use | How it works |
|---|---|---|
| **stdio** | Local servers, subprocess model | Host spawns the server as a child process and exchanges JSON-RPC over stdin/stdout. Stderr is reserved for logs. |
| **Streamable HTTP** | Remote / hosted servers | Single HTTP endpoint. The client POSTs each request; the server answers with JSON or an SSE stream scoped to that request. On 2026-07-28 there is no session ID and no GET stream — change notifications use an opt-in `subscriptions/listen` POST stream, and requests carry `Mcp-Method` / `Mcp-Name` headers for routing. Replaced the older split HTTP+SSE transport in 2025-03-26 (that transport is now formally deprecated). |

stdio is dominant for local developer tooling. Streamable HTTP is dominant for hosted multi-tenant servers (think: GitHub's hosted MCP, Sentry's hosted MCP, Stripe's hosted MCP).

```
+-----------+        stdio        +-----------+
|   Host    |  ───────────────────│   Server  |    (local subprocess)
+-----------+                     +-----------+

+-----------+   POST  /mcp        +-----------+
|   Host    |  ───────────────────│   Server  |    (remote, multi-tenant)
+-----------+                     +-----------+
```

### Protocol layer

The wire format is **JSON-RPC 2.0**. Each message is either a *request* (expects a response), a *response* (correlates to a request via `id`), or a *notification* (fire-and-forget). MCP layers a typed message catalog on top: `server/discover`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get`, `subscriptions/listen`, plus notifications like `notifications/tools/list_changed` and `notifications/progress`. On 2026-07-28 every request also carries its protocol version and client capabilities in `params._meta` (`io.modelcontextprotocol/protocolVersion`, `io.modelcontextprotocol/clientCapabilities`), and every result carries a `resultType`. Servers on 2025-11-25 and earlier use the `initialize` handshake instead.

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

Calling a tool returns content — text, images, or embedded resources. Tools may have side effects; the host should treat every tool call as a sensitive action and apply allowlists, prompts, and audit logging accordingly. The spec's **2025-06-18** revision added structured tool output (`structuredContent` + `outputSchema`), which lets servers return typed JSON that downstream tools can consume without re-parsing; 2026-07-28 loosened tool schemas to allow any JSON Schema 2020-12 keyword. Tools can also carry behavior hints (`readOnlyHint`, `destructiveHint`, …) and, with the **MCP Apps** extension, point at an interactive UI resource the host renders in a sandboxed iframe.

### Resources — application-controlled data

A **resource** is a piece of data the server can expose by URI. Examples: a file, a database row, a wiki page, a Figma node, the contents of an environment variable. Resources are *application-controlled*: the host (or user) decides which ones to attach to context, not the model directly.

```json
{
  "uri": "file:///repo/README.md",
  "name": "README",
  "mimeType": "text/markdown"
}
```

Hosts typically surface resources as `@mentions`, attachment pickers, or auto-context (e.g. attach the resource the user is currently viewing). Clients can **subscribe** to resource updates (on 2026-07-28, via the `resourceSubscriptions` option of `subscriptions/listen`), and list/read results carry `ttlMs` / `cacheScope` cache hints.

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

In Claude Code, server prompts are listed as `/<server>:<prompt> (MCP)` slash commands (typing `/mcp__<server>__<prompt>` also works). In Cursor and Cline they appear in the command palette. Prompts are how a server vendor ships expert workflows alongside the raw tool surface.

### Control-model summary

| Primitive | Who decides to invoke it | Typical UX |
|---|---|---|
| Tool | Model | Function calling |
| Resource | Application / user | `@mention`, attachment, auto-context |
| Prompt | User | Slash command, palette entry |

This separation matters for safety and UX. You don't want the model auto-reading every resource in your filesystem, and you don't want the user manually approving every benign `read_file`. Different control models for different threat profiles.

---

## Lifecycle of an MCP session

The 2026-07-28 revision changed this section more than any other: MCP went from a stateful, handshake-based protocol to a **stateless request/response** protocol. Both shapes still exist in the wild, so it helps to know each.

### 2026-07-28: stateless, self-describing requests

There is no handshake and no session. Every request names its protocol version and the client's capabilities in `_meta` (and, on Streamable HTTP, the `MCP-Protocol-Version`, `Mcp-Method`, and `Mcp-Name` headers). The server accepts or rejects each request independently; if it doesn't speak the requested version it returns `UnsupportedProtocolVersionError` listing the versions it does support.

```
Host                                          Server
 │   server/discover   (optional)              │
 ├────────────────────────────────────────────>│
 │   supportedVersions, capabilities, identity │
 │<────────────────────────────────────────────┤
 │                                             │
 │   tools/call  _meta: {protocolVersion,      │
 │                       clientCapabilities}   │
 ├────────────────────────────────────────────>│
 │   result  (resultType: "complete")          │
 │<────────────────────────────────────────────┤
```

1. **Discovery (optional)**. Servers MUST implement `server/discover`, which returns supported versions, capabilities (including any `extensions`), and server identity. Clients MAY call it up front, or just send requests and handle a version error.
2. **Listing**. `tools/list`, `resources/list` (+ `resources/templates/list`), and `prompts/list` — paginated via opaque `cursor` tokens, and cacheable via `ttlMs` / `cacheScope`. Lists no longer vary per connection.
3. **Operation**. `tools/call`, `resources/read`, `prompts/get`. A server that needs something mid-call (a user confirmation, a missing parameter) returns `resultType: "input_required"` with `inputRequests`; the client gathers the answers and retries the call with `inputResponses` — the **Multi Round-Trip Requests** pattern that replaced server-initiated requests.
4. **Notifications**. Progress (`notifications/progress`) flows on the response stream of the request it relates to. Change notifications (`tools/list_changed`, `resources/updated`, …) flow only on a `subscriptions/listen` stream the client opened and opted into.

State that must span calls is carried explicitly — a server mints a handle (a cart ID, a job ID) and the model passes it back as an ordinary tool argument.

### 2025-11-25 and earlier: initialize handshake + session

Older servers (and clients) use a four-phase session:

1. **Initialization** — the client sends `initialize` (protocol version, client capabilities, client info), the server replies with its version, capabilities, and info, and the client confirms with `notifications/initialized`. On Streamable HTTP the server issues an `Mcp-Session-Id`.
2. **Discovery** — `tools/list`, `resources/list`, `prompts/list`.
3. **Operation** — calls, plus server-initiated requests (`sampling/createMessage`, `elicitation/create`, `roots/list`) and notifications on an open stream.
4. **Shutdown** — for stdio, the host closes stdin, waits, then terminates; for HTTP, the session ends or times out.

Interop is built in: a 2026-07-28 client falls back to `initialize` when it reaches an older server, and the v2 SDKs serve both eras from one endpoint. Either way, capability negotiation is what lets the protocol evolve without breaking old clients — neither side uses a feature the other didn't declare.

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
- **Governance & trust** (policy engines, audit ledgers, identity providers): the host enforces policy *around* MCP calls; MCP itself does not define an authorization model beyond the OAuth 2.1-based flow for HTTP transports (Resource Indicators since 2025-06-18; issuer validation, issuer-bound credentials, and Client ID Metadata Documents preferred over Dynamic Client Registration as of 2026-07-28), plus optional auth extensions such as Enterprise-Managed Authorization.

---

## What MCP is not

A few common misconceptions worth flattening up front.

- **MCP is not an agent framework.** It does not implement planning, loops, reflection, or memory. It is a tool/data integration protocol.
- **MCP is not a sandbox.** A tool call runs whatever code the server runs. Sandboxing is the host's and the server author's responsibility.
- **MCP is not an authentication system.** The transport layer carries auth (OAuth 2.1 for HTTP, environment for stdio). MCP doesn't define users, roles, or scopes beyond capability negotiation.
- **MCP is not bound to Anthropic.** Since December 2025 it is a project of the Agentic AI Foundation under the Linux Foundation (co-founded by Anthropic, Block, and OpenAI). Technical direction stays with the MCP maintainers via the public SEP process. Production deployments run on OpenAI, Google, Mistral, Llama, and local models alike.
- **MCP is not "tools over HTTP."** That phrasing misses resources, prompts, notifications, elicitation, extensions, and the negotiation model. The protocol's value is the full surface, not just function dispatch.

---

## Adoption snapshot (late 2026)

A non-exhaustive list of where MCP shows up:

**First-class hosts**: Claude Desktop, Claude Code, Cursor, Cline, Continue, Windsurf (formerly Codeium), Zed, JetBrains AI Assistant, Replit, Aider.

**Framework clients**: OpenAI Agents SDK, LangChain / LangGraph (`langchain-mcp-adapters`), CrewAI (`crewai-tools[mcp]`), AutoGen (`autogen-ext[mcp]`), LlamaIndex (`llama-index-tools-mcp`), Pydantic AI, AWS Bedrock AgentCore, Microsoft Semantic Kernel, Microsoft Agent Framework.

**Hosted MCP servers** (you connect via Streamable HTTP, no install): GitHub, GitLab, Sentry, Stripe, Linear, Notion, Atlassian (Jira + Confluence), Cloudflare, Vercel, Neon, Supabase, PlanetScale, Figma, Canva, Plaid, Slack, Google Cloud (managed servers for BigQuery, Cloud SQL, GKE, and more). See [`catalog.md`](./catalog.md) for verified endpoints.

**Scale**: at the 2026-07-28 release the maintainers reported close to half a billion monthly downloads across the Tier 1 SDKs, with the TypeScript and Python SDKs each past 1 billion total downloads.

**Spec governance**: MCP was donated to the [Agentic AI Foundation](https://blog.modelcontextprotocol.io/posts/2025-12-09-mcp-joins-agentic-ai-foundation/) (AAIF, a Linux Foundation directed fund) on 2025-12-09, alongside goose (Block) and AGENTS.md (OpenAI). The AAIF Governing Board handles budget, membership, and new projects; MCP keeps full technical autonomy. The protocol is run by Lead and Core Maintainers with Working Groups, a contributor ladder, and a public SEP (Specification Enhancement Proposal) process, under the `modelcontextprotocol` GitHub org. Revisions so far: 2024-11-05 → 2025-03-26 → 2025-06-18 → 2025-11-25 → **2026-07-28**. A feature lifecycle policy (adopted with 2026-07-28) keeps deprecated features for at least twelve months before removal (ninety days under a narrow expedited-removal exception).

**SDKs**: Tier 1 (100% conformance) — TypeScript, Python, Go, C#. Other official SDKs: Rust, Java, Kotlin, Swift, Ruby (1.0 in July 2026), PHP. See the [SDK tiers page](https://modelcontextprotocol.io/community/sdk-tiers).

**Discovery**: the official [MCP Registry](https://registry.modelcontextprotocol.io) (preview since September 2025; v0.1 API frozen since October 2025) indexes `server.json` metadata that points at npm / PyPI / NuGet / OCI packages or remote URLs. See [`building.md`](./building.md#the-official-mcp-registry).

---

## Further reading

- **Spec**: <https://modelcontextprotocol.io/specification/latest> · [2026-07-28 changelog](https://modelcontextprotocol.io/specification/2026-07-28/changelog)
- **Blog** (release notes, roadmap): <https://blog.modelcontextprotocol.io/>
- **Security best practices**: <https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices>
- **Extensions** (MCP Apps, Tasks, auth): <https://modelcontextprotocol.io/docs/extensions/overview>
- **Registry**: <https://registry.modelcontextprotocol.io>
- **Reference implementation servers**: <https://github.com/modelcontextprotocol/servers>
- **TypeScript SDK**: <https://github.com/modelcontextprotocol/typescript-sdk> · docs <https://ts.sdk.modelcontextprotocol.io/v2/>
- **Python SDK**: <https://github.com/modelcontextprotocol/python-sdk> · docs <https://py.sdk.modelcontextprotocol.io/>
- **Inspector** (debug tool): <https://github.com/modelcontextprotocol/inspector>
- **Awesome MCP**: <https://github.com/punkpeye/awesome-mcp-servers>
- **Catalog (this guide)**: [`catalog.md`](./catalog.md)

Next, see:

- [`installation.md`](./installation.md) — installing servers across hosts.
- [`configuration.md`](./configuration.md) — config file shapes and patterns.
- [`building.md`](./building.md) — building your own server in TypeScript or Python.
- [`advanced.md`](./advanced.md) — the stateless core, elicitation, extensions, security, federation.
