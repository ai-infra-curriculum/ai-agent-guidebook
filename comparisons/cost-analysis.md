# Cost Analysis

Cost breakdown across AI coding tools. Per-token pricing, subscription vs API, free tiers, hidden costs, engineer-hour framing.

Last updated 2026-10-21. Prices are list prices as of October 2026.

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

1. **Per-token API.** Claude Code (with a Console API key), Codex CLI (with an API key), Gemini CLI (with a paid Gemini API key), custom agents (Claude Agent SDK, LangChain, etc.) — you pay the LLM provider directly. Scales with usage.
2. **Per-seat subscription.** Claude Pro/Max/Team, ChatGPT Plus/Pro/Business (includes Codex), GitHub Copilot, Cursor — flat monthly fee per developer with a usage allowance.
3. **Hybrid.** Copilot (GitHub AI Credits) and Cursor (usage pools; third-party models billed by usage) include an allowance; past it you pay for usage or upgrade tier.

Each model has different operating characteristics:
- API: predictable per-call cost; total can spike under agent workloads.
- Subscription: predictable monthly; pays for itself fast at heavy use, expensive at light use.
- Hybrid: best of both for moderate use; worst of both at extremes.

---

## API Pricing

All prices are list prices in USD per million tokens (MTok), **as of October 2026**. Verify on the linked pages before committing volume.

### Anthropic (as of October 2026)

Source: [Claude pricing](https://platform.claude.com/docs/en/about-claude/pricing), [models overview](https://platform.claude.com/docs/en/about-claude/models/overview).

| Model (API ID) | Input | Output | Cache hit | Cache write (5m / 1h) |
|----------------|-------|--------|-----------|------------------------|
| Haiku 5.5 (`claude-haiku-5-5`), prompts ≤100K tokens | $0.10 | $0.50 | $0.01 | $0.125 / $0.20 |
| Haiku 5.5, prompts >100K tokens | $0.50 | $2.50 | $0.05 | $0.625 / $1.00 |
| Sonnet 5.5 (`claude-sonnet-5-5`) | $2.00 | $10.00 | $0.10 | $2.50 / $4.00 |
| Opus 5.5 (`claude-opus-5-5`) | $4.00 | $20.00 | $0.20 | $5.00 / $8.00 |
| Fable 5.1 (`claude-fable-5-1`) | $10.00 | $50.00 | $0.25 | $12.50 / $20.00 |

- All four current models have a 1M-token context window and 128K max output. Except for Haiku 5.5 (priced by prompt length, threshold 100K tokens), the full 1M window is billed at standard rates.
- Cache reads are 0.05x base input on Opus 5.5 and Sonnet 5.5, 0.025x on Fable 5.1, and 0.1x on other models.
- **Batch API:** 50% off input and output.
- **Fast mode** (Opus 5.5): $8 / $40 per MTok. Not available with Batch.
- **US-only inference** (`inference_geo: "us"`): 1.1x multiplier on 4.6-and-later models.
- Still available as legacy models: Fable 5, Opus 5, Opus 4.8/4.7/4.6/4.5, Sonnet 5, Sonnet 4.6, Haiku 4.5. Claude 4.7-and-later models use a newer tokenizer that produces roughly 30% more tokens for the same text, so compare cost per task, not just rate cards.

### OpenAI (as of October 2026)

Source: [OpenAI API pricing](https://developers.openai.com/api/docs/pricing), [models](https://developers.openai.com/api/docs/models).

| Model | Input | Cached input | Output |
|-------|-------|--------------|--------|
| GPT-6 Luna (`gpt-6-luna`) | $0.10 | $0.01 | $0.50 |
| GPT-6.1 Sol (`gpt-6.1-sol`) | $2.00 | $0.10 | $10.00 |
| GPT-6 Astra (`gpt-6-astra`) | $10.00 | $1.00 | $50.00 |
| GPT-5.5 (previous gen) | $5.00 | $0.50 | $30.00 |
| GPT-5.4 (previous gen) | $2.50 | $0.25 | $15.00 |

- The three GPT-6 models are OpenAI's featured models, each with a ~1.05M-token context window and 128K max output.
- **Long context:** prompts over 272K input tokens are billed at higher rates (for example GPT-6.1 Sol $4 / $15, GPT-6 Astra $20 / $75).
- **Batch / Flex:** 50% off standard rates. **Fast** (formerly Priority) tier: 2x standard on the GPT-6 models.
- Regional processing (data residency) adds 10% for eligible models.

### Google Gemini API (as of October 2026)

Source: [Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing), [models](https://ai.google.dev/gemini-api/docs/models).

| Model | Input | Output | Context cache (read) |
|-------|-------|--------|----------------------|
| Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) | $0.30 | $2.50 | $0.03 + storage |
| Gemini 3.8 Flash (`gemini-3.8-flash`) | $0.75 | $3.75 | $0.075 + storage |
| Gemini 4 Argon (`gemini-4-argon`) | $2.00 | $10.00 | $0.10 (implicit only) |
| Gemini 3.1 Pro Preview, ≤200K prompt | $2.00 | $12.00 | $0.20 + storage |
| Gemini 3.1 Pro Preview, >200K prompt | $4.00 | $18.00 | $0.40 + storage |

- **Scheduled increases:** Google's pricing page lists Gemini 4 Argon doubling to $4 / $20 from December 1, 2026, and Gemini 3.8 Flash doubling to $1.50 / $7.50 from January 1, 2027.
- Gemini 4 Argon is documented with a 1M-token context window. Google recommends Gemini 3.8 Flash for long-horizon software engineering and agent work.
- **Batch:** 50% off standard rates.
- The Gemini 2.5 family (2.5 Pro $1.25 / $10 ≤200K) is still listed but access is restricted; Google asks new projects to use 3.5 Flash-Lite or 3.8 Flash.

### Others

Open-weight and alternative providers (Mistral, DeepSeek, Cohere, and inference accelerators such as Groq or Cerebras) change prices often and were not re-verified for this revision. Check each provider's pricing page directly.

---

## Subscription Pricing

### Claude plans (as of October 2026)

Source: [claude.com/pricing](https://claude.com/pricing), [Claude Code setup](https://code.claude.com/docs/en/setup).

| Plan | Price | Claude Code |
|------|-------|-------------|
| Free | $0 | Not included |
| Pro | $20/mo monthly ($200/yr billed annually) | Included |
| Max | From $100/mo (5x or 20x Pro usage) | Included |
| Team, standard seat | $25/seat/mo monthly ($20 annual) | Included |
| Team, premium seat | $125/seat/mo monthly ($100 annual) | Included |
| Enterprise | $20/seat/mo annual, 20-seat minimum; usage billed at API rates | Included |

Claude Code needs a Pro, Max, Team, Enterprise, or Console (API) account. With a Console API key you pay standard per-token rates instead of a subscription. Anthropic doesn't publish fixed per-window prompt counts for each plan, so measure your own usage before choosing Max over Pro.

### ChatGPT plans with Codex (as of October 2026)

Source: [Codex pricing](https://learn.chatgpt.com/docs/pricing). See also the [Codex guide](../guides/codex/README.md).

| Plan | Price | Codex |
|------|-------|-------|
| Free | $0 | Quick coding tasks |
| Go | $8/mo | Lightweight coding tasks |
| Plus | $20/mo | "A few focused coding sessions each week" |
| Pro | $100, $200, or $500/mo | Highest allowances |
| Business | $25/user/mo monthly ($20 annual, 2+ users) | Included |
| Enterprise / Edu | Contact sales | Included |

Codex can also run on an API key, billed at API rates (suited to CI); API-key mode doesn't include cloud features such as GitHub code review.

### GitHub Copilot (as of October 2026)

Source: [Copilot plans](https://github.com/features/copilot/plans), [plans docs](https://docs.github.com/en/copilot/get-started/plans).

| Plan | Price | Monthly GitHub AI Credits |
|------|-------|----------------------------|
| Free | $0 | 2,000 completions + 50 chat requests |
| Pro | $10/mo | 1,500 (1,000 base + 500 flex) |
| Pro+ | $39/mo | 7,000 (3,900 base + 3,100 flex) |
| Max | $100/mo | 20,000 (10,000 base + 10,000 flex) |
| Business | $19/user/mo | 1,900 |
| Enterprise | $39/user/mo | 3,900 |

1 AI Credit = $0.01. Code completions and next-edit suggestions don't consume credits on paid plans. Paid individual plans include the Copilot cloud agent (assign an issue, get a PR). Pro+ and Max can also delegate to third-party coding agents such as Claude and OpenAI Codex (preview).

### Cursor (as of October 2026)

Source: [cursor.com/pricing](https://cursor.com/pricing).

| Plan | Price | Usage |
|------|-------|-------|
| Free | $0 | Limited agent and chat requests |
| Plus | $8/mo | Shared "Basic" usage pool |
| Premium | $30/mo | 4x Plus usage; cloud agents, AI code review |
| Super | $100/mo | 15x Plus usage; priority access |
| Ultra | $200/mo | 50x Plus usage |
| Teams | $30+/user/mo | 4-50x Plus usage; SSO, admin, analytics |
| Enterprise | Custom | Pooled usage, SCIM, audit logs |

Cursor restructured its plans in 2026: third-party models (Claude, GPT, Gemini) are billed separately by usage rather than included in the plan price, and allowances refresh weekly. Read the current page before budgeting a team.

### Google (Gemini CLI / Antigravity)

On June 18, 2026, Gemini CLI and the Gemini Code Assist IDE extensions stopped serving free individual, Google AI Pro, and Google AI Ultra users; those users moved to **Antigravity CLI**, part of Google Antigravity ([Google Developers Blog](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/)). Gemini CLI remains available to Gemini Code Assist Standard/Enterprise organizations and with paid Gemini API keys. Google lists Antigravity as available at no charge for individuals, with higher agent rate limits on Google AI Pro and Ultra ([antigravity.google](https://antigravity.google/)). Google AI plan prices weren't verifiable from a primary source for this revision.

### Other tools

- **Sourcegraph Cody:** Cody Free and Pro were discontinued on July 23, 2025; only Cody Enterprise remains ([Sourcegraph blog](https://sourcegraph.com/blog/changes-to-cody-free-pro-and-enterprise-starter-plans)).
- **Windsurf, JetBrains AI, Tabnine:** pricing not re-verified for this revision — check vendor pages.

---

## Free Tiers

Useful free tiers as of October 2026:

| Tool | Free quota | Limitations |
|------|------------|-------------|
| GitHub Copilot Free | 2,000 completions + 50 chat requests / mo | No cloud agent |
| Cursor Free | Limited agent and chat requests | |
| ChatGPT Free (Codex) | Quick coding tasks | Smallest allowance |
| Google Antigravity | Available at no charge for individuals | Rate-limited agent model |
| Gemini CLI | Not available on the unpaid tier since June 18, 2026 | Use Antigravity CLI, or a paid Gemini API key |
| Claude Free | Chat only | Claude Code not included |

For learning / hobbyist work, Copilot Free plus Antigravity plus a ChatGPT or Claude entry plan gets you far.

---

## What the Models Actually Cost in Practice

Per-developer monthly cost ranges based on usage patterns:

### Light user (occasional chat, some completion)

- Copilot Pro: $10
- Cursor Plus: $8 (third-party models billed separately)
- Claude Pro or ChatGPT Plus (includes Claude Code / Codex): $20
- Claude Code or Codex via API key: varies with usage

**Light total: roughly $10-30/mo per dev.** A Copilot Pro or entry chat-plan subscription usually wins.

### Heavy individual user (daily multi-hour AI sessions, agent work)

- Copilot Pro+ ($39) or Max ($100): Pro's credit allowance runs out under agent load
- Cursor Super ($100) or Ultra ($200)
- Claude Code via Claude Max: from $100
- Codex via ChatGPT Pro: from $100
- Claude Code or Codex via API key: highly variable; agent loops can run into hundreds of dollars a month

**Heavy total: roughly $100-500/mo per dev.** Pick based on workflow style; most heavy users settle on one agent subscription plus one IDE tool.

### Agent fleet / background workloads

- API spend dominates. Per-agent costs:
  - Triage bot (10 calls/day, Sonnet-class): a few dollars a month
  - Daily PR review bot (50 PRs/day, Sonnet-class): tens of dollars a month
  - Continuous integration agent (1000 invocations/day, Haiku-class + occasional Sonnet-class): tens to hundreds of dollars a month
  - These are rough estimates; compute your own from token counts × the rate tables above
- Plus: governance platform ($300-3000/mo at scale; see [agent-governance.md](../best-practices/agent-governance.md))
- Plus: orchestration infra (Temporal, Inngest, custom) — $100-1000/mo

**Fleet total: $500-10000/mo depending on scale.**

### Team of 10 developers

- Copilot Business: $190/mo
- Cursor Teams: from $300/mo
- Claude Team standard seats: $200-250/mo (or Claude Code on API keys, usage-based)
- Plus governance / observability if production agents: $500-3000/mo

**Team of 10: $1000-5000/mo all-in** for tools + minimal infra.

### Team of 100 developers

- Copilot Enterprise: $3900/mo
- Cursor Teams: from $3000/mo (consider Enterprise tier negotiation)
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
| $20 (Claude Pro / ChatGPT Plus) | 8 minutes |
| $100 (Claude Max / Copilot Max / Cursor Super) | 40 minutes |
| $200 (Cursor Ultra / higher Max tiers) | 80 minutes |
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
- Internal documentation, CLAUDE.md / AGENTS.md / `.cursor/rules` curation: 10-40 hours per repo
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

- **Cheaper tier for routing / classification.** Haiku 5.5 routes; Sonnet 5.5 or Opus 5.5 does the work.
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

- Cursor Plus: $8/mo (plus any third-party model usage)
- Claude Code via Claude Pro: $20/mo
- (Maybe) Google Antigravity: no charge for individuals
- Storage / hosting (Vercel, Supabase, etc.): $20-50/mo

**TCO: roughly $50-80/mo.**

### Small startup, 5 engineers, no production agents

- Cursor Teams x5: from $150/mo
- Claude Team standard x5 (includes Claude Code): $100-125/mo
- Observability (free tiers initially): $0
- LLM provider account fees: $0

**TCO: roughly $250-400/mo.**

### Growing startup, 25 engineers, some production agents

- Cursor Teams x25: from $750/mo
- Copilot Business x25 (alongside Cursor): $475/mo
- Claude Code API: $500-1500/mo
- Production agent API spend: $500-3000/mo
- Observability (LangSmith Pro): $200-500/mo
- Vector DB (Pinecone Standard): $200/mo
- Compute (small K8s cluster, agents): $500-2000/mo

**TCO: $3000-9000/mo.**

### Mid-size company, 100 engineers, production agent fleet, regulated industry

- Copilot Enterprise x100: $3900/mo
- Cursor Teams x100: from $3000/mo
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

- **Prices move.** Opus went from $15/$75 (Opus 4.1) to $5/$25 (Opus 4.5 through Opus 5) to $4/$20 (Opus 5.5); Sonnet from $3/$15 (Sonnet 4.6) to $2/$10 (Sonnet 5 and 5.5). Google has announced increases for Gemini 4 Argon and 3.8 Flash. Expect further movement.
- **Tokenizers differ.** Claude 4.7-and-later models produce roughly 30% more tokens for the same text than earlier Claude models, so a lower rate card doesn't always mean a lower bill.
- **New tiers appear.** GPT-6 Luna, Haiku 5.5, and the Gemini Flash-Lite tiers exist for cost-sensitive workloads.
- **Provider credits / discounts.** Negotiate. Most providers offer 10-30% off at $50K+ annual.
- **Region pricing.** Vertex AI region pricing varies slightly; EU sometimes higher.
- **Currency.** All USD. EUR / GBP pricing typically tracks with FX adjustment.
- **Per-seat sub tools change quotas.** Cursor restructured its plans again in 2026 (third-party models now billed by usage), GitHub moved Copilot metering to AI Credits in June 2026, and Google moved consumer Gemini CLI users to Antigravity CLI. Read the fine print before committing a large team.

The number that matters is **cost per delivered task or feature**, not the API rate card. A $0.50 task with Opus that ships in 5 minutes beats a $0.05 task with Haiku that takes 45 minutes of human follow-up to fix.

---

## Related

- [Feature Matrix](feature-matrix.md)
- [Use Cases](use-cases.md)
- [Performance Comparison](performance.md)
- [Performance Best Practices](../best-practices/performance.md)
- [Agent Governance](../best-practices/agent-governance.md)
