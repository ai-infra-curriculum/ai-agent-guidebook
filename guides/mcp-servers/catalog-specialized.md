# MCP Server Catalog — Productivity, Cloud, Communication, Data & Governance

Second half of the MCP server catalog. The first half — Development, Databases, Infrastructure, Quality & Testing, Documentation, Web & APIs, plus setup and configuration examples — is in [`catalog.md`](./catalog.md).

> **Last updated**: 2026-10-21 · Tracks MCP spec **2026-07-28**.
>
> **Version note**: install snippets are unpinned so they keep working as servers release; "current" versions are as of the last-updated date. Hosted servers (`"type": "http"`) authenticate with OAuth on first connect unless noted.

---

## Table of Contents

- [Productivity & Design](#productivity--design)
- [Cloud Services](#cloud-services)
- [Communication](#communication)
- [Data & Analytics](#data--analytics)
- [Agent Governance & Trust](#agent-governance--trust)

---

## Productivity & Design

### Notion MCP
**Package**: hosted **Remote Notion MCP** at `https://mcp.notion.com/mcp` (recommended)

> **Note**: the self-hosted `@notionhq/notion-mcp-server` npm package (repo [`makenotion/notion-mcp-server`](https://github.com/makenotion/notion-mcp-server)) is still published, but its README now says it is **no longer actively maintained or supported** and directs users to the remote server.

**Features**:
- Semantic search across the workspace (and connected apps)
- Read and edit pages in Markdown
- Database queries
- OAuth that respects each user's existing Notion permissions

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
**Package**: hosted-only at `https://mcp.linear.app/mcp` (Linear does not publish a stdio npm package) · read-only variant at `https://mcp.linear.app/mcp/readonly`

> **Note**: `https://mcp.linear.app/sse` is a deprecated fallback; new setups should use `/mcp`.

**Features**:
- Issue lifecycle (create / update / assign / close)
- Project + cycle management
- Search across teams
- Auth: OAuth 2.1, or a Linear API key / OAuth token as `Authorization: Bearer`

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
**Package**: hosted at `https://mcp.atlassian.com/v2/mcp` (recommended) · source/docs [`atlassian/atlassian-mcp-server`](https://github.com/atlassian/atlassian-mcp-server)

> **Note**: the legacy SSE endpoint `https://mcp.atlassian.com/v1/sse` is **no longer supported after 30 June 2026**. The `v1/mcp` endpoints remain supported and now expose the v2 tools, but Atlassian recommends `v2/mcp`.

**Features**:
- Jira issue + project management
- Confluence page CRUD + search
- JQL queries
- Cross-product linking
- OAuth 2.1 or API-token auth

**Installation**:
```json
{
  "atlassian": {
    "type": "http",
    "url": "https://mcp.atlassian.com/v2/mcp"
  }
}
```

---

### Sentry MCP
**Package**: hosted at `https://mcp.sentry.dev/mcp` · source now lives in [`getsentry/toolkit`](https://github.com/getsentry/toolkit) (alongside the Sentry CLI)

**Features**:
- Issue + event inspection
- Stacktrace + trace retrieval
- Release tracking
- Tuned for human-in-the-loop coding agents rather than full Sentry API coverage

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
**Package**: hosted at `https://mcp.stripe.com` (OAuth, or an **agent API key** as `Authorization: Bearer`) · `@stripe/mcp` (current `0.3.x`) is still published on npm, but Stripe's docs now point to the hosted server · source [`stripe/ai`](https://github.com/stripe/ai) (formerly `stripe/agent-toolkit`)

> **Note**: Stripe says that starting December 2026 its MCP server stops accepting full-access secret keys and restricted keys without the Agent tag — migrate to agent API keys or OAuth by **November 30, 2026**.

**Features**:
- Generic `stripe_api_read` / `stripe_api_write` tools over a large allowlist of API methods (customers, payments, subscriptions, invoices, products, prices, and more)
- Docs and knowledge-base search
- Human confirmation required for certain writes (e.g. refunds, outbound payments)
- OAuth consent can grant per-environment access (live mode vs. sandboxes)

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

### Figma MCP
**Package**: hosted at `https://mcp.figma.com/mcp` (Figma's recommended option) · a desktop server also runs locally through the Figma desktop app for specific organization/enterprise needs — see [Figma's MCP docs](https://developers.figma.com/docs/figma-mcp-server/)

**Features**:
- Extract design context (variables, components, layout data) and generate code from selected frames
- Code Connect mappings for consistent generated code
- Write native content to the canvas (Figma Design, FigJam, Slides) — requires the remote server and a Full seat outside drafts
- Generate editable designs from live web UI (remote server, select clients)

**Installation (hosted)**:
```json
{
  "figma": {
    "type": "http",
    "url": "https://mcp.figma.com/mcp"
  }
}
```

> Seat/plan requirements apply (the desktop server requires a Dev or Full seat on a paid plan). Check Figma's docs for your plan.

---

## Cloud Services

### AWS MCP
**Package**: the official [`awslabs/mcp`](https://github.com/awslabs/mcp) collection — dozens of per-service PyPI packages named `awslabs.<service>-mcp-server` (e.g. `awslabs.aws-documentation-mcp-server`, `awslabs.aws-iac-mcp-server`, `awslabs.s3-tables-mcp-server`)

> **Note**: servers in the collection get deprecated and replaced over time (e.g. the Cloud Control API server is marked deprecated in favor of the IaC server). Check the README's table before adopting one.

**Features**:
- Per-service servers across S3 Tables, Lambda, ECS, RDS, infrastructure-as-code, and more
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
**Package**: Google-official servers, listed in [`google/mcp`](https://github.com/google/mcp):

- **Managed remote servers** (operated by Google, enabled per project — see [Google Cloud's MCP overview](https://docs.cloud.google.com/mcp/overview)) for BigQuery, Cloud SQL (MySQL / PostgreSQL / SQL Server), AlloyDB, Spanner, Firestore, Bigtable, GKE, Compute Engine, Cloud Run, Cloud Storage, Cloud Resource Manager, and more.
- **Open-source local servers**, e.g. [`googleapis/gcloud-mcp`](https://github.com/googleapis/gcloud-mcp) (npm `@google-cloud/gcloud-mcp`, plus `observability-mcp`, `storage-mcp`, `backupdr-mcp`) and [MCP Toolbox for Databases](https://github.com/googleapis/genai-toolbox).

> The community `gcp-mcp-server` PyPI package listed here previously (last release March 2025) has been dropped in favor of Google's official servers.

**Features**:
- gcloud CLI operations in natural language (`gcloud-mcp`)
- Logs, metrics, and traces (`observability-mcp`)
- Managed data-service access without running a local server
- ADC / IAM-based auth

**Installation (example, gcloud MCP — requires Node 20+ and the gcloud CLI)**:
```json
{
  "gcloud": {
    "command": "npx",
    "args": ["-y", "@google-cloud/gcloud-mcp"]
  }
}
```

---

### Azure MCP
**Package**: `@azure/mcp` (Microsoft, official) · current `4.0.0-beta.x` (the npm `latest` tag is a beta) · source now in [`microsoft/mcp`](https://github.com/microsoft/mcp) (the old `Azure/azure-mcp` repo was archived 2025-08-25)

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

(.NET alternative per the README: `dotnet dnx Azure.Mcp server start`.)

---

### Vercel MCP
**Package**: hosted at `https://mcp.vercel.com` (OAuth) — Vercel only allows MCP clients it has reviewed and approved (Claude Code, Cursor, VS Code, Codex CLI, and others are on its list)

**Features**:
- Search Vercel documentation
- Project + deployment management, deployment logs
- Web Analytics queries (visitors, page views, custom events)

**Installation**:
```json
{
  "vercel": {
    "type": "http",
    "url": "https://mcp.vercel.com"
  }
}
```

---

## Communication

### Slack MCP
**Official**: Slack hosts an MCP server at `https://mcp.slack.com/mcp` (Streamable HTTP, confidential OAuth). It is **not** a drop-in endpoint for arbitrary clients: the MCP client must be backed by a registered Slack app (Marketplace-published or internal — unlisted apps are prohibited), Dynamic Client Registration and SSE are not supported, and workspace admins approve it through the normal app-approval process. See [Slack's MCP docs](https://docs.slack.dev/ai/slack-mcp-server/). Hosts with a built-in Slack connector use this path for you.

**Community (self-run)**: `slack-mcp-server` (npm, [`korotovsky/slack-mcp-server`](https://github.com/korotovsky/slack-mcp-server)) · current `1.3.0` · the old `@modelcontextprotocol/server-slack` reference server is **archived** and deprecated on npm

**Features (community server)**:
- Send messages (channels + DMs)
- Channel + user lookup
- Message history search
- User (`xoxp`) or bot (`xoxb`) token modes

**Installation (community server)**:
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

## Data & Analytics

### Jupyter MCP
**Package**: `jupyter-mcp-server` (PyPI, [`datalayer/jupyter-mcp-server`](https://github.com/datalayer/jupyter-mcp-server)) · current `2.2.x`

**Features**:
- Notebook execution against a running Jupyter kernel
- Cell add / edit / delete
- Output capture (text, images, plots)
- Multi-notebook workspace

---

### ClickHouse MCP
**Package**: `mcp-clickhouse` (official, [`ClickHouse/mcp-clickhouse`](https://github.com/ClickHouse/mcp-clickhouse)) · current `0.7.0`

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
**Package**: hosted Tools MCP at `https://mcp.veriswarm.ai/mcp/` · also stdio + SDK integrations for LangChain, CrewAI, AutoGen, Bedrock AgentCore, Salesforce Agentforce, Microsoft Agent 365

**Features**:
- **Trust scoring** — real-time per-call policy decisions (allow / review / deny) with explainable reasons
- **PII detection + redaction** — inbound and outbound content scanning (the hosted MCP does not support PII rehydration; use a self-hosted deployment for that)
- **Prompt-injection guard** — detection against indirect prompt injection in tool outputs
- **Passport** — portable agent identity credentials usable across frameworks
- **Vault** — hash-chained, tamper-evident audit ledger over every tool call (inputs, outputs, decisions, identities)
- **100+ tools** exposed via MCP for trust scoring, security, identity, audit, and agent operations
- **Cross-framework** — same governance layer across LangChain, CrewAI, AutoGen, Bedrock, Agentforce, Microsoft Agent 365, custom agents

**Installation (hosted)** — authenticate with OAuth 2.0 `client_credentials` (exchange your client ID/secret for an access token):
```json
{
  "veriswarm": {
    "type": "http",
    "url": "https://mcp.veriswarm.ai/mcp/",
    "headers": {"Authorization": "Bearer ${VERISWARM_ACCESS_TOKEN}"}
  }
}
```

**Pricing**:
- Free — 5,000 trust-score queries/day, up to 10 agents
- Pro — $49/mo
- Max — $299/mo
- Enterprise — custom

**Use Cases**:
- Pre-deployment policy enforcement on agent tool calls
- SOC2 / HIPAA / FINRA audit evidence for agent actions
- Cross-team agent identity (Passport carries trust score + permissions across workflows)
- Incident replay over the Vault hash chain

**Website**: <https://veriswarm.ai>

---

### LangSmith
**Package**: hosted **LangSmith Remote MCP** at `https://api.smith.langchain.com/mcp` (US; EU: `https://eu.api.smith.langchain.com/mcp`; other regions in the docs) · self-hosted LangSmith v0.15+ exposes it at `https://<your-host>/api/mcp`

> **Note**: the standalone [`langchain-ai/langsmith-mcp-server`](https://github.com/langchain-ai/langsmith-mcp-server) repo is now **archived**, and LangChain's docs mark the standalone server deprecated in favor of the Remote MCP for LangSmith Cloud.

**Features**:
- Conversation history, prompts, runs and traces
- Datasets and experiments
- Billing usage
- OAuth 2.1 for interactive clients; `X-Api-Key` header for programmatic clients

**Installation (hosted, API key)**:
```json
{
  "langsmith": {
    "type": "http",
    "url": "https://api.smith.langchain.com/mcp",
    "headers": {"X-Api-Key": "${LANGSMITH_API_KEY}"}
  }
}
```

**Docs**: <https://docs.langchain.com/langsmith/langsmith-remote-mcp>

---

### Arize Phoenix
**Package**: `@arizeai/phoenix-mcp` (npm, in the [`Arize-ai/phoenix`](https://github.com/Arize-ai/phoenix) monorepo) · current `4.3.x` · OSS

**Features**:
- OpenTelemetry-based LLM + tool tracing
- LLM evaluators (relevance, hallucination, toxicity)
- Self-hostable; no vendor lock-in
- MCP server covers projects, traces / spans / annotations, sessions, prompts, datasets, and experiments

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

See [`advanced.md`](./advanced.md#trust-and-audit-platforms) for how these platforms fit into an MCP deployment, and [`catalog.md`](./catalog.md) for the rest of the catalog, installation steps, and contribution guidelines.

**Last Updated**: 2026-10-21
