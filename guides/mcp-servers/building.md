# Building an MCP Server

End-to-end walkthrough for building your own MCP server in TypeScript and Python. Starts from a one-tool "hello world," then adds resources, prompts, error handling, logging, tests, and publishing. Covers both stdio and Streamable HTTP transports.

> **Last updated**: 2026-10-21 · Tracks MCP spec **2026-07-28** · TypeScript SDK **v2** (`@modelcontextprotocol/server` / `@modelcontextprotocol/client`) · Python SDK **v2** (`mcp`, with `MCPServer` replacing `FastMCP`).
>
> **On v1?** Both SDKs shipped breaking v2 releases alongside the 2026-07-28 spec. The TypeScript v1 line (`@modelcontextprotocol/sdk`) lives on the `v1.x` branch and gets bug fixes and security updates for at least six months after the v2 release; the Python v1.x branch continues to receive critical fixes and security patches. Moving to v2 and adopting the 2026-07-28 protocol are separate steps. Migration guides: [TypeScript](https://ts.sdk.modelcontextprotocol.io/v2/migration/upgrade-to-v2) (there is a codemod: `npx @modelcontextprotocol/codemod v1-to-v2 .`) and [Python](https://py.sdk.modelcontextprotocol.io/migration/).

---

## Table of Contents

- [Choose your stack](#choose-your-stack)
- [TypeScript walkthrough](#typescript-walkthrough)
  - [Project scaffold (TS)](#project-scaffold-ts)
  - [Hello world server](#hello-world-server)
  - [Adding tools with Zod schemas](#adding-tools-with-zod-schemas)
  - [Adding resources](#adding-resources)
  - [Adding prompts](#adding-prompts)
  - [Switching to Streamable HTTP](#switching-to-streamable-http)
- [Python walkthrough](#python-walkthrough)
  - [Project scaffold (Python)](#project-scaffold-python)
  - [Hello world with MCPServer](#hello-world-with-mcpserver)
  - [Tools, resources, prompts](#tools-resources-prompts)
  - [Streamable HTTP in Python](#streamable-http-in-python)
- [Schema design](#schema-design)
- [Error handling](#error-handling)
- [Logging](#logging)
- [Testing with the Inspector](#testing-with-the-inspector)
- [Automated tests](#automated-tests)
- [Versioning](#versioning)
- [Publishing](#publishing)
- [Operational checklist before you ship](#operational-checklist-before-you-ship)

---

## Choose your stack

TypeScript, Python, Go, and C# are the **Tier 1** official SDKs (100% conformance-test pass rate required; all four speak 2026-07-28). Rust, Java, Kotlin, Swift, Ruby, and PHP SDKs also live under [`github.com/modelcontextprotocol`](https://github.com/modelcontextprotocol) — check each repo and the [SDK tiers page](https://modelcontextprotocol.io/community/sdk-tiers) for its current tier and spec support. This guide covers TypeScript and Python. Choose by where the surrounding code lives:

| Choose TypeScript when | Choose Python when |
|---|---|
| The system you're wrapping has a strong Node/TS client. | The system you're wrapping is Python-native (data tooling, ML, scientific). |
| You want first-class browser tooling integration (Inspector, hosted MCP gateways). | You want first-class async, type hints, and pydantic schemas. |
| Your users will mostly run via `npx`. | Your users will mostly run via `uvx` / `pipx`. |
| You need to ship a hosted Streamable HTTP server on Node, Bun, Deno, Cloudflare Workers, or another web-standard runtime. | You need to ship a hosted Streamable HTTP server on Starlette / FastAPI / any ASGI host. |

The protocol surface is identical; the local idioms differ.

---

## TypeScript walkthrough

TypeScript SDK v2 is ESM-only, runs on Node.js 20+, Bun, and Deno, and accepts any [Standard Schema](https://standardschema.dev/) library for tool schemas (Zod v4, Valibot, ArkType, …). The examples below use Zod v4.

### Project scaffold (TS)

```bash
mkdir my-mcp-server && cd my-mcp-server
npm init -y
npm install @modelcontextprotocol/server zod
npm install --save-dev typescript @types/node tsx
npx tsc --init --target es2022 --module nodenext --moduleResolution nodenext \
  --outDir dist --rootDir src --strict
mkdir src
```

Update `package.json`:

```json
{
  "name": "@yourorg/my-mcp-server",
  "version": "0.1.0",
  "description": "An example MCP server.",
  "type": "module",
  "bin": {
    "my-mcp-server": "dist/index.js"
  },
  "files": ["dist", "README.md"],
  "scripts": {
    "build": "tsc",
    "dev": "tsx src/index.ts",
    "start": "node dist/index.js",
    "inspect": "npx @modelcontextprotocol/inspector tsx src/index.ts"
  }
}
```

### Hello world server

`src/index.ts`:

```ts
#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/server";
import { StdioServerTransport } from "@modelcontextprotocol/server/stdio";
import * as z from "zod/v4";

const server = new McpServer({
  name: "my-mcp-server",
  version: "0.1.0",
});

server.registerTool(
  "echo",
  {
    title: "Echo",
    description: "Returns the input string unchanged.",
    inputSchema: z.object({ message: z.string().describe("Text to echo back") }),
  },
  async ({ message }) => ({
    content: [{ type: "text", text: message }],
  }),
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  // Server runs until stdin closes.
}

main().catch((err) => {
  console.error("[my-mcp-server] fatal:", err);
  process.exit(1);
});
```

Build and verify:

```bash
npm run build
chmod +x dist/index.js
npm run inspect
```

The Inspector should open at `http://localhost:6274`, show one tool (`echo`), and let you call it.

### Adding tools with Zod schemas

The SDK derives both runtime validation and the JSON Schema sent over the wire from your schema object. A more realistic tool with multiple typed inputs, plus a declared output shape:

```ts
const CreateNoteInput = z.object({
  title: z.string().min(1).max(200).describe("Note title"),
  body: z.string().describe("Markdown body of the note"),
  tags: z.array(z.string()).default([]).describe("Optional tags"),
  pinned: z.boolean().default(false).describe("Whether to pin the note"),
});

server.registerTool(
  "create_note",
  {
    title: "Create Note",
    description: "Create a new note in the user's notebook.",
    inputSchema: CreateNoteInput,
    outputSchema: z.object({
      id: z.string(),
      title: z.string(),
      tags: z.array(z.string()),
      pinned: z.boolean(),
    }),
  },
  async ({ title, body, tags, pinned }) => {
    const id = await notesService.create({ title, body, tags, pinned });
    return {
      content: [{ type: "text", text: `Created note ${id}: ${title}` }],
      structuredContent: { id, title, tags, pinned },
    };
  },
);
```

`structuredContent` + `outputSchema` (introduced in spec 2025-06-18) let you return typed JSON alongside the human-readable text, so downstream steps can consume it without re-parsing prose. As of 2026-07-28, `inputSchema`/`outputSchema` may use any JSON Schema 2020-12 keyword and `structuredContent` may be any JSON value (SEP-2106).

### Adding resources

Resources expose data the client can attach to context. Two flavors: static (one fixed URI) and template (a parameterized URI pattern).

```ts
import { ResourceTemplate } from "@modelcontextprotocol/server";

// Static resource
server.registerResource(
  "config",
  "config://app",
  {
    title: "App Config",
    description: "Current application configuration",
    mimeType: "application/json",
  },
  async (uri) => ({
    contents: [
      { uri: uri.href, text: JSON.stringify(await configService.snapshot(), null, 2) },
    ],
  }),
);

// Templated resource: notes://<id>. `list` is required — pass undefined if unbounded.
server.registerResource(
  "note",
  new ResourceTemplate("notes://{noteId}", {
    list: async () => ({
      resources: (await notesService.list()).map((n) => ({
        uri: `notes://${n.id}`,
        name: n.title,
        mimeType: "text/markdown",
      })),
    }),
  }),
  { title: "Note", description: "Read a single note by id." },
  async (uri, { noteId }) => {
    const note = await notesService.get(noteId);
    return {
      contents: [
        { uri: uri.href, mimeType: "text/markdown", text: `# ${note.title}\n\n${note.body}` },
      ],
    };
  },
);
```

**Change notifications.** On a 2026-07-28 connection, `notifications/resources/updated` and the `*/list_changed` notifications reach a client only over a `subscriptions/listen` stream the client opened (this replaced `resources/subscribe` and the HTTP GET stream). Behind `createMcpHandler` (below), publish through the handler: `handler.notify.resourceUpdated("notes://42")`, or `handler.notify.toolsChanged()` / `promptsChanged()` / `resourcesChanged()`. The server your factory builds must advertise `resources: { subscribe: true }` for per-resource updates.

### Adding prompts

Prompts are templates the user invokes. They return a sequence of messages the host injects into the conversation.

```ts
server.registerPrompt(
  "summarize_note",
  {
    title: "Summarize Note",
    description: "Summarize a note in 3 bullet points.",
    argsSchema: z.object({ noteId: z.string().describe("Note id to summarize") }),
  },
  async ({ noteId }) => {
    const note = await notesService.get(noteId);
    return {
      messages: [
        {
          role: "user" as const,
          content: {
            type: "text" as const,
            text: `Summarize the following note in exactly 3 bullet points.\n\n# ${note.title}\n\n${note.body}`,
          },
        },
      ],
    };
  },
);
```

In Claude Code, server prompts are listed as `/my-mcp-server:summarize_note (MCP)` in the `/` menu (typing `/mcp__my-mcp-server__summarize_note <noteId>` also runs it). Other hosts typically put them in a command palette.

### Switching to Streamable HTTP

Once you want the server reachable over the network (multi-tenant, hosted, shared by a team), serve it over Streamable HTTP. In v2, `createMcpHandler` takes a **factory** that returns a fresh `McpServer`; the factory runs once per HTTP request and the handler holds nothing between requests, so any instance behind a plain round-robin load balancer can serve any request. The same endpoint answers both 2026-07-28 and 2025-11-25 clients.

```bash
npm install @modelcontextprotocol/express @modelcontextprotocol/node express
```

```ts
import { createMcpExpressApp, requireBearerAuth } from "@modelcontextprotocol/express";
import { toNodeHandler } from "@modelcontextprotocol/node";
import { createMcpHandler, McpServer } from "@modelcontextprotocol/server";

const handler = createMcpHandler(({ authInfo }) => {
  const server = new McpServer({ name: "my-mcp-server", version: "0.1.0" });
  registerTools(server, authInfo); // register tools/resources/prompts inside the factory
  return server;
});

// express() + express.json() + Host/Origin validation (DNS-rebinding protection)
const app = createMcpExpressApp({ host: "0.0.0.0", allowedHosts: ["mcp.example.com"] });
const node = toNodeHandler(handler);
const auth = requireBearerAuth({ verifier }); // your token verification

app.all("/mcp", auth, (req, res) => void node(req, res, req.body));
app.listen(3000);
```

Adapters also exist for Fastify (`@modelcontextprotocol/fastify`) and Hono (`@modelcontextprotocol/hono`); `handler.fetch` is a web-standard `(Request) => Promise<Response>` for runtimes like Workers, Deno, and Bun.

For production:

- Front with TLS (a reverse proxy or platform termination).
- Authenticate per the spec's OAuth 2.1 authorization model (protected resource metadata, audience-bound tokens); short-lived JWT bearer tokens are fine for internal deployments. See [`advanced.md`](./advanced.md#security-model).
- Add CORS only if browser clients will connect directly.
- Keep `Host`/`Origin` validation on (the Express helper does it by default on loopback; name your hosts when binding `0.0.0.0`).
- Gateways and rate limiters can route on the `Mcp-Method` / `Mcp-Name` headers that 2026-07-28 clients must send — no body parsing needed.

---

## Python walkthrough

Python SDK v2 requires Python 3.11+. The high-level class formerly called `FastMCP` is now `MCPServer`; the decorator API carries over. (The separate, third-party `fastmcp` package — now FastMCP 4.x, maintained by Prefect — is a different project; don't mix its APIs with the official SDK's.)

### Project scaffold (Python)

```bash
mkdir my-mcp-server-py && cd my-mcp-server-py
uv init --package
uv add "mcp[cli]>=2" pydantic
```

`pyproject.toml`:

```toml
[project]
name = "my-mcp-server-py"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
  "mcp[cli]>=2,<3",
  "pydantic>=2.0",
]

[project.scripts]
my-mcp-server-py = "my_mcp_server_py:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

Publishing a *library* that depends on `mcp`? Add an upper bound (e.g. `mcp>=2,<3`) so a future major doesn't surprise your users — the SDK maintainers recommended exactly this ahead of v2.

### Hello world with MCPServer

`src/my_mcp_server_py/__init__.py`:

```python
from mcp.server.mcpserver import MCPServer

mcp = MCPServer("my-mcp-server-py", version="0.1.0")

@mcp.tool()
def echo(message: str) -> str:
    """Return the input string unchanged."""
    return message

def main() -> None:
    mcp.run()  # defaults to stdio transport
```

Pass `name` positionally and everything else (`version`, `instructions`, …) by keyword — v2 inserted `title` and `description` into the positional order.

Run:

```bash
uv run my-mcp-server-py            # boots on stdio
uv run mcp dev src/my_mcp_server_py/__init__.py  # launches the Inspector
```

### Tools, resources, prompts

`MCPServer` infers JSON Schema from your type hints (Pydantic under the hood), so most servers stay this concise:

```python
import asyncio
from typing import Annotated
from pydantic import BaseModel, Field
from mcp.server.mcpserver import MCPServer, Context

mcp = MCPServer("notes", version="0.1.0")

class Note(BaseModel):
    id: str
    title: str
    body: str
    tags: list[str] = []
    pinned: bool = False

@mcp.tool()
def create_note(
    title: Annotated[str, Field(min_length=1, max_length=200)],
    body: str,
    tags: list[str] = [],
    pinned: bool = False,
) -> Note:
    """Create a new note in the user's notebook."""
    return notes_service.create(title=title, body=body, tags=tags, pinned=pinned)

@mcp.resource("config://app")
def app_config() -> str:
    """Current application configuration as JSON."""
    return config_service.snapshot_json()

@mcp.resource("notes://{note_id}")
def get_note(note_id: str) -> str:
    note = notes_service.get(note_id)
    return f"# {note.title}\n\n{note.body}"

@mcp.prompt()
def summarize_note(note_id: str) -> str:
    """Summarize a note in 3 bullets."""
    note = notes_service.get(note_id)
    return (
        f"Summarize the following note in exactly 3 bullet points.\n\n"
        f"# {note.title}\n\n{note.body}"
    )

@mcp.tool()
async def long_running_task(steps: int, ctx: Context) -> str:
    """Demonstrates progress notifications."""
    for i in range(steps):
        await ctx.report_progress(i + 1, steps, f"step {i + 1}/{steps}")
        await asyncio.sleep(0.1)
    return "done"
```

The `Context` parameter is injected by `MCPServer`. Note two v2 behavior changes: sync (`def`) handlers now run on a worker thread, and the server-initiated helpers (`ctx.elicit()`, `ctx.session.create_message()`) raise `NoBackChannelError` on 2026-07-28 connections — see [`advanced.md`](./advanced.md#elicitation-and-multi-round-trip-requests) for the era-portable pattern.

### Streamable HTTP in Python

Transport options moved from the constructor to `run()` / `streamable_http_app()` in v2:

```python
from mcp.server.mcpserver import MCPServer

mcp = MCPServer("notes", version="0.1.0")
# ... register tools/resources/prompts ...

if __name__ == "__main__":
    mcp.run(transport="streamable-http", host="127.0.0.1", port=8000)  # serves /mcp
```

A v2 HTTP server answers both 2026-07-28 and legacy (`initialize`-based) clients from one endpoint. To mount inside an existing ASGI app, the host app's lifespan must run the session manager:

```python
import contextlib
from starlette.applications import Starlette
from starlette.routing import Mount
from mcp.server.mcpserver import MCPServer

mcp = MCPServer("notes", version="0.1.0")
# ... register ...
mcp_app = mcp.streamable_http_app()  # build at module level

@contextlib.asynccontextmanager
async def lifespan(app: Starlette):
    async with mcp.session_manager.run():
        yield

app = Starlette(routes=[Mount("/", app=mcp_app)], lifespan=lifespan)
```

DNS-rebinding protection auto-enables for loopback hosts; to serve a real hostname pass `transport_security=TransportSecuritySettings(allowed_hosts=[...], allowed_origins=[...])` (from `mcp.server.transport_security`). Streamable HTTP request bodies are capped at 4 MiB by default (`max_request_body_size`).

---

## Schema design

Tool descriptions and input schemas are *prompt engineering*. The model reads them and decides whether and how to invoke. A few rules earned in production:

1. **Tool name is a verb-phrase**. `create_issue`, not `issues`. `query_db`, not `db`.
2. **One-sentence description, model-readable**. Lead with what it does, end with when to use it. Skip implementation details.
3. **Every parameter has a `.describe()` / `Field(description=…)`**. Without descriptions the model has only the name to go on.
4. **Use enums for closed sets**. `priority: z.enum(["low", "medium", "high"])` beats `priority: z.string()`. The model picks valid values far more reliably.
5. **Keep schemas shallow**. Models handle flat objects best. If you have deeply nested config, accept it as a JSON string and parse server-side.
6. **Make destructive ops ask first**. Either require an explicit `confirm: true` argument or ask the user mid-call with an elicitation (`input_required` in 2026-07-28 — see [`advanced.md`](./advanced.md#elicitation-and-multi-round-trip-requests)).
7. **Return structured output where it composes**. `structuredContent` (TS) / a typed return value (Python) lets the model chain calls without parsing prose.
8. **Annotate side effects**. Set the spec's tool annotations (`readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint`) so hosts can pick the right confirmation UX — they are hints, not a security boundary.
9. **Return tools in a stable order**. 2026-07-28 says servers SHOULD list tools deterministically so clients can cache and keep LLM prompt caches warm.

---

## Error handling

Tools can fail. The protocol distinguishes two failure modes:

### Tool execution error (model-visible)

The tool was called but the underlying operation failed. Return content with `isError: true`. The model sees the error and can recover (retry, ask the user, try a different approach).

TS:

```ts
server.registerTool("fetch_url", { /* ... */ }, async ({ url }) => {
  try {
    const res = await fetch(url);
    if (!res.ok) {
      return {
        isError: true,
        content: [{ type: "text", text: `HTTP ${res.status}: ${res.statusText}` }],
      };
    }
    return { content: [{ type: "text", text: await res.text() }] };
  } catch (err) {
    return {
      isError: true,
      content: [{ type: "text", text: `Network error: ${(err as Error).message}` }],
    };
  }
});
```

Python:

```python
from mcp.server.mcpserver.exceptions import ToolError

@mcp.tool()
async def fetch_url(url: str) -> str:
    try:
        res = await http_client.get(url)
        res.raise_for_status()
        return res.text
    except HTTPStatusError as e:
        raise ToolError(f"HTTP {e.response.status_code}: {e.response.reason_phrase}")
```

### Protocol error (host-visible)

The request was malformed or should be rejected outright. These become JSON-RPC errors — the host shows a system-level failure rather than feeding it to the model. In Python v2, raising `MCPError` (renamed from `McpError`) inside a tool now produces a JSON-RPC error with its `code`/`message`/`data` intact, where v1 turned it into `isError: true`. Use `ToolError` for failures the model should see.

Rule of thumb: **reject the request → protocol error; the operation failed → tool error**. (Note 2026-07-28 changed "resource not found" from `-32002` to the standard `-32602`; update clients that match on the literal.)

### Don't leak

- Stack traces with full file paths.
- Internal IDs that name your DB schema.
- Auth tokens, even partially redacted ones (the model may repeat them).
- Verbose SQL containing user data.

Return a short, model-actionable message; log the full detail to stderr.

---

## Logging

Strict rules for stdio servers:

- **All logs go to stderr.** stdout is the protocol channel; one stray `console.log` corrupts the JSON-RPC stream and the host disconnects.
- **Structured > unstructured.** JSON lines on stderr are easy to ingest into Loki, Datadog, Cloud Logging.
- **Prefer OpenTelemetry for hosted servers.** 2026-07-28 documents trace-context propagation through `_meta` (`traceparent`, `tracestate`, `baggage`), and the Python v2 SDK turns OpenTelemetry on by default.

TS:

```ts
// Always use console.error, never console.log
const log = (level: string, msg: string, extra?: object) =>
  console.error(JSON.stringify({ ts: new Date().toISOString(), level, msg, ...extra }));
```

Python's `logging` module writes to stderr by default — just configure it:

```python
import logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
```

**MCP protocol logging (`notifications/message`) is deprecated** as of 2026-07-28 (SEP-2577), together with Roots and Sampling. It keeps working for at least twelve months, but new servers shouldn't adopt it. On 2026-07-28 connections log delivery is also per-request opt-in: a server MUST NOT send `notifications/message` for a request that didn't carry `io.modelcontextprotocol/logLevel` in `_meta`, so in-SDK helpers like `ctx.mcpReq.log(...)` (TS) and `ctx.info(...)` (Python) are silently dropped unless the client asked. Use progress notifications (`ctx.mcpReq.notify(...)` in TS, `ctx.report_progress(...)` in Python) for user-visible status like "rate-limited by upstream, retrying in 5s".

---

## Testing with the Inspector

The Inspector (v2 — a rewrite; requires Node ≥ 22.19.0, single web server on port 6274, plus `--cli` and `--tui` modes) is the dev loop. From your server's repo:

```bash
# TS
npx @modelcontextprotocol/inspector tsx src/index.ts

# Python
uv run mcp dev src/my_mcp_server_py/__init__.py
```

For Streamable HTTP servers, start the server then use the CLI mode:

```bash
npx @modelcontextprotocol/inspector --cli http://localhost:3000/mcp --transport http --method tools/list
```

In v2 a failing CLI tool call exits non-zero, so it works in CI. Verification flow for every change:

1. Connect — confirm protocol version and advertised capabilities.
2. `tools/list` — confirm count, names, descriptions, and schemas.
3. Invoke each new/changed tool with valid inputs — confirm the response shape.
4. Invoke with invalid inputs — confirm a clean error rather than a crash.
5. Inspect notifications and logs for unexpected warnings.

---

## Automated tests

Run the server in-process to keep tests fast. In TypeScript v2, point a real `Client` at the handler's `fetch` — no socket, and it exercises the same `createMcpHandler` you deploy:

```ts
import assert from "node:assert/strict";
import { Client, StreamableHTTPClientTransport } from "@modelcontextprotocol/client";
import { createMcpHandler } from "@modelcontextprotocol/server";
import { buildServer } from "../src/server.js";

const handler = createMcpHandler(buildServer);
const transport = new StreamableHTTPClientTransport(new URL("http://test.local/mcp"), {
  fetch: (url, init) => handler.fetch(new Request(url, init)),
});
const client = new Client({ name: "test", version: "0.0.0" }, { versionNegotiation: { mode: "auto" } });
await client.connect(transport);

const result = await client.callTool({
  name: "create_note",
  arguments: { title: "Hello", body: "World" },
});
assert.ok(!result.isError);
assert.equal(result.structuredContent?.title, "Hello");

await client.close();
await handler.close();
```

(`InMemoryTransport.createLinkedPair()` still exists but only pairs 2025-era instances.) In Python v2, pass the server object straight to `Client` — it connects in memory:

```python
import pytest
from mcp import Client
from my_mcp_server_py import mcp

@pytest.fixture
def anyio_backend():
    return "asyncio"

@pytest.mark.anyio
async def test_create_note():
    async with Client(mcp, raise_exceptions=True) as client:
        result = await client.call_tool("create_note", {"title": "Hello", "body": "World"})
        assert not result.is_error
        assert result.structured_content["title"] == "Hello"
```

Python v2 type fields are snake_case (`is_error`, `structured_content`), and `Client(mcp)` negotiates 2026-07-28 by default; pass `mode="legacy"` to test the old `initialize` path. The v1 helper `create_connected_server_and_client_session` was removed.

Keep at least:

- One happy-path test per tool.
- One invalid-input test per tool.
- One regression test for every bug filed.

Run them in CI on every PR. The official [conformance test suite](https://github.com/modelcontextprotocol/conformance) is worth a look if you implement transports or protocol handling yourself.

---

## Versioning

Use SemVer with these specific rules:

- **Patch** (`1.2.x`) — bug fixes, performance, internal refactors. No tool schema change.
- **Minor** (`1.x.0`) — new tools, new optional parameters, new resources, new prompts.
- **Major** (`x.0.0`) — renamed/removed tools, renamed/removed required parameters, changed return shapes, transport changes.

Why this matters: agent workflows that "memorize" tool names break on major bumps. Make them rare, document them loudly in the changelog, and provide a deprecation period (one minor release with both old + new tools, then the major bump that removes the old).

Pin the spec revision your server targets in your README, e.g.:

> Implements MCP spec revision 2026-07-28. Also answers clients on 2025-11-25 and earlier via the legacy `initialize` handshake.

---

## Publishing

### npm

```bash
# 1. Confirm package.json: name (scoped or not), version, bin entry, files array.
# 2. Build.
npm run build
# 3. Smoke-test the published shape.
npm pack && tar -tf *.tgz   # confirm only dist/ + README ship
# 4. Login + publish.
npm login
npm publish --access public  # for scoped packages
```

Users install with `npx -y @yourorg/my-mcp-server`.

### PyPI

```bash
uv build
uv publish --token "$PYPI_TOKEN"
```

Users install with `uvx my-mcp-server-py` or `pipx run my-mcp-server-py`.

### Docker

For servers with heavy native deps:

```dockerfile
FROM node:22-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY dist ./dist
USER node
ENTRYPOINT ["node", "/app/dist/index.js"]
```

Publish to a public registry (Docker Hub, GHCR, Quay) and document the `docker run` invocation.

### MCP Bundles (`.mcpb`)

For one-click install of a *local* server in desktop clients, package it as an [MCP Bundle](https://github.com/modelcontextprotocol/mcpb) — a ZIP with your server plus a `manifest.json` (Node, Python, or a compiled binary). The format (formerly DXT) moved into the MCP project in November 2025.

### The official MCP Registry

The [MCP Registry](https://registry.modelcontextprotocol.io) (source: [`modelcontextprotocol/registry`](https://github.com/modelcontextprotocol/registry)) is a metadata index: it stores a `server.json` pointing at your npm/PyPI/NuGet/OCI package or remote URL, not the code itself. It is still a **preview** — the v0.1 API has been frozen since October 2025 ahead of a GA "v1", but breaking changes or data resets remain possible.

1. Add an ownership marker: `"mcpName": "io.github.<you>/<server>"` in `package.json` (npm), or an `mcp-name: io.github.<you>/<server>` line in the README (PyPI, NuGet).
2. Install the publisher: `brew install mcp-publisher` (or a release binary).
3. `mcp-publisher init` to generate `server.json`, then edit it:

```json
{
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json",
  "name": "io.github.your-username/my-mcp-server",
  "description": "An example MCP server.",
  "repository": { "url": "https://github.com/your-username/my-mcp-server", "source": "github" },
  "version": "0.1.0",
  "packages": [
    {
      "registryType": "npm",
      "identifier": "@yourorg/my-mcp-server",
      "version": "0.1.0",
      "transport": { "type": "stdio" }
    }
  ]
}
```

   Remote-only servers replace `packages` with `"remotes": [{ "type": "streamable-http", "url": "https://…/mcp" }]`.
4. `mcp-publisher login github`, then `mcp-publisher publish`.

The `io.github.<user>/` namespace comes from GitHub auth; domain-based auth (a DNS TXT record on your apex domain, or HTTP) unlocks reverse-DNS names such as `com.example/…`. Community directories such as the [Awesome MCP list](https://github.com/punkpeye/awesome-mcp-servers) are still worth a PR — this is mostly how users discover servers.

---

## Operational checklist before you ship

Treat this as a literal pre-flight. Most production incidents in MCP servers trace back to one of these.

- [ ] Every tool has a description, a name that begins with a verb, and `.describe()` on every parameter.
- [ ] Destructive tools require explicit confirmation (argument or elicitation) and carry `destructiveHint`.
- [ ] Errors return `isError: true` with a short, model-actionable message — no stack traces, no secrets.
- [ ] All logs go to stderr (stdio) or OpenTelemetry. Zero accidental stdout writes. No new dependence on deprecated MCP logging.
- [ ] Server survives concurrent `tools/call` requests (parallel tool calls are the host default).
- [ ] HTTP server keeps no per-connection state in memory — any cross-call state lives behind an explicit, unguessable, user-bound handle.
- [ ] Long-running tools emit progress notifications (or use the Tasks extension).
- [ ] Tool schemas validated with the Inspector against valid and invalid inputs.
- [ ] In-process tests cover every tool, including failure cases, on both 2026-07-28 and legacy negotiation if you support both.
- [ ] Version pinned in README; spec revision documented.
- [ ] OAuth / auth model documented for HTTP transport.
- [ ] Rate-limit / quota behavior documented.
- [ ] Telemetry (basic counters at minimum: calls per tool, errors per tool, latency percentiles) — see [`advanced.md`](./advanced.md) for instrumentation patterns including OpenTelemetry and trust/audit platforms like Veriswarm for high-stakes workflows.
- [ ] CHANGELOG covers user-visible changes.
- [ ] README has install command, example config snippet, and the tool list with one-line summaries.

When the list is green, ship it.

---

## Next

- [`advanced.md`](./advanced.md) — multi round-trip requests, tasks, extensions, security, federation.
- [`configuration.md`](./configuration.md) — config reference, allowlists, multi-instance.
- [`catalog.md`](./catalog.md) — the server catalog.
