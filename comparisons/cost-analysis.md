# Cost Analysis

Cost breakdown across AI coding tools. Per-token pricing, subscription vs API, free tiers, hidden costs, engineer-hour framing.

Last updated 2026-05.

---

## Table of Contents

- [The Three Cost Models](#the-three-cost-models)
- [API Pricing](#api-pricing)
- [Subscription Pricing](#subscription-pricing)
- [Free Tiers](#free-tiers)
- [What the Models Actually Cost in Practice](#what-the-models-actually-cost-in-practice)
- [Cost-Per-Engineer-Hour Framing](#cost-per-engineer-hour-framing)
- [Hidden Costs](#hidden-costs)
- [Cost Controls](#cost-controls)
- [Total-Cost-of-Ownership Scenarios](#total-cost-of-ownership-scenarios)
- [Caveats](#caveats)

---

## The Three Cost Models

AI coding tools price one of three ways:

1. **Per-token API.** Claude Code, Gemini CLI, custom (LangChain etc.) — you pay the LLM provider directly. Scales with usage.
2. **Per-seat subscription.** GitHub Copilot, Cursor, Cody, JetBrains AI — flat monthly fee per developer, model API costs included in the subscription.
3. **Hybrid.** Cursor and Cody have subscription tiers that include a quota; past the quota, you pay per-token or upgrade tier.

Each model has different operating characteristics:
- API: predictable per-call cost; total can spike under agent workloads.
- Subscription: predictable monthly; pays for itself fast at heavy use, expensive at light use.
- Hybrid: best of both for moderate use; worst of both at extremes.

---

## API Pricing

### Anthropic (May 2026)

| Model | Input $/Mtok | Output $/Mtok | Cache hit | Cache write (5m / 1h) |
|-------|--------------|---------------|-----------|------------------------|
| Haiku 4.5 | $1.00 | $5.00 | $0.10 | $1.25 / $2.00 |
| Sonnet 4.6 | $3.00 | $15.00 | $0.30 | $3.75 / $6.00 |
| Opus 4.7 (≤200K context) | $15.00 | $75.00 | $1.50 | $18.75 / $30.00 |
| Opus 4.7 (>200K context, 1M tier) | $30.00 | $150.00 | $3.00 | $37.50 / $60.00 |

Batch API: 50% discount, ~24h turnaround.

### OpenAI (May 2026)

| Model | Input $/Mtok | Output $/Mtok | Cached input |
|-------|--------------|---------------|--------------|
| GPT-5 Nano | $0.10 | $0.40 | $0.05 |
| GPT-5 Mini | $0.25 | $2.00 | $0.125 |
| GPT-5 | $1.25 | $10.00 | $0.625 |
| GPT-5 Codex | $1.25 | $10.00 | $0.625 |
| o3 | $2.00 | $8.00 | $1.00 |
| o3-mini | $1.10 | $4.40 | $0.55 |

Batch API: 50% discount, 24h.

### Google (May 2026)

| Model | Input $/Mtok | Output $/Mtok | Context cache |
|-------|--------------|---------------|---------------|
| Gemini 2.5 Flash-Lite | $0.10 | $0.40 | implicit free |
| Gemini 2.5 Flash | $0.30 | $2.50 | implicit free |
| Gemini 2.5 Pro (≤200K) | $1.25 | $10.00 | implicit free |
| Gemini 2.5 Pro (>200K) | $2.50 | $15.00 | implicit free |

Explicit Context Caching: small write fee + storage cost; ~85% off on hit.

### Others

| Provider | Model | Input | Output | Notes |
|----------|-------|-------|--------|-------|
| Mistral | Large 3 | $2 | $6 | Open weights also available |
| Mistral | Codestral 25.05 | $1 | $3 | Code-focused |
| DeepSeek | V3.5 | $0.50 | $1.50 | Excellent value |
| Cohere | Command R+ | $2.50 | $10 | RAG-friendly |
| Groq / Cerebras / SambaNova | Llama 4 / Mixtral / others | $0.20-$0.80 | $0.20-$1.50 | Inference accelerators; high TPOT |

---

## Subscription Pricing

### GitHub Copilot (May 2026)

| Plan | Price | Includes |
|------|-------|----------|
| Free | $0 | 2K completions/mo, 50 chat msgs/mo |
| Pro | $10/mo or $100/yr | Unlimited completions, GPT-5 chat, agent mode |
| Pro+ | $39/mo | + premium models, Workspace |
| Business | $19/user/mo | Org policies, content exclusions, audit |
| Enterprise | $39/user/mo | + custom models, knowledge bases, fine-tuning |

### Cursor (May 2026)

| Plan | Price | Includes |
|------|-------|----------|
| Free / Hobby | $0 | 50 slow premium requests/mo, 2K completions |
| Pro | $20/mo | 500 fast premium requests/mo, unlimited slow, GPT-5 / Sonnet / Gemini |
| Ultra | $200/mo | 1000+ fast requests, priority access, all models |
| Business | $40/user/mo | Org SSO, admin controls, privacy mode default |
| Enterprise | Custom | Volume + procurement |

"Premium request" = full-quality model call (Sonnet 4.6 / GPT-5 / Gemini 2.5 Pro). Composer agent runs typically consume 3-15 premium requests per task.

### Sourcegraph Cody (May 2026)

| Plan | Price | Includes |
|------|-------|----------|
| Free | $0 | 200 autocompletes/day, 20 chats/day |
| Pro | $9/user/mo | Unlimited completions, Sonnet 4.6, Gemini 2.5 Pro |
| Enterprise | Custom | Multi-repo, BYOK, self-host, audit |

### JetBrains AI Assistant (May 2026)

| Plan | Price | Includes |
|------|-------|----------|
| Free | $0 | Limited daily quota |
| Pro | $10/user/mo | Multi-model, integrated with IDE |
| Enterprise | Custom | |

### Codeium / Windsurf (May 2026)

| Plan | Price | Includes |
|------|-------|----------|
| Free | $0 | Unlimited autocomplete, Cascade agent (limited) |
| Pro | $15/user/mo | Premium models, Cascade unlimited |
| Teams | $35/user/mo | Admin, BYOK |
| Enterprise | Custom | Self-host option |

### Claude Code (May 2026)

Claude Code is the CLI; there's no Claude Code subscription. You pay either:

- **Per-token via API:** standard Anthropic pricing above.
- **Via Claude.ai subscription:** Pro ($20/mo) or Max ($200/mo or $100/mo for 5x) includes Claude Code usage with caps.
  - Pro: ~45 prompts per 5h window in Sonnet 4.6
  - Max 5x: ~225 prompts / 5h in Sonnet, ~50 in Opus
  - Max 20x: ~900 prompts / 5h in Sonnet, ~200 in Opus
- **Anthropic Enterprise / API direct billing:** no per-prompt cap, billed metered.

The Max 5x ($100/mo) tier hits the sweet spot for heavy individual users — equivalent API usage would often exceed that.

---

## Free Tiers

Useful free tiers as of May 2026:

| Tool | Free quota | Limitations |
|------|------------|-------------|
| GitHub Copilot Free | 2K completions/mo + 50 chat | Recent change; was unlimited for OSS maintainers |
| Cursor Free | 50 slow / 2K completions / mo | Slow tier uses GPT-4o-mini class |
| Cody Free | 200 completes/day + 20 chats/day | |
| Codeium Free | Unlimited completions | Premium models limited |
| Gemini CLI | 60 requests / min on free Vertex tier | Plus generous AI Studio free tier |
| Anthropic API | $5 trial credit | One-time |
| OpenAI API | none typically; $5 trial sometimes | |
| Tabnine Free | Local AI completions only | |

For learning / hobbyist work, Cursor Free + Gemini CLI free tier + Anthropic trial gets you very far.

---

## What the Models Actually Cost in Practice

Per-developer monthly cost ranges based on usage patterns:

### Light user (occasional chat, some completion)

- Copilot Pro: $10
- Cursor Pro: $20 (or Free if you tolerate the slow tier)
- Claude Code via API: $5-15
- Gemini CLI via API: $2-10

**Light total: $10-30/mo per dev.** A Copilot Pro sub usually wins.

### Heavy individual user (daily multi-hour AI sessions, agent work)

- Copilot Pro: $10 (but Pro is rate-limited under load; Pro+ at $39 better)
- Cursor Ultra: $200 (or Pro $20 if you stay under 500 premium req/mo)
- Claude Code via Claude.ai Max 5x: $100
- Claude Code via API: $50-300

**Heavy total: $100-500/mo per dev.** Pick based on workflow style. Cursor Ultra + Claude Code Max ($300 combined) covers nearly all use cases for one dev.

### Agent fleet / background workloads

- API spend dominates. Per-agent costs:
  - Triage bot (10 calls/day, Sonnet): ~$5/mo
  - Daily PR review bot (50 PRs/day, Sonnet): ~$30-100/mo
  - Continuous integration agent (1000 invocations/day, Haiku + occasional Sonnet): ~$50-300/mo
- Plus: governance platform ($300-3000/mo at scale; see [agent-governance.md](../best-practices/agent-governance.md))
- Plus: orchestration infra (Temporal, Inngest, custom) — $100-1000/mo

**Fleet total: $500-10000/mo depending on scale.**

### Team of 10 developers

- Copilot Business: $190/mo
- Cursor Business: $400/mo
- Claude Code API (shared, ~$30/dev average): $300/mo
- Plus governance / observability if production agents: $500-3000/mo

**Team of 10: $1000-5000/mo all-in** for tools + minimal infra.

### Team of 100 developers

- Copilot Enterprise: $3900/mo
- Cursor Business: $4000/mo (consider Enterprise tier negotiation)
- Claude Code API + governance + observability + custom agents: $5000-30000/mo

**Team of 100: $15000-50000/mo all-in** depending on workload depth.

---

## Cost-Per-Engineer-Hour Framing

Right framing for tool spend.

Fully loaded cost per engineer-hour:

| Comp band | Salary | Total comp (1.5x) | $/hour (2000h/yr) |
|-----------|--------|-------------------|---------------------|
| Junior | $80K | $120K | $60 |
| Mid | $150K | $225K | $112 |
| Senior | $200K | $300K | $150 |
| Staff | $300K | $450K | $225 |
| Principal | $400K | $600K | $300 |

Time saved required to break even on AI tool spend:

| Tool spend / dev / mo | Hours saved required (senior) |
|------------------------|--------------------------------|
| $10 (Copilot Pro) | 4 minutes |
| $20 (Cursor Pro) | 8 minutes |
| $100 (Claude Code Max 5x) | 40 minutes |
| $200 (Cursor Ultra) | 80 minutes |
| $500 (heavy combined) | 3.3 hours |
| $1000 (very heavy) | 6.7 hours |

Almost any AI tool subscription pays back if it saves any meaningful time. Studies (GitHub, GitClear, McKinsey, others, 2023-2025) show 20-55% productivity gains on supported tasks for users who internalize the workflow. Even 10% on a 40-hour week is 4 hours — far exceeding any tool sub cost.

The math fails when:
- The tool produces worse code that costs more time to debug than it saved to write.
- The tool encourages over-generation (verbose, not what you wanted) that costs review time.
- The developer doesn't internalize the workflow and never gets the speedup.

These are real failure modes, but they're addressable through training and tool choice, not by spending less.

---

## Hidden Costs

Real costs that don't show on the invoice:

### Orchestration infrastructure

If you run agents in production:
- Compute for agent processes (containers, Lambdas, K8s pods): $100-5000/mo depending on volume
- Message queues / task brokers (SQS, Redis, Kafka): $50-500/mo
- State storage (Postgres for agent state, vector DB for memory): $50-2000/mo
- Networking (load balancers, egress): $20-500/mo

Typical agent fleet infra: $500-3000/mo all-in for a small production deployment.

### Observability and evaluation

- LLM observability (LangSmith, Phoenix Cloud, Langfuse Cloud, Helicone): $50-1000/mo
- Eval suite compute (running evals = LLM calls): $50-2000/mo
- General observability (Datadog, Honeycomb) for tracing: $100-2000/mo

### Governance

For production agent fleets, governance is real cost. See [agent-governance.md](../best-practices/agent-governance.md).

- Managed governance (Veriswarm, Credal, others): $50-3000/mo depending on tier
- DIY governance: 6-12 engineer-months initial + 1-2 engineers ongoing — typically $200K-$500K/year fully loaded

### Storage of artifacts

- Audit logs (S3, Object Lock): $20-500/mo for low volume, $500-5000/mo for high
- Vector DB for memory / RAG (Pinecone, Weaviate, pgvector): $50-2000/mo
- Cache layers (Redis, CDN): $20-500/mo

### Compliance attestation

If you're going for SOC 2 / HIPAA / ISO 42001:
- Initial audit: $20-80K
- Annual recertification: $15-40K
- Tools and consultants: $10-50K
- Internal engineer time: 1-3 months across multiple folks

These costs exist whether or not AI is in the picture, but AI usage adds scope.

### Training and adoption

Underrated. A team that doesn't use the tool well wastes the spend.
- Training time per developer: 5-20 hours initial, ongoing learning
- Internal documentation, CLAUDE.md / .cursorrules curation: 10-40 hours per repo
- Sharing best practices, internal show-and-tell: ~1 hour/week
- Workflow iteration: ongoing

---

## Cost Controls

How to keep spend predictable.

### At the provider level

- **Spend limits.** Anthropic, OpenAI, Google all let you cap monthly spend per key.
- **Rate limits.** Lower the per-minute / per-day budget for non-critical workloads.
- **Alerts.** Set notifications at 50%, 80%, 100% of monthly budget.
- **Per-environment keys.** Dev / staging / prod isolated so a runaway dev script doesn't eat prod budget.

### At the application level

- **Token budgets per call.** Reject prompts past a size threshold.
- **Per-agent spend caps.** Halt the agent at $X per session.
- **Per-user spend caps.** Especially for end-user-facing copilots.
- **Per-feature kill switches.** Disable optional AI features under cost pressure.

### At the prompt level

- **Cheaper tier for routing / classification.** Haiku 4.5 routes; Sonnet 4.6 does the work.
- **Cache aggressively.** See [performance.md](../best-practices/performance.md) — cache hits can cut spend 70-85%.
- **Batch API** for non-urgent — 50% off.
- **Smaller context.** Don't paste lockfiles. See [context-management.md](../best-practices/context-management.md).

### Observability

- Track $/task at the team level. If a feature jumps 3x in cost without a usage jump, investigate.
- Anomaly detection on per-agent spend. A buggy retry loop will burn money fast.
- Weekly cost review for production agents.

---

## Total-Cost-of-Ownership Scenarios

End-to-end TCO for common deployments:

### Solo developer, side project

- Cursor Pro: $20/mo
- Claude Code via Anthropic Pro: $20/mo
- (Maybe) Gemini AI Studio: free tier
- Storage / hosting (Vercel, Supabase, etc.): $20-50/mo

**TCO: $60-90/mo.**

### Small startup, 5 engineers, no production agents

- Cursor Business x5: $200/mo
- Claude Code API shared: $100-200/mo
- Observability (free tiers initially): $0
- LLM provider account fees: $0

**TCO: $300-400/mo.**

### Growing startup, 25 engineers, some production agents

- Cursor Business x25: $1000/mo
- Copilot Business x25 (alongside Cursor): $475/mo
- Claude Code API: $500-1500/mo
- Production agent API spend: $500-3000/mo
- Observability (LangSmith Pro): $200-500/mo
- Vector DB (Pinecone Standard): $200/mo
- Compute (small K8s cluster, agents): $500-2000/mo

**TCO: $3000-9000/mo.**

### Mid-size company, 100 engineers, production agent fleet, regulated industry

- Copilot Enterprise x100: $3900/mo
- Cursor Business x100: $4000/mo
- Claude Code API: $3000-10000/mo
- Production agent API spend: $5000-30000/mo
- Observability (LangSmith Enterprise): $1000-3000/mo
- Governance (Veriswarm Max or Enterprise): $300-5000/mo
- Vector DB / cache / storage: $1000-3000/mo
- Compute infra for agents: $2000-10000/mo
- Compliance overhead (amortized): $5000-15000/mo

**TCO: $25000-85000/mo.**

### Large enterprise, 1000+ engineers

Beyond the scope of public pricing. Negotiate enterprise contracts with each vendor; expect ~30-50% off list at this scale. TCO typically $200K-$1M/mo all-in for tools + infra + governance + compliance.

---

## Caveats

- **Prices move.** Cuts in Q1 2026 dropped Sonnet 4.6 input from $5 → $3. Expect further movement.
- **New tiers appear.** GPT-5 Mini and Gemini 2.5 Flash-Lite were created to address cost-sensitive workloads.
- **Provider credits / discounts.** Negotiate. Most providers offer 10-30% off at $50K+ annual.
- **Region pricing.** Vertex AI region pricing varies slightly; EU sometimes higher.
- **Currency.** All USD. EUR / GBP pricing typically tracks with FX adjustment.
- **Per-seat sub tools change quotas.** Cursor's "premium request" definition has shifted multiple times in 2024-2025. Read the fine print before committing a large team.

The number that matters is **cost per delivered task or feature**, not the API rate card. A $0.50 task with Opus that ships in 5 minutes beats a $0.05 task with Haiku that takes 45 minutes of human follow-up to fix.

---

## Related

- [Feature Matrix](feature-matrix.md)
- [Use Cases](use-cases.md)
- [Performance Comparison](performance.md)
- [Performance Best Practices](../best-practices/performance.md)
- [Agent Governance](../best-practices/agent-governance.md)
