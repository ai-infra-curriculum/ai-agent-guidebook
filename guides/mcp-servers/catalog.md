# MCP Server Catalog

Comprehensive catalog of Model Context Protocol (MCP) servers for extending Claude Code and other AI assistants.

> **Last updated**: 2026-10-21 · Tracks MCP spec **2026-07-28**.
>
> **Version note**: install snippets below are unpinned (`npx -y <pkg>` / `uvx <pkg>`) so they keep working as servers release. "Current" versions are listed per entry as of the last-updated date; pin (`<pkg>@<version>` / `<pkg>==<version>`) when supply-chain stability matters.
>
> **Hosted vs. local**: vendor-hosted servers (`"type": "http"`) are increasingly the recommended path — several vendors (Notion, Supabase, Cloudflare, Atlassian) now point users away from their local packages or legacy `/sse` endpoints toward a Streamable HTTP `/mcp` URL with OAuth.

The catalog is split in two files to keep each readable:

- **This file** — Development, Databases, Infrastructure, Quality & Testing, Documentation, Web & APIs, plus setup and configuration examples.
- **[`catalog-specialized.md`](./catalog-specialized.md)** — Productivity & Design, Cloud Services, Communication, Data & Analytics, Agent Governance & Trust.

See the companion guides:

- [`guide.md`](./guide.md) — conceptual intro to MCP.
- [`installation.md`](./installation.md) — install across hosts.
- [`configuration.md`](./configuration.md) — config reference and allowlists.
- [`building.md`](./building.md) — build your own server.
- [`advanced.md`](./advanced.md) — stateless core, elicitation, extensions, security, federation, telemetry.

---

## Table of Contents

- [Development](#development)
- [Databases](#databases)
- [Infrastructure](#infrastructure)
- [Quality & Testing](#quality--testing)
- [Documentation](#documentation)
- [Web & APIs](#web--apis)
- [Productivity & Design](./catalog-specialized.md#productivity--design) *(in catalog-specialized.md)*
- [Cloud Services](./catalog-specialized.md#cloud-services) *(in catalog-specialized.md)*
- [Communication](./catalog-specialized.md#communication) *(in catalog-specialized.md)*
- [Data & Analytics](./catalog-specialized.md#data--analytics) *(in catalog-specialized.md)*
- [Agent Governance & Trust](./catalog-specialized.md#agent-governance--trust) *(in catalog-specialized.md)*
- [Installation Guide](#installation-guide)
- [Configuration Examples](#configuration-examples)
- [Resources](#resources)
- [Contributing](#contributing)

---

## Development

### GitHub MCP
**Package**: official hosted server at `https://api.githubcopilot.com/mcp/` (recommended) · self-hostable Go binary at [`github/github-mcp-server`](https://github.com/github/github-mcp-server)

> **Note**: the old `@modelcontextprotocol/server-github` npm package is **archived** (moved to [`modelcontextprotocol/servers-archived`](https://github.com/modelcontextprotocol/servers-archived)) and deprecated on npm. Use GitHub's official hosted server or `github/github-mcp-server` instead.

**Features**:
- Create and manage repositories
- Issues and pull requests
- GitHub Actions workflows
- Code search across orgs
- Repository content operations

**Installation (hosted, recommended)**:
```json
{
  "github": {
    "type": "http",
    "url": "https://api.githubcopilot.com/mcp/"
  }
}
```

**Installation (self-hosted, Docker)**:
```json
{
  "github": {
    "command": "docker",
    "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
             "ghcr.io/github/github-mcp-server"],
    "env": {"GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"}
  }
}
```

**Use Cases**:
- Automated repository operations
- Issue and PR triage
- Code review automation
- Cross-repo search

---

### Filesystem MCP
**Package**: `@modelcontextprotocol/server-filesystem` · current `2.0.0`

> **Note**: the reference servers' **v2.0.0** release (2026-10-19) moved the TypeScript servers (filesystem, memory, sequential-thinking, everything) to the v2 SDK and the 2026-07-28 spec while still answering legacy clients, and raised their Node.js floor to **24**.

**Features**:
- File read/write/edit with diff previews
- Directory listing and search
- Bulk operations
- Access limited to the directories passed on the command line (also honors client-advertised roots, a feature deprecated in 2026-07-28)

**Installation**:
```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/project"]
  }
}
```

**Use Cases**:
- Complex file operations
- Multi-file edits
- Directory restructuring

---

### Git MCP
**Package**: `mcp-server-git` (Python, via `uvx`) · current `2026.10.19`

**Features**:
- Git operations (status, log, diff, show, add, commit, branch)
- Repository inspection
- Access scoped by `--repository` (or each call's `repo_path`); flag-injection guards on arguments
- Includes write tools such as `git_add` and `git_commit` — restrict them with host allowlists if you want read-only use

**Installation**:
```json
{
  "git": {
    "command": "uvx",
    "args": ["mcp-server-git", "--repository", "/path/to/repo"]
  }
}
```

---

### Memory MCP
**Package**: `@modelcontextprotocol/server-memory` · current `2.0.0`

**Features**:
- Knowledge graph persistence
- Entity and relation tracking
- Cross-session state
- Local file-backed storage

**Installation**:
```json
{
  "memory": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-memory"],
    "env": {"MEMORY_FILE_PATH": "/path/to/memory.jsonl"}
  }
}
```

**Use Cases**:
- Multi-session projects
- State persistence
- Context preservation

---

### Sequential Thinking MCP
**Package**: `@modelcontextprotocol/server-sequential-thinking` · current `2.0.0`

**Features**:
- Structured reasoning scratchpad
- Revisable thought chains
- Branching exploration of alternatives

**Installation**:
```json
{
  "sequential-thinking": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
  }
}
```

---

## Databases

### PostgreSQL MCP
**Package**: `@modelcontextprotocol/server-postgres` · **archived** (last release `0.6.2`)

> **Note**: the reference Postgres server is **archived** (moved to [`modelcontextprotocol/servers-archived`](https://github.com/modelcontextprotocol/servers-archived)) and deprecated on npm. For maintained options, look at community/vendor servers such as **Postgres MCP Pro** ([`crystaldba/postgres-mcp`](https://github.com/crystaldba/postgres-mcp)), the **Neon MCP** (hosted, below), the **Supabase MCP** (below), or Google's managed Cloud SQL / AlloyDB servers ([`catalog-specialized.md`](./catalog-specialized.md#google-cloud-mcp)).

**Features (archived server)**:
- Read-only SQL queries
- Schema inspection (tables, columns)

**Installation (legacy — connection string is a positional argument, not an env var)**:
```json
{
  "postgres": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-postgres",
             "postgresql://user:pass@localhost:5432/db"]
  }
}
```

---

### SQLite MCP
**Package**: `mcp-server-sqlite` (Python) · **archived** (last release `2025.4.25`)

> **Note**: archived to [`modelcontextprotocol/servers-archived`](https://github.com/modelcontextprotocol/servers-archived); no longer maintained. Community alternatives exist on PyPI and npm if you need active maintenance.

**Features**:
- SQLite database operations
- Local data storage
- Schema and index inspection

**Installation (legacy)**:
```json
{
  "sqlite": {
    "command": "uvx",
    "args": ["mcp-server-sqlite", "--db-path", "/path/to/database.db"]
  }
}
```

---

### MongoDB MCP
**Package**: `mongodb-mcp-server` (official, MongoDB Inc.) · current `3.1.0`

**Features**:
- MongoDB Atlas + self-hosted operations
- Document queries and updates
- Aggregation pipelines
- Collection and index management
- `--readOnly` flag to disable write tools

**Installation**:
```json
{
  "mongodb": {
    "command": "npx",
    "args": ["-y", "mongodb-mcp-server", "--readOnly"],
    "env": {"MDB_MCP_CONNECTION_STRING": "${MONGODB_URI}"}
  }
}
```

---

### Neon MCP
**Package**: hosted at `https://mcp.neon.tech/mcp` (the older `/sse` endpoint is deprecated) · source [`neondatabase/mcp-server-neon`](https://github.com/neondatabase/mcp-server-neon)

**Features**:
- Serverless Postgres branching
- Project + branch + database management
- Direct SQL execution
- Tool categories selectable via `?category=` query parameters (e.g. `projects`, `branches`, `querying`, `schema`)

**Installation**:
```json
{
  "neon": {
    "type": "http",
    "url": "https://mcp.neon.tech/mcp"
  }
}
```

---

### Supabase MCP
**Package**: hosted at `https://mcp.supabase.com/mcp` (recommended) · source [`supabase/mcp`](https://github.com/supabase/mcp) · npm `@supabase/mcp-server-supabase` (current `0.14.0`) is still published for local use

**Features**:
- Project / branch / migration management
- SQL execution
- Docs search
- Scope with query parameters such as `project_ref`, `read_only=true`, and `features=database,docs`

**Installation (hosted, scoped read-only)**:
```json
{
  "supabase": {
    "type": "http",
    "url": "https://mcp.supabase.com/mcp?project_ref=<project-ref>&read_only=true"
  }
}
```

---

## Infrastructure

### Kubernetes MCP
**Package**: `kubernetes-mcp-server` (npm/PyPI, from the GitHub [`containers`](https://github.com/containers/kubernetes-mcp-server) org) · current `0.0.67`

**Features**:
- Native Kubernetes API client (not a `kubectl` wrapper): pods, deployments, services, configmaps, generic resources
- Helm install / list / uninstall
- Multi-cluster (kubeconfig context switching)
- Toolsets (`core`, `config`, `helm`, …) and `read_only` mode via the TOML config

**Installation (npx)**:
```json
{
  "kubernetes": {
    "command": "npx",
    "args": ["-y", "kubernetes-mcp-server@latest"]
  }
}
```

**Use Cases**:
- K8s resource creation
- Cluster diagnostics
- Deployment automation

---

### Docker MCP Toolkit
**Package**: MCP Toolkit built into Docker Desktop (the current UI documents Docker Desktop **4.62+**) · gateway source [`docker/mcp-gateway`](https://github.com/docker/mcp-gateway)

**Features**:
- Curated catalog of containerized MCP servers, added to named **profiles**
- OAuth handled per server in the Toolkit UI
- One gateway (`docker mcp gateway run`) fronts every server in a profile
- Sandboxed, containerized tool execution

**Installation**: open **MCP Toolkit** in Docker Desktop, add servers from the **Catalog** tab, then connect a client from the **Clients** tab — or point any client at the gateway:
```json
{
  "MCP_DOCKER": {
    "command": "docker",
    "args": ["mcp", "gateway", "run", "--profile", "my_profile"]
  }
}
```

**Use Cases**:
- Running third-party servers in containers instead of directly on the host
- Sharing one curated server set across several clients
- Local development environments

---

### Terraform MCP
**Package**: `hashicorp/terraform-mcp-server` (official, HashiCorp) — a Go binary distributed via Docker and [GitHub releases](https://github.com/hashicorp/terraform-mcp-server/releases), **not** npm

> **Note**: the `terraform-mcp-server` package on npm is a separate community project (thrashr888), not HashiCorp's.

**Features**:
- Terraform Registry provider + module doc lookup
- Registry module search
- Terraform-aware code assistance

**Installation (Docker)**:
```json
{
  "terraform": {
    "command": "docker",
    "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server"]
  }
}
```

---

### Cloudflare MCP
**Package**: hosted. The recommended server is the **Cloudflare API MCP Server** at `https://mcp.cloudflare.com/mcp` ([`cloudflare/mcp`](https://github.com/cloudflare/mcp)), which gives broad access to Cloudflare's APIs through code execution. Domain-specific servers live at `https://<product>.mcp.cloudflare.com/mcp` ([`cloudflare/mcp-server-cloudflare`](https://github.com/cloudflare/mcp-server-cloudflare)) — e.g. `docs`, `containers`, `browser`, `radar`.

> **Note**: several per-product servers, including **Workers Bindings** (`bindings.mcp.cloudflare.com`) and **Observability**, are now listed as **deprecated** in favor of the API server. All Cloudflare servers are stateless Streamable HTTP; `/sse` survives only as a URL alias, and a legacy HTTP+SSE `GET /sse` returns `410 Gone` — use `/mcp`.

**Features**:
- Cloudflare API coverage (Workers, storage, DNS, and more) via the API server
- Docs search (`https://docs.mcp.cloudflare.com/mcp`)
- Sandbox containers, browser rendering, Radar insights via domain servers

**Installation (recommended API server)**:
```json
{
  "cloudflare": {
    "type": "http",
    "url": "https://mcp.cloudflare.com/mcp"
  }
}
```

---

## Quality & Testing

### Playwright MCP
**Package**: `@playwright/mcp` · current `0.0.83` (the package versions on a `0.0.x` line — the README uses `@latest`) · source [`microsoft/playwright-mcp`](https://github.com/microsoft/playwright-mcp)

**Features**:
- Full browser automation (Chromium, Firefox, WebKit)
- Accessibility-tree-based interaction (no fragile selectors)
- Screenshots, PDF, network capture
- Headed and headless

**Installation**:
```json
{
  "playwright": {
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest"]
  }
}
```

**Use Cases**:
- E2E testing
- Web scraping with auth
- Visual regression
- Repro-browser-bug investigations

---

### MCP Tools Py (formerly MCP Code Checker)
**Package**: `mcp-tools-py` · current `0.1.10` on PyPI · source [`MarcusJellinghaus/mcp-tools-py`](https://github.com/MarcusJellinghaus/mcp-tools-py) (the old `mcp-code-checker` repo name redirects here)

**Features**:
- pylint, pytest, and mypy runs scoped to a `--project-dir`
- Formatting and refactoring helpers for Python projects
- Size-limited, LLM-friendly result summaries
- Python projects only

**Installation**:
```json
{
  "python-tools": {
    "command": "mcp-tools-py",
    "args": ["--project-dir", "/path/to/project"]
  }
}
```

(Install with `pip install mcp-tools-py`, or from source per the README.)

---

### Semgrep MCP
**Package**: built into the **`semgrep` CLI** (`semgrep mcp`) · the standalone [`semgrep/mcp`](https://github.com/semgrep/mcp) repo is **archived** and the `semgrep-mcp` PyPI package (last `0.9.0`, 2025-09) is no longer where updates land

**Features**:
- Static analysis with Semgrep rules
- Custom rule authoring
- Multi-language (TS, Python, Go, Java, Ruby, etc.)
- stdio or Streamable HTTP (`semgrep mcp -t streamable-http`)

**Installation** (after `brew install semgrep` or another Semgrep CLI install):
```json
{
  "semgrep": {
    "command": "semgrep",
    "args": ["mcp"]
  }
}
```

---

## Documentation

### Context7 MCP
**Package**: hosted at `https://mcp.context7.com/mcp` · also `@upstash/context7-mcp` (current `4.4.4`) for stdio

**Features**:
- Up-to-date library docs
- Version-specific API references
- Code examples
- Topic search

**Installation (hosted)**:
```json
{
  "context7": {
    "type": "http",
    "url": "https://mcp.context7.com/mcp",
    "headers": {"Authorization": "Bearer ${CONTEXT7_API_KEY}"}
  }
}
```

**Use Cases**:
- Pulling current API docs into context
- Avoiding outdated model knowledge
- Quick code-example lookups

---

### Mintlify MCP CLI
**Package**: `@mintlify/mcp` ("The Mintlify MCP package manager") · current `1.1.x`

**Note**: this is a CLI that installs MCP servers for **Mintlify-hosted documentation sites** — it is not a docs generator.

**Features**:
- One-command install of a docs site's MCP server into your host
- Search + Q&A tools over the hosted docs corpus

**Installation**:
```bash
npx @mintlify/mcp add <docs-site>
```

---

### MarkItDown MCP (Microsoft)
**Package**: `markitdown-mcp` · current `0.0.1a7` (pre-release) · source [`microsoft/markitdown`](https://github.com/microsoft/markitdown)

**Features**:
- PDF / DOCX / PPTX / XLSX → Markdown
- HTML → Markdown
- Converts `http:`, `https:`, `file:`, and `data:` URIs

**Installation**:
```bash
uvx markitdown-mcp
```

---

## Web & APIs

### Puppeteer MCP
**Package**: `@modelcontextprotocol/server-puppeteer` · **archived** (moved to [`modelcontextprotocol/servers-archived`](https://github.com/modelcontextprotocol/servers-archived), deprecated on npm)

**Note**: use the **Playwright MCP** (`@playwright/mcp`, above) instead — actively maintained, broader browser support, and more stable accessibility-tree interaction.

---

### Brave Search MCP
**Package**: `@brave/brave-search-mcp-server` (official, Brave) · current `2.1.x`

> **Note**: the old `@modelcontextprotocol/server-brave-search` reference server is archived and deprecated on npm; Brave now maintains the official package.

**Features**:
- Web search via Brave Search API
- Local / image / news / video search
- Independent search index

**Installation**:
```json
{
  "brave-search": {
    "command": "npx",
    "args": ["-y", "@brave/brave-search-mcp-server"],
    "env": {"BRAVE_API_KEY": "${BRAVE_API_KEY}"}
  }
}
```

---

### Fetch MCP
**Package**: `mcp-server-fetch` (Python) · current `2026.10.19`

**Features**:
- URL fetch with content extraction (HTML → Markdown)
- Chunked reading via `start_index`
- Robots.txt respect

**Installation**:
```json
{
  "fetch": {
    "command": "uvx",
    "args": ["mcp-server-fetch"]
  }
}
```

> **Security**: a fetch tool pulls untrusted content into the model's context — the classic prompt-injection vector. See [`advanced.md`](./advanced.md#prompt-injection-and-tool-call-defense).

---

### Firecrawl MCP
**Package**: `firecrawl-mcp` · current `3.33.x`

**Features**:
- Full-site crawl with JS rendering
- Markdown / structured-data extraction
- Sitemap-aware
- Hosted or self-hosted backend

**Installation**:
```json
{
  "firecrawl": {
    "command": "npx",
    "args": ["-y", "firecrawl-mcp"],
    "env": {"FIRECRAWL_API_KEY": "${FIRECRAWL_API_KEY}"}
  }
}
```

---

## Installation Guide

### Quick Setup

1. **Pick a host**: Claude Code, Claude Desktop, Cursor, Cline, Continue, Windsurf, Zed, or a custom SDK client. See [`installation.md`](./installation.md) for per-host paths.

2. **Add servers** to the host's config (shape varies, but `mcpServers` is conventional):
```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name@version"],
      "env": {"KEY": "${KEY}"}
    }
  }
}
```

3. **Set environment variables**. Prefer `${VAR}` substitution + a shell-init secret loader (1Password CLI, macOS Keychain, direnv) over literal tokens in committed files. For hosted servers, prefer OAuth over static tokens.

4. **Verify with the Inspector** before wiring into your daily-driver host (Inspector v2 requires Node ≥ 22.19.0):
```bash
npx @modelcontextprotocol/inspector npx -y <package> [args]
```

5. **Restart your host** to pick up config changes.

See [`installation.md`](./installation.md) for the full per-host walkthrough.

---

## Configuration Examples

### Complete Development Setup

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/projects"]
    },
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "/path/to/repo"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {"MEMORY_FILE_PATH": "/path/to/memory.jsonl"}
    },
    "neon": {
      "type": "http",
      "url": "https://mcp.neon.tech/mcp"
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {"Authorization": "Bearer ${CONTEXT7_API_KEY}"}
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

For configuration patterns (allow/deny, multi-instance, scoping), see [`configuration.md`](./configuration.md).

---

## Resources

- **Official MCP Registry** (preview): <https://registry.modelcontextprotocol.io> · source <https://github.com/modelcontextprotocol/registry>
- **Official reference servers**: <https://github.com/modelcontextprotocol/servers>
- **Awesome MCP** (community list): <https://github.com/punkpeye/awesome-mcp-servers>
- **MCP Directory**: <https://mcpservers.org/>
- **MCP Spec**: <https://modelcontextprotocol.io/specification/latest>
- **Inspector**: <https://github.com/modelcontextprotocol/inspector>

---

## Contributing

Submit your MCP server to the community:
1. Publish to npm or PyPI with a clear README, install command, and tool surface
2. Publish a `server.json` to the official MCP Registry with `mcp-publisher` (see [`building.md`](./building.md#the-official-mcp-registry))
3. Add to Awesome MCP Servers
4. List on `mcpservers.org`
5. Share in the MCP Discord / GitHub Discussions

**Inclusion bar for this catalog**: an actively maintained, publicly available server (published package or vendor-hosted endpoint) with a stable release or vendor backing, and install instructions we can verify against the project's own README. Pre-release / single-maintainer projects are better served by the registries above until they mature.

See [`building.md`](./building.md) for the build, test, and publish walkthrough.

---

**Last Updated**: 2026-10-21

**Total Servers**: 40 entries across 11 categories (both catalog files; includes archived entries kept for migration notes)
