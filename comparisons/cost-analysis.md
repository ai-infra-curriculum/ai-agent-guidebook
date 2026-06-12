# Cost Analysis

Cost breakdown across AI coding tools. Per-token pricing, subscription vs API, free tiers, hidden costs, engineer-hour framing.

Last updated 2026-06-11.

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

### Anthropic (June 2026)

| Model | Input $/Mtok | Output $/Mtok | Cache hit | Cache write (5m / 1h) |
|-------|--------------|---------------|-----------|------------------------|
| Haiku 4.5 | $1.00 | $5.00 | $0.10 | $1.25 / $2.00 |
| Sonnet 4.6 | $3.00 | $15.00 | $0.30 | $3.75 / $6.00 |
| Opus 4.8 (also 4.7/4.6/4.5) | $5.00 | $25.00 | $0.50 | $6.25 / $10.00 |
| Fable 5 | $10.00 | $50.00 | $1.00 | $12.50 / $20.00 |

Fable 5, Opus 4.8/4.7/4.6, and Sonnet 4.6 include the full 1M context window at standard pricing — there is no >200K surcharge. (The $30/$150 rate exists only as Opus fast-mode pricing.) Legacy Opus 4.1/4 are deprecated at $15/$75.

Batch API: 50% discount, ~24h turnaround.

### OpenAI (June 2026)

| Model | Input $/Mtok | Output $/Mtok | Cached input |
|-------|--------------|---------------|--------------|
| GPT-5.4 Nano | $0.20 | $1.25 | $0.02 |
| GPT-5.4 Mini | $0.75 | $4.50 | $0.075 |
| GPT-5.4 | $2.50 | $15.00 | $0.25 |
| GPT-5.5 | $5.00 | $30.00 | $0.50 |

Cached input is 90% off across the lineup. GPT-5.5 and GPT-5.4 are the current flagships; the original GPT-5 family and o3 are previous-gen.

Batch API: 50% discount, 24h.

### Google (June 2026)

| Model | Input $/Mtok | Output $/Mtok | Context cache |
|-------|--------------|---------------|---------------|
| Gemini 3.1 Pro (≤200K) | $2.00 | $12.00 | cached input $0.20 (90% off) |
| Gemini 3.1 Pro (>200K) | $4.00 | $18.00 | 90% off on cached input |
| Gemini 2.5 Flash-Lite (previous gen) | $0.10 | $0.40 | implicit free |
| Gemini 2.5 Flash (previous gen) | $0.30 | $2.50 | implicit free |
| Gemini 2.5 Pro (previous gen, ≤200K) | $1.25 | $10.00 | implicit free |
| Gemini 2.5 Pro (previous gen, >200K) | $2.50 | $15.00 | implicit free |

Gemini 3.1 Pro carries a 1M context window. Gemini 3.5 Flash shipped May 2026 as the current fast tier — check current rates before committing volume. Explicit Context Caching: small write fee + storage cost.

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

### GitHub Copilot (June 2026)

| Plan | Price | Includes |
|------|-------|----------|
| Free | $0 | 2K completions/mo, 50 chat msgs/mo |
| Pro | $10/mo or $100/yr | Unlimited completions, chat, agent mode, coding agent |
| Pro+ | $39/mo | + larger AI Credit allowance, premium models |
| Business | $19/user/mo | Org policies, content exclusions, audit |
| Enterprise | $39/user/mo | + custom models, knowledge bases, fine-tuning |

As of June 1, 2026, metered usage is billed via **GitHub AI Credits**, which replaced the premium-requests system. Each plan includes a credit allowance; overages draw on credits. (Copilot Workspace was sunset May 30, 2025 — the coding agent is its successor for spec-to-PR flows.)

### Cursor (June 2026)

| Plan | Price | Includes |
|------|-------|----------|
| Free / Hobby | $0 | Limited model usage, 2K completions |
| Pro | $20/mo | Included usage allowance for frontier models (GPT-5.5 / Sonnet 4.6 / Gemini 3.1 Pro) |
| Ultra | $200/mo | ~20x Pro's usage allowance, priority access, all models |
| Business | $40/user/mo | Org SSO, admin controls, privacy mode default |
| Enterprise | Custom | Volume + procurement |

Cursor moved from counted "fast premium requests" to **usage-based pricing** in mid-2025: plans include a usage allowance priced at model API rates, and agent runs draw it down. Heavy Composer/agent use burns through the Pro allowance quickly.

### Sourcegraph Cody (June 2026)

| Plan | Price | Includes |
|------|-------|----------|
| Free | $0 | 200 autocompletes/day, 20 chats/day |
| Pro | $9/user/mo | Unlimited completions, Sonnet 4.6, Gemini 2.5 Pro |
| Enterprise | Custom | Multi-repo, BYOK, self-host, audit |

### JetBrains AI Assistant (June 2026)

| Plan | Price | Includes |
|------|-------|----------|
| Free | $0 | Limited daily quota |
| Pro | $10/user/mo | Multi-model, integrated with IDE |
| Enterprise | Custom | |

### Windsurf (formerly Codeium; acquired by Cognition) (June 2026)

| Plan | Price | Includes |
|------|-------|----------|
| Free | $0 | Unlimited autocomplete, Cascade agent (limited) |
| Pro | $15/user/mo | Premium models, Cascade unlimited |
| Teams | $35/user/mo | Admin, BYOK |
| Enterprise | Custom | Self-host option |

### Claude Code (June 2026)

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

Useful free tiers as of June 2026:

| Tool | Free quota | Limitations |
|------|------------|-------------|
| GitHub Copilot Free | 2K completions/mo + 50 chat | Recent change; was unlimited for OSS maintainers |
| Cursor Free | Limited usage / 2K completions / mo | Free tier uses smaller-model class |
| Cody Free | 200 completes/day + 20 chats/day | |
| Windsurf Free | Unlimited completions | Premium models limited |
| Gemini CLI | 60 req/min + 1,000 req/day with a personal Google account (Code Assist license) | Plus generous AI Studio free tier |
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

- Copilot Pro: $10 (but Pro's AI Credit allowance runs out under load; Pro+ at $39 better)
- Cursor Ultra: $200 (or Pro $20 if you stay within the included usage allowance)
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

- **Prices move.** The big recent cut was Opus: $15/$75 dropped to $5/$25 with Opus 4.5 in November 2025. (Sonnet input has been $3 since Sonnet 3.5.) Expect further movement.
- **New tiers appear.** GPT-5.4 Mini/Nano and the Gemini Flash tiers exist to address cost-sensitive workloads.
- **Provider credits / discounts.** Negotiate. Most providers offer 10-30% off at $50K+ annual.
- **Region pricing.** Vertex AI region pricing varies slightly; EU sometimes higher.
- **Currency.** All USD. EUR / GBP pricing typically tracks with FX adjustment.
- **Per-seat sub tools change quotas.** Cursor's pricing model shifted multiple times in 2024-2025 (counted premium requests → usage-based), and GitHub moved Copilot metering to AI Credits in June 2026. Read the fine print before committing a large team.

The number that matters is **cost per delivered task or feature**, not the API rate card. A $0.50 task with Opus that ships in 5 minutes beats a $0.05 task with Haiku that takes 45 minutes of human follow-up to fix.

---

## Related

- [Feature Matrix](feature-matrix.md)
- [Use Cases](use-cases.md)
- [Performance Comparison](performance.md)
- [Performance Best Practices](../best-practices/performance.md)
- [Agent Governance](../best-practices/agent-governance.md)
