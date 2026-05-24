# MCP Server Catalog

Comprehensive catalog of Model Context Protocol (MCP) servers for extending Claude Code and other AI assistants.

> **Last updated**: 2026-05-24 · Tracks MCP spec **2025-06-18**.

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
**Package**: `@modelcontextprotocol/server-github` (legacy stdio) · official hosted server at `https://api.githubcopilot.com/mcp/` (recommended)

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
    "transport": "http",
    "url": "https://api.githubcopilot.com/mcp/"
  }
}
```

**Installation (stdio)**:
```json
{
  "github": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github@2025.11.0"],
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
**Package**: `@modelcontextprotocol/server-filesystem` · current `2025.11.0`

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
    "args": ["-y", "@modelcontextprotocol/server-filesystem@2025.11.0", "/path/to/project"]
  }
}
```

**Use Cases**:
- Complex file operations
- Multi-file edits
- Directory restructuring

---

### Git MCP
**Package**: `mcp-server-git` (Python, via `uvx`) · current `2025.11.0`

**Features**:
- Git operations (status, log, diff, show, add, commit, branch)
- Repository inspection
- Read-only by default; write tools opt-in

**Installation**:
```json
{
  "git": {
    "command": "uvx",
    "args": ["mcp-server-git==2025.11.0", "--repository", "/path/to/repo"]
  }
}
```

---

### Memory MCP
**Package**: `@modelcontextprotocol/server-memory` · current `2025.11.0`

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
    "args": ["-y", "@modelcontextprotocol/server-memory@2025.11.0"],
    "env": {"MEMORY_FILE_PATH": "/path/to/memory.json"}
  }
}
```

**Use Cases**:
- Multi-session projects
- State persistence
- Context preservation

---

### Sequential Thinking MCP
**Package**: `@modelcontextprotocol/server-sequential-thinking` · current `2025.11.0`

**Features**:
- Structured reasoning scratchpad
- Revisable thought chains
- Branching exploration of alternatives

**Installation**:
```json
{
  "sequential-thinking": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-sequential-thinking@2025.11.0"]
  }
}
```

---

## Databases

### PostgreSQL MCP
**Package**: `@modelcontextprotocol/server-postgres` · current `1.4.0`

**Features**:
- Parameterized SQL queries
- Schema inspection (tables, columns, indexes)
- Read-only mode by default
- Connection pooling

**Installation**:
```json
{
  "postgres": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-postgres@1.4.0"],
    "env": {"POSTGRES_CONNECTION_STRING": "${POSTGRES_CONNECTION_STRING}"}
  }
}
```

---

### SQLite MCP
**Package**: `mcp-server-sqlite` (Python) · current `2025.11.0`

**Features**:
- SQLite database operations
- Local data storage
- Schema and index inspection

**Installation**:
```json
{
  "sqlite": {
    "command": "uvx",
    "args": ["mcp-server-sqlite==2025.11.0", "--db-path", "/path/to/database.db"]
  }
}
```

---

### MongoDB MCP
**Package**: `mongodb-mcp-server` (official, MongoDB Inc.) · current `1.6.0`

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
    "args": ["-y", "mongodb-mcp-server@1.6.0"],
    "env": {"MDB_MCP_CONNECTION_STRING": "${MONGODB_URI}"}
  }
}
```

---

### Neon MCP
**Package**: hosted at `https://mcp.neon.tech/sse`

**Features**:
- Serverless Postgres branching
- Project + branch + database management
- Direct SQL execution
- One-click query inspector integration

**Installation**:
```json
{
  "neon": {
    "transport": "http",
    "url": "https://mcp.neon.tech/sse"
  }
}
```

---

### Supabase MCP
**Package**: `@supabase/mcp-server-supabase` · current `0.6.0`

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
    "args": ["-y", "@supabase/mcp-server-supabase@0.6.0", "--access-token", "${SUPABASE_ACCESS_TOKEN}"]
  }
}
```

---

## Infrastructure

### Kubernetes MCP
**Package**: `kubernetes-mcp-server` (containers.io) · current `0.6.0`

**Features**:
- kubectl operations (pods, deployments, services, configmaps, secrets)
- Helm chart operations
- Multi-cluster (kubeconfig context switching)
- Apply / patch / delete with explicit confirmation

**Installation**:
```json
{
  "kubernetes": {
    "command": "docker",
    "args": ["run", "-i", "--rm", "-v", "~/.kube:/home/mcp/.kube:ro",
             "quay.io/containers/kubernetes-mcp-server:0.6.0"]
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
**Package**: `terraform-mcp-server` (HashiCorp) · current `0.4.0`

**Features**:
- Terraform plan/apply with diff summaries
- State inspection
- Registry module search
- Workspace and variable management

**Installation**:
```json
{
  "terraform": {
    "command": "npx",
    "args": ["-y", "terraform-mcp-server@0.4.0"]
  }
}
```

---

### Cloudflare MCP
**Package**: hosted at `https://mcp.cloudflare.com/`

**Features**:
- Workers deployment
- KV / R2 / D1 / Queues admin
- DNS and zone management
- Analytics + observability queries

**Installation**:
```json
{
  "cloudflare": {
    "transport": "http",
    "url": "https://mcp.cloudflare.com/"
  }
}
```

---

## Quality & Testing

### Playwright MCP
**Package**: `@playwright/mcp` · current `0.4.0`

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
    "args": ["-y", "@playwright/mcp@0.4.0"]
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
**Package**: `mcp-code-checker` · current `1.0.0`

**Features**:
- pylint integration
- pytest execution with structured output
- Coverage reports
- LLM-friendly result summaries

**Installation**:
```bash
uvx mcp-code-checker==1.0.0
```

---

### Ruff MCP Server
**Package**: `ruff-mcp-server` · current `0.3.0`

**Features**:
- Fast Python linting and formatting
- Import sorting
- Rule explanations
- Auto-fix where supported

**Installation**:
```json
{
  "ruff": {
    "command": "uvx",
    "args": ["ruff-mcp-server==0.3.0"]
  }
}
```

---

### Semgrep MCP
**Package**: `semgrep-mcp-server` · current `0.5.0`

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
    "args": ["semgrep-mcp-server==0.5.0"]
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
    "transport": "http",
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

### Mintlify Documentation MCP
**Package**: `@mintlify/mcp` · current `0.4.0`

**Features**:
- Generate docs from code
- API reference scaffolding
- Markdown conversion
- Mintlify hosting integration

---

### MarkItDown MCP (Microsoft)
**Package**: `markitdown-mcp` · current `0.1.0`

**Features**:
- PDF / DOCX / PPTX / XLSX → Markdown
- HTML → Markdown
- Image OCR
- ZIP-archive batch conversion

**Installation**:
```bash
uvx markitdown-mcp==0.1.0
```

---

### MCP Documentation Service
**Package**: `mcp-docs-service` · current `0.7.0`

**Features**:
- Markdown management
- Frontmatter metadata
- Navigation generation
- Documentation aggregation

---

## Web & APIs

### Puppeteer MCP
**Package**: `@modelcontextprotocol/server-puppeteer` · current `2025.11.0`

**Note**: For new projects prefer the **Playwright MCP** above — broader browser support and more stable accessibility-tree interaction.

**Features**:
- Headless Chromium automation
- Screenshot capture
- Form filling
- Web scraping

**Installation**:
```json
{
  "puppeteer": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-puppeteer@2025.11.0"]
  }
}
```

---

### Brave Search MCP
**Package**: `@modelcontextprotocol/server-brave-search` · current `2025.11.0`

**Features**:
- Web search via Brave Search API
- Local / image / news search
- No tracking; independent index

**Installation**:
```json
{
  "brave-search": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-brave-search@2025.11.0"],
    "env": {"BRAVE_API_KEY": "${BRAVE_API_KEY}"}
  }
}
```

---

### Fetch MCP
**Package**: `mcp-server-fetch` (Python) · current `2025.11.0`

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
    "args": ["mcp-server-fetch==2025.11.0"]
  }
}
```

---

### Firecrawl MCP
**Package**: `firecrawl-mcp` · current `1.4.0`

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
    "args": ["-y", "firecrawl-mcp@1.4.0"],
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
    "transport": "http",
    "url": "https://mcp.notion.com/mcp"
  }
}
```

---

### Linear MCP
**Package**: hosted at `https://mcp.linear.app/mcp` · also `@linear/mcp-server` for stdio

**Features**:
- Issue lifecycle (create / update / assign / close)
- Project + cycle management
- Search across teams
- Triage workflows

**Installation (hosted)**:
```json
{
  "linear": {
    "transport": "http",
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
    "transport": "http",
    "url": "https://mcp.atlassian.com/v1/sse"
  }
}
```

---

### Sentry MCP
**Package**: hosted at `https://mcp.sentry.dev/sse`

**Features**:
- Issue + event inspection
- Stacktrace + breadcrumb retrieval
- Release tracking
- Project + team admin

**Installation**:
```json
{
  "sentry": {
    "transport": "http",
    "url": "https://mcp.sentry.dev/sse"
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
    "transport": "http",
    "url": "https://mcp.stripe.com/"
  }
}
```

---

## Cloud Services

### AWS MCP
**Package**: `aws-mcp-server` (community) · also `awslabs/mcp` collection for service-specific servers

**Features**:
- S3, Lambda, EC2, IAM, CloudFormation, ECS, RDS via per-service MCPs
- CloudWatch logs + metrics queries
- Cost Explorer integration
- SSO + profile-based auth

**Installation (example, S3)**:
```json
{
  "aws-s3": {
    "command": "uvx",
    "args": ["awslabs.s3-mcp-server@0.3.0"],
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
**Package**: `azure-mcp-server` (Microsoft) · current `0.5.0`

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
    "args": ["-y", "azure-mcp-server@0.5.0"]
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
    "transport": "http",
    "url": "https://mcp.vercel.com/"
  }
}
```

---

### Replicate MCP
**Package**: `@replicate/mcp` · current `0.3.0`

**Features**:
- Model inference (image, video, audio, LLM)
- Prediction tracking
- Model search
- Output streaming

**Installation**:
```json
{
  "replicate": {
    "command": "npx",
    "args": ["-y", "@replicate/mcp@0.3.0"],
    "env": {"REPLICATE_API_TOKEN": "${REPLICATE_API_TOKEN}"}
  }
}
```

---

## Communication

### Slack MCP
**Package**: `@modelcontextprotocol/server-slack` · current `2025.11.0`

**Features**:
- Send messages (channels + DMs)
- Channel + user lookup
- Message history search
- File uploads

**Installation**:
```json
{
  "slack": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-slack@2025.11.0"],
    "env": {
      "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
      "SLACK_TEAM_ID": "${SLACK_TEAM_ID}"
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

### Pandas MCP
**Package**: `mcp-server-pandas` · current `0.3.0`

**Features**:
- DataFrame operations
- CSV / Excel / Parquet I/O
- Statistical summaries
- Plot generation

**Installation**:
```bash
uvx mcp-server-pandas==0.3.0
```

**Use Cases**:
- Ad-hoc data exploration
- Report generation
- Data cleaning pipelines

---

### Jupyter MCP
**Package**: `jupyter-mcp-server` · current `0.5.0`

**Features**:
- Notebook execution against running Jupyter kernel
- Cell add / edit / delete
- Output capture (text, images, plots)
- Multi-notebook workspace

---

### ClickHouse MCP
**Package**: `mcp-clickhouse` · current `0.3.0`

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
    "args": ["mcp-clickhouse==0.3.0"],
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
    "transport": "http",
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
**Package**: `arize-phoenix-mcp` · current `0.2.0` · OSS

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
    "command": "uvx",
    "args": ["arize-phoenix-mcp==0.2.0"],
    "env": {"PHOENIX_COLLECTOR_ENDPOINT": "http://localhost:6006"}
  }
}
```

**Website**: <https://phoenix.arize.com>

---

### Patronus AI
**Package**: `patronus-mcp` · current `0.3.0`

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
      "transport": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem@2025.11.0", "/path/to/projects"]
    },
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git==2025.11.0", "--repository", "/path/to/repo"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory@2025.11.0"],
      "env": {"MEMORY_FILE_PATH": "/path/to/memory.json"}
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres@1.4.0"],
      "env": {"POSTGRES_CONNECTION_STRING": "${POSTGRES_CONNECTION_STRING}"}
    },
    "context7": {
      "transport": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {"Authorization": "Bearer ${CONTEXT7_API_KEY}"}
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@0.4.0"]
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

**Last Updated**: 2026-05-24

**Total Servers**: 35+ across 11 categories
