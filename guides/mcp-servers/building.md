# Building an MCP Server

End-to-end walkthrough for building your own MCP server in TypeScript and Python. Starts from a one-tool "hello world," then adds resources, prompts, error handling, logging, tests, and publishing. Covers both stdio and Streamable HTTP transports.

> **Last updated**: 2026-05-24 · Tracks MCP spec **2025-06-18** · TS SDK `^1.20.0` · Python SDK `^1.13.0`.

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
  - [Hello world with FastMCP](#hello-world-with-fastmcp)
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

Both reference SDKs are first-class and protocol-complete. Choose by where the surrounding code lives:

| Choose TypeScript when | Choose Python when |
|---|---|
| The system you're wrapping has a strong Node/TS client. | The system you're wrapping is Python-native (data tooling, ML, scientific). |
| You want first-class browser tooling integration (Inspector, hosted MCP gateways). | You want first-class async, type hints, and pydantic schemas. |
| Your users will mostly run via `npx`. | Your users will mostly run via `uvx` / `pipx`. |
| You need to ship a hosted Streamable HTTP server on Cloudflare Workers / Vercel / Node. | You need to ship a hosted Streamable HTTP server on FastAPI / Starlette / ASGI. |

The protocol surface is identical; the local idioms differ.

---

## TypeScript walkthrough

### Project scaffold (TS)

```bash
mkdir my-mcp-server && cd my-mcp-server
npm init -y
npm install @modelcontextprotocol/sdk zod
npm install --save-dev typescript @types/node tsx
npx tsc --init --target es2022 --module nodenext --moduleResolution nodenext \
  --outDir dist --rootDir src --strict --esModuleInterop
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
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({
  name: "my-mcp-server",
  version: "0.1.0",
});

server.registerTool(
  "echo",
  {
    title: "Echo",
    description: "Returns the input string unchanged.",
    inputSchema: { message: z.string().describe("Text to echo back") },
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

Add a shebang for direct execution:

```bash
sed -i '' '1i\
#!/usr/bin/env node
' src/index.ts
```

Build and verify:

```bash
npm run build
chmod +x dist/index.js
npm run inspect
```

The Inspector should open at `http://localhost:6274`, show one tool (`echo`), and let you call it.

### Adding tools with Zod schemas

The SDK uses Zod to derive both runtime validation and the JSON Schema sent over the wire. A more realistic tool with multiple typed inputs:

```ts
import { z } from "zod";

const CreateNoteInput = {
  title: z.string().min(1).max(200).describe("Note title"),
  body: z.string().describe("Markdown body of the note"),
  tags: z.array(z.string()).default([]).describe("Optional tags"),
  pinned: z.boolean().default(false).describe("Whether to pin the note"),
};

server.registerTool(
  "create_note",
  {
    title: "Create Note",
    description: "Create a new note in the user's notebook.",
    inputSchema: CreateNoteInput,
  },
  async ({ title, body, tags, pinned }) => {
    const id = await notesService.create({ title, body, tags, pinned });
    return {
      content: [
        { type: "text", text: `Created note ${id}: ${title}` },
      ],
      structuredContent: { id, title, tags, pinned },
    };
  },
);
```

`structuredContent` is the 2025-06-18 spec addition that lets you return typed JSON alongside the human-readable text. Downstream tools can consume it without re-parsing the text. Pair it with an `outputSchema` to declare its shape:

```ts
server.registerTool(
  "create_note",
  {
    title: "Create Note",
    description: "Create a new note in the user's notebook.",
    inputSchema: CreateNoteInput,
    outputSchema: {
      id: z.string(),
      title: z.string(),
      tags: z.array(z.string()),
      pinned: z.boolean(),
    },
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

### Adding resources

Resources expose data the user can attach to context. Two flavors: static (known URI list) and template (parameterized URI patterns).

```ts
import { ResourceTemplate } from "@modelcontextprotocol/sdk/server/mcp.js";

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
      {
        uri: uri.href,
        text: JSON.stringify(await configService.snapshot(), null, 2),
      },
    ],
  }),
);

// Templated resource: notes://<id>
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
  {
    title: "Note",
    description: "Read a single note by id.",
  },
  async (uri, { noteId }) => {
    const note = await notesService.get(noteId);
    return {
      contents: [
        {
          uri: uri.href,
          mimeType: "text/markdown",
          text: `# ${note.title}\n\n${note.body}`,
        },
      ],
    };
  },
);
```

Resources can be **subscribed** so the server pushes updates when the data changes. To opt in, advertise the capability and emit `notifications/resources/updated`:

```ts
const server = new McpServer({
  name: "my-mcp-server",
  version: "0.1.0",
}, {
  capabilities: { resources: { subscribe: true, listChanged: true } },
});

notesService.on("change", (note) => {
  server.sendResourceUpdated({ uri: `notes://${note.id}` });
});
```

### Adding prompts

Prompts are templates the user invokes. They return a sequence of messages the host injects into the conversation.

```ts
server.registerPrompt(
  "summarize_note",
  {
    title: "Summarize Note",
    description: "Summarize a note in 3 bullet points.",
    argsSchema: { noteId: z.string().describe("Note id to summarize") },
  },
  async ({ noteId }) => {
    const note = await notesService.get(noteId);
    return {
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: `Summarize the following note in exactly 3 bullet points.\n\n# ${note.title}\n\n${note.body}`,
          },
        },
      ],
    };
  },
);
```

In Claude Code, this surfaces as `/my-mcp-server:summarize_note <noteId>`. In Cursor and Cline it appears in the command palette.

### Switching to Streamable HTTP

Once you want the server reachable over the network (multi-tenant, hosted, shared by a team), swap the transport. The same `McpServer` instance plugs into either.

```ts
import express from "express";
import { randomUUID } from "node:crypto";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";

const app = express();
app.use(express.json());

const transports = new Map<string, StreamableHTTPServerTransport>();

app.post("/mcp", async (req, res) => {
  const sessionId = req.header("mcp-session-id");
  let transport = sessionId ? transports.get(sessionId) : undefined;

  if (!transport) {
    transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: () => randomUUID(),
      onsessioninitialized: (id) => transports.set(id, transport!),
    });
    transport.onclose = () => {
      if (transport!.sessionId) transports.delete(transport!.sessionId);
    };

    const server = buildServer(); // factory that returns a fresh McpServer
    await server.connect(transport);
  }

  await transport.handleRequest(req, res, req.body);
});

app.get("/mcp", async (req, res) => {
  const sessionId = req.header("mcp-session-id");
  const transport = sessionId ? transports.get(sessionId) : undefined;
  if (!transport) return res.status(400).send("Missing or unknown session");
  await transport.handleRequest(req, res);
});

app.delete("/mcp", async (req, res) => {
  const sessionId = req.header("mcp-session-id");
  const transport = sessionId ? transports.get(sessionId) : undefined;
  if (!transport) return res.status(400).send("Missing or unknown session");
  await transport.handleRequest(req, res);
});

app.listen(3000, () => console.log("MCP HTTP server on :3000"));
```

For production:

- Front with TLS (a reverse proxy or platform termination).
- Authenticate via OAuth 2.1 + Resource Indicators (the spec-mandated scheme for public HTTP servers); short-lived JWT bearer tokens are fine for internal deployments.
- Add CORS only if browser clients will connect directly.
- Validate the `Origin` header to mitigate DNS rebinding.

---

## Python walkthrough

### Project scaffold (Python)

```bash
mkdir my-mcp-server-py && cd my-mcp-server-py
uv init --package
uv add "mcp[cli]>=1.13.0" pydantic
```

`pyproject.toml`:

```toml
[project]
name = "my-mcp-server-py"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
  "mcp[cli]>=1.13.0",
  "pydantic>=2.0",
]

[project.scripts]
my-mcp-server-py = "my_mcp_server_py:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### Hello world with FastMCP

`src/my_mcp_server_py/__init__.py`:

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-mcp-server-py")

@mcp.tool()
def echo(message: str) -> str:
    """Return the input string unchanged."""
    return message

def main() -> None:
    mcp.run()  # defaults to stdio transport
```

Run:

```bash
uv run my-mcp-server-py            # boots on stdio
uv run mcp dev src/my_mcp_server_py/__init__.py  # launches the Inspector
```

### Tools, resources, prompts

`FastMCP` infers JSON Schema from your type hints (it leverages Pydantic under the hood), so most servers stay this concise:

```python
from typing import Annotated
from pydantic import BaseModel, Field
from mcp.server.fastmcp import FastMCP, Context

mcp = FastMCP("notes")

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
    note = notes_service.create(title=title, body=body, tags=tags, pinned=pinned)
    return note

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
        await ctx.report_progress(progress=i + 1, total=steps,
                                  message=f"step {i + 1}/{steps}")
        await asyncio.sleep(0.1)
    return "done"
```

The `Context` parameter is dependency-injected by FastMCP; it gives access to logging, progress reporting, and (when the client supports it) sampling.

### Streamable HTTP in Python

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("notes", stateless_http=False)

# ... register tools/resources/prompts ...

if __name__ == "__main__":
    mcp.run(transport="streamable-http")  # listens on /mcp
```

Or mount inside an existing ASGI app (FastAPI, Starlette):

```python
from fastapi import FastAPI
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("notes")
# ... register ...

app = FastAPI()
app.mount("/mcp", mcp.streamable_http_app())
```

For multi-tenant deployments, set `stateless_http=True` and key per-request context off the `Authorization` header or a request-scoped middleware.

---

## Schema design

Tool descriptions and input schemas are *prompt engineering*. The model reads them and decides whether and how to invoke. A few rules earned in production:

1. **Tool name is a verb-phrase**. `create_issue`, not `issues`. `query_db`, not `db`.
2. **One-sentence description, model-readable**. Lead with what it does, end with when to use it. Skip implementation details.
3. **Every parameter has a `.describe()` / `Field(description=…)`**. Without descriptions the model has only the name to go on.
4. **Use enums for closed sets**. `priority: z.enum(["low", "medium", "high"])` beats `priority: z.string()`. The model picks valid values far more reliably.
5. **Keep schemas shallow**. Models handle flat objects best. If you have deeply nested config, accept it as a JSON string and parse server-side.
6. **Make destructive ops require a confirmation flag**. `delete_repo({ owner, repo, confirm: true })` — model has to be explicit, host can deny calls without `confirm`.
7. **Return structured output where it composes**. `structuredContent` (TS) / second return value (Python) lets the model chain calls without parsing prose.
8. **Tag side effects in the description**. `[read-only]`, `[creates resources]`, `[destructive]`. Hosts can pattern-match these to surface the right confirmation UX.

---

## Error handling

Tools can fail. The protocol distinguishes two failure modes:

### Tool execution error (model-visible)

The tool was called but the underlying operation failed. Return content with `isError: true`. The model sees the error and can recover (retry, ask the user, try a different approach).

TS:

```ts
server.registerTool("fetch_url", { ... }, async ({ url }) => {
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
from mcp.server.fastmcp.exceptions import ToolError

@mcp.tool()
async def fetch_url(url: str) -> str:
    try:
        res = await http_client.get(url)
        res.raise_for_status()
        return res.text
    except httpx.HTTPStatusError as e:
        raise ToolError(f"HTTP {e.response.status_code}: {e.response.reason_phrase}")
```

### Protocol error (host-visible)

The request was malformed or the server is in a bad state. The SDK turns these into JSON-RPC errors automatically — invalid params raise an MCP error code, the host shows a system-level failure rather than feeding it to the model.

Rule of thumb: **invalid inputs are protocol errors; failed operations are tool errors**.

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
- **Include the request id when available.** The SDKs surface it on the call context.

TS:

```ts
// Always use console.error, never console.log
const log = (level: string, msg: string, extra?: object) =>
  console.error(JSON.stringify({ ts: new Date().toISOString(), level, msg, ...extra }));

server.registerTool("create_note", { ... }, async (input, extra) => {
  log("info", "tool.call", { tool: "create_note", requestId: extra._meta?.requestId });
  // ...
});
```

Python's `logging` module writes to stderr by default — just configure it:

```python
import logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
```

To send log messages over MCP to the host (so they surface in the host's log pane), use the protocol's `notifications/message`:

```ts
server.server.sendLoggingMessage({
  level: "info",
  logger: "my-mcp-server",
  data: { event: "tool.call", tool: "create_note" },
});
```

```python
await ctx.info("tool.call", tool="create_note")
```

This is the right channel for user-visible operational info (e.g. "rate-limited by upstream, retrying in 5s"); keep noisy debug on stderr only.

---

## Testing with the Inspector

The Inspector is the dev loop. From your server's repo:

```bash
# TS
npx @modelcontextprotocol/inspector tsx src/index.ts

# Python
uv run mcp dev src/my_mcp_server_py/__init__.py
```

For Streamable HTTP servers, start the server then run:

```bash
npx @modelcontextprotocol/inspector --transport http --server-url http://localhost:3000/mcp
```

Verification flow for every change:

1. Connect — confirm protocol version and advertised capabilities.
2. `tools/list` — confirm count, names, descriptions, and schemas.
3. Invoke each new/changed tool with valid inputs — confirm the response shape.
4. Invoke with invalid inputs — confirm a clean error rather than a crash.
5. Inspect notifications and logs for unexpected warnings.

---

## Automated tests

Run the server in-process to keep tests fast. The TS SDK exposes an in-memory transport pair for this:

```ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { buildServer } from "../src/server.js";
import { describe, it, expect } from "vitest";

describe("create_note", () => {
  it("returns the new note id", async () => {
    const [clientT, serverT] = InMemoryTransport.createLinkedPair();
    const server = buildServer();
    await server.connect(serverT);

    const client = new Client({ name: "test", version: "0.0.0" }, { capabilities: {} });
    await client.connect(clientT);

    const result = await client.callTool({
      name: "create_note",
      arguments: { title: "Hello", body: "World" },
    });

    expect(result.isError).toBeFalsy();
    expect(result.structuredContent?.title).toBe("Hello");
    expect(result.structuredContent?.id).toMatch(/^note_/);
  });
});
```

Python equivalent uses the same `InMemoryTransport` pattern:

```python
import pytest
from mcp import ClientSession
from mcp.shared.memory import create_connected_server_and_client_session
from my_mcp_server_py import mcp

@pytest.mark.asyncio
async def test_create_note():
    async with create_connected_server_and_client_session(mcp._mcp_server) as session:
        result = await session.call_tool(
            "create_note",
            {"title": "Hello", "body": "World"},
        )
        assert not result.isError
        assert result.structuredContent["title"] == "Hello"
```

Keep at least:

- One happy-path test per tool.
- One invalid-input test per tool.
- One regression test for every bug filed.

Run them in CI on every PR.

---

## Versioning

Use SemVer with these specific rules:

- **Patch** (`1.2.x`) — bug fixes, performance, internal refactors. No tool schema change.
- **Minor** (`1.x.0`) — new tools, new optional parameters, new resources, new prompts.
- **Major** (`x.0.0`) — renamed/removed tools, renamed/removed required parameters, changed return shapes, transport changes.

Why this matters: agent workflows that "memorize" tool names break on major bumps. Make them rare, document them loudly in the changelog, and provide a deprecation period (one minor release with both old + new tools, then the major bump that removes the old).

Pin the spec revision your server targets in your README, e.g.:

> Implements MCP spec revision 2025-06-18. Compatible with hosts speaking 2024-11-05 or later (negotiation handles capability differences).

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

### Registry

After publishing, list your server in:

- The official MCP registry: <https://github.com/modelcontextprotocol/registry>
- The Awesome MCP list: <https://github.com/punkpeye/awesome-mcp-servers>
- `mcpservers.org`

This is mostly how users discover servers; it's worth the 15 minutes.

---

## Operational checklist before you ship

Treat this as a literal pre-flight. Most production incidents in MCP servers trace back to one of these.

- [ ] Every tool has a description, a name that begins with a verb, and `.describe()` on every parameter.
- [ ] Destructive tools require an explicit `confirm: true` (or equivalent) parameter.
- [ ] Errors return `isError: true` with a short, model-actionable message — no stack traces, no secrets.
- [ ] All logs go to stderr (stdio) or to `notifications/message` (host-visible). Zero accidental stdout writes.
- [ ] Server survives `tools/list` and `tools/call` concurrency (parallel tool calls are the host default).
- [ ] Long-running tools emit progress notifications.
- [ ] Tool schemas validated with the Inspector against valid and invalid inputs.
- [ ] In-memory tests cover every tool, including failure cases.
- [ ] Version pinned in README; spec revision documented.
- [ ] OAuth / auth model documented for HTTP transport.
- [ ] Rate-limit / quota behavior documented.
- [ ] Telemetry (basic counters at minimum: calls per tool, errors per tool, latency percentiles) — see [`advanced.md`](./advanced.md) for instrumentation patterns including OpenTelemetry and trust/audit platforms like Veriswarm for high-stakes workflows.
- [ ] CHANGELOG covers user-visible changes.
- [ ] README has install command, example config snippet, and the tool list with one-line summaries.

When the list is green, ship it.

---

## Next

- [`advanced.md`](./advanced.md) — sampling, notifications, sessions, security, federation.
- [`configuration.md`](./configuration.md) — config reference, allowlists, multi-instance.
- [`catalog.md`](./catalog.md) — the server catalog.
