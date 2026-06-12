# MCP Server Catalog

Comprehensive catalog of Model Context Protocol (MCP) servers for extending Claude Code and other AI assistants.

> **Last updated**: 2026-06-11 · Tracks MCP spec **2025-11-25**.
>
> **Version note**: install snippets below are unpinned (`npx -y <pkg>` / `uvx <pkg>`) so they keep working as servers release. "Current" versions are listed per entry as of the last-updated date; pin (`<pkg>@<version>` / `<pkg>==<version>`) when supply-chain stability matters.

See the companion guides:

- [`guide.md`](./guide.md) — conceptual intro to MCP.
- [`installation.md`](./installation.md) — install across hosts.
- [`configuration.md`](./configuration.md) — config reference and allowlists.
- [`building.md`](./building.md) — build your own server.
- [`advanced.md`](./advanced.md) — sampling, security, federation, telemetry.

---

## Table of Contents

- [Development](#development)
- [Databases](#databases)
- [Infrastructure](#infrastructure)
- [Quality & Testing](#quality--testing)
- [Documentation](#documentation)
- [Web & APIs](#web--apis)
- [Productivity](#productivity)
- [Cloud Services](#cloud-services)
- [Communication](#communication)
- [Data & Analytics](#data--analytics)
- [Agent Governance & Trust](#agent-governance--trust)

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
**Package**: `@modelcontextprotocol/server-filesystem` · current `2026.1.14`

**Features**:
- File read/write/edit with diff previews
- Directory listing and search
- Bulk operations
- Roots-based access control (honors client-advertised roots)

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
**Package**: `mcp-server-git` (Python, via `uvx`) · current `2026.6.4`

**Features**:
- Git operations (status, log, diff, show, add, commit, branch)
- Repository inspection
- Read-only by default; write tools opt-in

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
**Package**: `@modelcontextprotocol/server-memory` · current `2026.1.26`

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
**Package**: `@modelcontextprotocol/server-sequential-thinking` · current `2025.12.18`

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

> **Note**: the reference Postgres server is **archived** (moved to [`modelcontextprotocol/servers-archived`](https://github.com/modelcontextprotocol/servers-archived)) and deprecated on npm. For maintained options, look at community/vendor servers such as **Postgres MCP Pro** (`crystaldba/postgres-mcp`), the **Neon MCP** (hosted, below), or the **Supabase MCP** (below).

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
**Package**: `mongodb-mcp-server` (official, MongoDB Inc.) · current `1.12.0`

**Features**:
- MongoDB Atlas + self-hosted operations
- Document queries and updates
- Aggregation pipelines
- Collection and index management

**Installation**:
```json
{
  "mongodb": {
    "command": "npx",
    "args": ["-y", "mongodb-mcp-server"],
    "env": {"MDB_MCP_CONNECTION_STRING": "${MONGODB_URI}"}
  }
}
```

---

### Neon MCP
**Package**: hosted at `https://mcp.neon.tech/mcp` (the older `/sse` endpoint is deprecated)

**Features**:
- Serverless Postgres branching
- Project + branch + database management
- Direct SQL execution
- One-click query inspector integration

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
**Package**: `@supabase/mcp-server-supabase` · current `0.8.2`

**Features**:
- Project / branch / migration management
- SQL execution
- Auth + storage admin
- Edge function deploys

**Installation**:
```json
{
  "supabase": {
    "command": "npx",
    "args": ["-y", "@supabase/mcp-server-supabase", "--access-token", "${SUPABASE_ACCESS_TOKEN}"]
  }
}
```

---

## Infrastructure

### Kubernetes MCP
**Package**: `kubernetes-mcp-server` (npm/PyPI, from the GitHub `containers` org) · current `0.0.62`

**Features**:
- kubectl operations (pods, deployments, services, configmaps, secrets)
- Helm chart operations
- Multi-cluster (kubeconfig context switching)
- Read-only mode via `--read-only`

**Installation (npx)**:
```json
{
  "kubernetes": {
    "command": "npx",
    "args": ["-y", "kubernetes-mcp-server@latest"]
  }
}
```

**Installation (Docker)**:
```json
{
  "kubernetes": {
    "command": "docker",
    "args": ["run", "-i", "--rm", "-v", "~/.kube:/home/mcp/.kube:ro",
             "quay.io/manusa/kubernetes_mcp_server"]
  }
}
```

**Use Cases**:
- K8s resource creation
- Cluster diagnostics
- Deployment automation

---

### Docker MCP
**Package**: Docker MCP Toolkit (bundled with Docker Desktop ≥ 4.40) · also `docker/mcp` containerized server

**Features**:
- Container lifecycle (run, stop, logs, exec)
- Image management
- Docker Compose orchestration
- Curated catalog of vetted MCP servers behind a toolkit UI

**Installation (Docker Desktop)**: Enable in Settings → Extensions → MCP Toolkit.

**Use Cases**:
- Container orchestration
- Local development environments
- Sandboxed tool execution

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
**Package**: hosted, **per-product servers** (there is no single `mcp.cloudflare.com` endpoint) — e.g. `https://bindings.mcp.cloudflare.com/sse` (Workers bindings), `https://observability.mcp.cloudflare.com/sse` (logs/analytics), plus a docs server. Full list: <https://github.com/cloudflare/mcp-server-cloudflare>

**Features**:
- Workers builds + bindings (KV / R2 / D1 / Queues)
- Observability: logs and analytics queries
- DNS analytics
- Docs search

**Installation (example: Workers bindings)**:
```json
{
  "cloudflare-bindings": {
    "type": "http",
    "url": "https://bindings.mcp.cloudflare.com/sse"
  }
}
```

---

## Quality & Testing

### Playwright MCP
**Package**: `@playwright/mcp` · current `0.0.76` (the package versions on a `0.0.x` line — use unpinned)

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
    "args": ["-y", "@playwright/mcp"]
  }
}
```

**Use Cases**:
- E2E testing
- Web scraping with auth
- Visual regression
- Repro-browser-bug investigations

---

### MCP Code Checker
**Package**: GitHub-only — [`MarcusJellinghaus/mcp-code-checker`](https://github.com/MarcusJellinghaus/mcp-code-checker) (not published to PyPI)

**Features**:
- pylint integration
- pytest execution with structured output
- Coverage reports
- LLM-friendly result summaries

**Installation** (clone + install from source per the repo README):
```bash
git clone https://github.com/MarcusJellinghaus/mcp-code-checker.git
pip install -e ./mcp-code-checker
```

---

### Semgrep MCP
**Package**: `semgrep-mcp` (PyPI) · current `0.9.0` · repo [`semgrep/mcp`](https://github.com/semgrep/mcp)

**Features**:
- Static analysis with Semgrep rules
- Custom rule authoring
- Multi-language (TS, Python, Go, Java, Ruby, etc.)
- SARIF output

**Installation**:
```json
{
  "semgrep": {
    "command": "uvx",
    "args": ["semgrep-mcp"]
  }
}
```

---

## Documentation

### Context7 MCP
**Package**: hosted at `https://mcp.context7.com/mcp` · also `@upstash/context7-mcp` for stdio

**Features**:
- Up-to-date library docs (10,000+ packages)
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
**Package**: `@mintlify/mcp` · current `1.1.x`

**Note**: this is a CLI that installs MCP servers for **Mintlify-hosted documentation sites** (every Mintlify-hosted docs site can expose an MCP server) — it is not a docs generator.

**Features**:
- One-command install of a docs site's MCP server into your host
- Search + Q&A tools over the hosted docs corpus

**Installation**:
```bash
npx @mintlify/mcp add <docs-site>
```

---

### MarkItDown MCP (Microsoft)
**Package**: `markitdown-mcp` · current `0.0.1a4` (pre-release)

**Features**:
- PDF / DOCX / PPTX / XLSX → Markdown
- HTML → Markdown
- Image OCR
- ZIP-archive batch conversion

**Installation**:
```bash
uvx markitdown-mcp
```

---

### MCP Documentation Service
**Package**: `mcp-docs-service` · current `7.2.1`

**Features**:
- Markdown management
- Frontmatter metadata
- Navigation generation
- Documentation aggregation

---

## Web & APIs

### Puppeteer MCP
**Package**: `@modelcontextprotocol/server-puppeteer` · **archived** (moved to [`modelcontextprotocol/servers-archived`](https://github.com/modelcontextprotocol/servers-archived), deprecated on npm)

**Note**: use the **Playwright MCP** (`@playwright/mcp`, above) instead — actively maintained, broader browser support, and more stable accessibility-tree interaction.

**Features (archived server)**:
- Headless Chromium automation
- Screenshot capture
- Form filling
- Web scraping

---

### Brave Search MCP
**Package**: `@brave/brave-search-mcp-server` (official, Brave) · current `2.0.x`

> **Note**: the old `@modelcontextprotocol/server-brave-search` reference server is archived and deprecated on npm; Brave now maintains the official package.

**Features**:
- Web search via Brave Search API
- Local / image / news / video search
- No tracking; independent index

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
**Package**: `mcp-server-fetch` (Python) · current `2026.6.4`

**Features**:
- HTTP GET / POST
- Content extraction (HTML → Markdown)
- Pagination via `start_index`
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

---

### Firecrawl MCP
**Package**: `firecrawl-mcp` · current `3.20.4`

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

## Productivity

### Notion MCP
**Package**: hosted at `https://mcp.notion.com/mcp` · also `@notionhq/notion-mcp-server` for stdio

**Features**:
- Page + database CRUD
- Block-level edits
- Comment management
- Database queries with filters

**Installation (hosted)**:
```json
{
  "notion": {
    "type": "http",
    "url": "https://mcp.notion.com/mcp"
  }
}
```

---

### Linear MCP
**Package**: hosted-only at `https://mcp.linear.app/mcp` (Linear does not publish a stdio npm package)

**Features**:
- Issue lifecycle (create / update / assign / close)
- Project + cycle management
- Search across teams
- Triage workflows

**Installation (hosted)**:
```json
{
  "linear": {
    "type": "http",
    "url": "https://mcp.linear.app/mcp"
  }
}
```

---

### Atlassian MCP (Jira + Confluence)
**Package**: hosted at `https://mcp.atlassian.com/v1/sse`

**Features**:
- Jira issue + project management
- Confluence page CRUD + search
- JQL queries
- Cross-product linking

**Installation**:
```json
{
  "atlassian": {
    "type": "http",
    "url": "https://mcp.atlassian.com/v1/sse"
  }
}
```

---

### Sentry MCP
**Package**: hosted at `https://mcp.sentry.dev/mcp`

**Features**:
- Issue + event inspection
- Stacktrace + breadcrumb retrieval
- Release tracking
- Project + team admin

**Installation**:
```json
{
  "sentry": {
    "type": "http",
    "url": "https://mcp.sentry.dev/mcp"
  }
}
```

---

### Stripe MCP
**Package**: hosted at `https://mcp.stripe.com/` · also `@stripe/mcp` for stdio

**Features**:
- Customers, charges, subscriptions, invoices
- Product + price catalog
- Webhook inspection
- Test-mode safe by default

**Installation (hosted)**:
```json
{
  "stripe": {
    "type": "http",
    "url": "https://mcp.stripe.com"
  }
}
```

---

## Cloud Services

### AWS MCP
**Package**: the official [`awslabs/mcp`](https://github.com/awslabs/mcp) collection — dozens of per-service PyPI packages named `awslabs.<service>-mcp-server` (e.g. `awslabs.aws-documentation-mcp-server`, `awslabs.s3-tables-mcp-server`, `awslabs.cdk-mcp-server`)

**Features**:
- Per-service servers across S3 Tables, Lambda, ECS, RDS, CloudFormation/CDK, and more
- CloudWatch logs + metrics queries
- Cost analysis servers
- SSO + profile-based auth

**Installation (example, AWS documentation server)**:
```json
{
  "aws-docs": {
    "command": "uvx",
    "args": ["awslabs.aws-documentation-mcp-server@latest"],
    "env": {"AWS_PROFILE": "default", "AWS_REGION": "us-east-1"}
  }
}
```

---

### Google Cloud MCP
**Package**: `gcp-mcp-server` collection

**Features**:
- GCS / Compute / Cloud Run / Cloud Functions / BigQuery
- IAM + project admin
- Logs Explorer queries
- ADC + service-account auth

---

### Azure MCP
**Package**: `@azure/mcp` (Microsoft, official) · current `3.0.0-beta.x`

**Features**:
- Storage (Blob, Queue, Table)
- App Service + Functions
- Cosmos DB
- Resource group + subscription admin
- Entra ID auth

**Installation**:
```json
{
  "azure": {
    "command": "npx",
    "args": ["-y", "@azure/mcp@latest", "server", "start"]
  }
}
```

---

### Vercel MCP
**Package**: hosted at `https://mcp.vercel.com/`

**Features**:
- Project + deployment management
- Env var admin
- Domain config
- Deployment logs

**Installation**:
```json
{
  "vercel": {
    "type": "http",
    "url": "https://mcp.vercel.com/"
  }
}
```

---

## Communication

### Slack MCP
**Package**: `slack-mcp-server` (community, maintained) · the old `@modelcontextprotocol/server-slack` reference server is **archived** and deprecated on npm

**Features**:
- Send messages (channels + DMs)
- Channel + user lookup
- Message history search

**Installation**:
```json
{
  "slack": {
    "command": "npx",
    "args": ["-y", "slack-mcp-server@latest", "--transport", "stdio"],
    "env": {
      "SLACK_MCP_XOXP_TOKEN": "${SLACK_MCP_XOXP_TOKEN}"
    }
  }
}
```

---

### Discord MCP
**Package**: `discord-mcp-server` · current `0.4.0`

**Features**:
- Bot message send/edit/delete
- Channel + role management
- Member operations
- Slash command registration

---

## Data & Analytics

### Jupyter MCP
**Package**: `jupyter-mcp-server` · current `1.0.2`

**Features**:
- Notebook execution against running Jupyter kernel
- Cell add / edit / delete
- Output capture (text, images, plots)
- Multi-notebook workspace

---

### ClickHouse MCP
**Package**: `mcp-clickhouse` · current `0.4.0`

**Features**:
- ClickHouse query execution
- Schema + partition inspection
- Read-only by default
- Cloud + self-hosted

**Installation**:
```json
{
  "clickhouse": {
    "command": "uvx",
    "args": ["mcp-clickhouse"],
    "env": {
      "CLICKHOUSE_HOST": "${CH_HOST}",
      "CLICKHOUSE_USER": "${CH_USER}",
      "CLICKHOUSE_PASSWORD": "${CH_PASSWORD}"
    }
  }
}
```

---

## Agent Governance & Trust

Production agent deployments need more than tool access — they need identity, policy enforcement, and tamper-evident audit. The servers in this section sit *between* hosts and other MCPs (or wrap calls inline) to add trust-layer capabilities.

### Veriswarm.ai
**Package**: hosted at `https://mcp.veriswarm.ai/` · also stdio + SDK integrations for LangChain, CrewAI, AutoGen, Bedrock AgentCore, Salesforce Agentforce, Microsoft Agent 365

**Features**:
- **Trust scoring** — real-time per-call policy decisions (allow / warn / block) with explainable reasons
- **PII detection + redaction** — inbound and outbound content scanning
- **Prompt-injection guard** — heuristic + model-based detection against indirect prompt injection in tool outputs
- **Passport** — portable agent identity credentials usable across frameworks
- **Vault** — hash-chained, tamper-evident audit ledger over every tool call (inputs, outputs, decisions, identities)
- **65+ tools** exposed via MCP for policy authoring, decision queries, audit search, identity management
- **Cross-framework** — same governance layer across LangChain, CrewAI, AutoGen, Bedrock, Agentforce, Microsoft Agent 365, custom agents

**Installation (hosted)**:
```json
{
  "veriswarm": {
    "type": "http",
    "url": "https://mcp.veriswarm.ai/",
    "headers": {"Authorization": "Bearer ${VERISWARM_API_KEY}"}
  }
}
```

**Pricing**:
- Free — 5,000 decisions/day, 10 agents
- Pro — $49/mo
- Max — $299/mo
- Enterprise — custom (SOC2, private deploy, SSO, dedicated support)

**Use Cases**:
- Pre-deployment policy enforcement on agent tool calls
- SOC2 / HIPAA / FINRA audit evidence for agent actions
- Cross-team agent identity (Passport carries trust score + permissions across workflows)
- Incident replay over the Vault hash chain

**Website**: <https://veriswarm.ai>

---

### LangSmith
**Package**: hosted service (LangChain Inc.) · MCP server in preview at `https://mcp.smith.langchain.com/`

**Features**:
- Trace + span ingestion for LLM + tool calls
- Eval datasets and online evaluators
- Prompt experiment tracking
- Annotation queues for SME review
- Works with any framework via SDK; MCP server exposes trace + dataset query tools to agents directly

**Pricing**: Free developer tier; Plus $39/user/mo; Enterprise custom.

**Website**: <https://smith.langchain.com>

---

### Arize Phoenix
**Package**: `@arizeai/phoenix-mcp` (npm) · current `4.x` · OSS

**Features**:
- OpenTelemetry-based LLM + tool tracing
- Embedding drift visualization
- LLM evaluators (relevance, hallucination, toxicity)
- Self-hostable; no vendor lock-in
- MCP server lets agents query their own traces and run evals over recent activity

**Installation**:
```json
{
  "phoenix": {
    "command": "npx",
    "args": ["-y", "@arizeai/phoenix-mcp@latest",
             "--baseUrl", "http://localhost:6006"]
  }
}
```

**Website**: <https://phoenix.arize.com>

---

### Patronus AI
**Package**: GitHub-only — [`patronus-ai/patronus-mcp-server`](https://github.com/patronus-ai/patronus-mcp-server) (not published to PyPI)

**Features**:
- Pre-deployment evals across hallucination, safety, brand-voice
- Policy enforcement at inference time
- Synthetic test generation
- Industry-tuned evaluators (legal, healthcare, finance)
- MCP tools for running an eval suite against a candidate agent change

**Pricing**: Free trial; Team and Enterprise tiers.

**Website**: <https://www.patronus.ai>

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

3. **Set environment variables**. Prefer `${VAR}` substitution + a shell-init secret loader (1Password CLI, macOS Keychain, direnv) over literal tokens in committed files.

4. **Verify with the Inspector** before wiring into your daily-driver host:
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
      "args": ["-y", "@playwright/mcp"]
    }
  }
}
```

For configuration patterns (allow/deny, multi-instance, scoping), see [`configuration.md`](./configuration.md).

---

## Resources

- **Official Servers**: <https://github.com/modelcontextprotocol/servers>
- **Awesome MCP** (community list): <https://github.com/punkpeye/awesome-mcp-servers>
- **MCP Registry**: <https://github.com/modelcontextprotocol/registry>
- **MCP Directory**: <https://mcpservers.org/>
- **MCP Spec**: <https://spec.modelcontextprotocol.io/>
- **Inspector**: <https://github.com/modelcontextprotocol/inspector>

---

## Contributing

Submit your MCP server to the community:
1. Publish to npm or PyPI with a clear README, install command, and tool surface
2. Submit to the official MCP registry
3. Add to Awesome MCP Servers
4. List on `mcpservers.org`
5. Share in the MCP Discord / GitHub Discussions

See [`building.md`](./building.md) for the build, test, and publish walkthrough.

---

**Last Updated**: 2026-06-11

**Total Servers**: 35+ across 11 categories
