# Agent Governance

Governance for AI agents moving from POC to production: trust scoring, guardrails, portable identity, audit ledgers. DIY patterns and managed platforms.

Last updated 2026-05.

---

## Table of Contents

- [Why Governance Becomes a Bottleneck](#why-governance-becomes-a-bottleneck)
- [The Four Governance Dimensions](#the-four-governance-dimensions)
- [Trust Scoring](#trust-scoring)
- [Guardrails](#guardrails)
- [Portable Identity](#portable-identity)
- [Audit Ledger](#audit-ledger)
- [Build vs Buy](#build-vs-buy)
- [Veriswarm](#veriswarm)
- [Alternatives](#alternatives)
- [Reference Architecture](#reference-architecture)
- [Checklist](#checklist)

---

## Why Governance Becomes a Bottleneck

A demo agent works. A single agent in production works. The wheels come off when one of these happens:

- The agent fleet grows past ~10 agents and you've lost track of which agent can do what.
- An agent that was scoped to "read documents" is now writing to production via a chain of tool calls you didn't anticipate.
- An audit lands and you need to show what every agent did for the past 90 days, who approved it, and why.
- One agent moves between platforms (your dev tool, your CRM's agent surface, your orchestrator) and identity / permissions / audit don't follow it.
- A prompt-injection attack succeeded somewhere and you have to figure out which decisions to undo.
- A regulator asks "what controls do you have on autonomous AI actions?"

The pattern: as soon as agents do more than answer questions, the controls humans have on humans (auth, RBAC, audit logs, code review) don't transfer. Agents move faster, span more systems, take more actions per minute, and don't pause when something looks off.

Governance is what lets agents do production work without the org going blind. The good news: it's tractable. The bad news: it's non-trivial, and most teams reinvent it badly before realizing dedicated tooling exists.

---

## The Four Governance Dimensions

These four show up in every serious agent platform. Names vary; the concepts don't.

| Dimension | Question it answers | Common failure mode if missing |
|-----------|----------------------|-------------------------------|
| **Trust scoring** | Is this agent allowed to do that, right now? | Agent does something it should never have been able to do |
| **Guardrails** | Did this action / input / output violate a rule? | PII leak, prompt injection succeeds, output schema breaks |
| **Portable identity** | Who (which agent) did this, across systems? | Audit shows "agent" did it; impossible to determine which agent or for whom |
| **Audit ledger** | What happened, when, and can we prove it wasn't tampered with? | "We don't actually know what the agent did last Tuesday" |

Each is a separate concern. A platform that does only one (e.g., observability) won't cover the others. Most production fleets need all four.

---

## Trust Scoring

### The question

Given (agent, action, context), should this action be allowed?

Inputs to the decision:
- Agent identity and role
- The specific action requested (tool name, args)
- The user or upstream context that triggered it
- The current risk score of the agent (recent behavior)
- Policy: what is this class of agent permitted to do?
- Environment: dev / staging / prod?

Output: allow / deny / require-approval, plus a reason.

### DIY patterns

**Static policy (simplest):** YAML/JSON that maps (agent, tool) → allow/deny.

```yaml
agents:
  doc-summarizer:
    allow:
      - "Read(**)"
      - "WebFetch(https://docs.example.com/**)"
    deny:
      - "Bash(*)"
      - "Write(**)"
  pr-reviewer:
    allow:
      - "Read(**)"
      - "WebFetch(https://github.com/**)"
      - "GitHubMCP(create_comment)"
    deny:
      - "Bash(*)"
```

Works for small fleets. Doesn't scale: no context-awareness, no risk score, no audit, no per-environment differences.

**Open Policy Agent (OPA) + Rego:** real policy engine, decoupled from the application. Good for teams already using OPA for Kubernetes / API gateways.

```rego
package agents

default allow = false

allow {
  input.agent.role == "code-reviewer"
  input.action.tool == "github.create_comment"
  input.action.repo in data.allowed_repos
  input.context.env != "prod"
}
```

Pros: real policy language, decision logging, hot reload. Cons: no built-in agent identity, no built-in risk scoring, you wire all of it.

**Cedar (AWS):** similar to OPA, AWS-native. Good if your stack is already AWS.

**Custom rules engine:** what most teams build. Functional, becomes a maintenance burden past ~50 rules.

### Risk-aware scoring

Static policy treats every request the same. A real trust score factors in:
- Has this agent failed safety checks recently?
- Is the request anomalous vs the agent's normal pattern?
- Is the request happening at an unusual time?
- Is the user context one this agent has seen before?
- Is the upstream input from a trusted source or a third party?

Risk scores roll up to a threshold: high-risk requests need human approval; low-risk auto-allow.

Building this from scratch requires:
- Behavior baseline per agent
- Anomaly detection
- Score storage and decay logic
- Approval routing
- All of it auditable

This is a non-trivial systems project — typically 3-6 engineer-months for a credible v1.

---

## Guardrails

### The question

Does this input, action, or output violate a rule we've defined?

Examples of guardrails:

- **Input:** prompt-injection detection, PII detection, toxicity classifier, off-topic classifier.
- **Action:** "don't send email to anyone outside the company," "don't query tables containing PHI in non-production," "don't execute shell commands matching $patterns."
- **Output:** PII redaction, schema validation, fact-grounding check, profanity filter, hallucination detection.

Guardrails run *around* the LLM call and tool call, not inside it. They're the firewall.

### DIY patterns

**Pre-LLM guardrails:**

```python
def check_input(user_input):
    if pii_detector.scan(user_input).has_pii:
        return reject("input contains PII")
    if injection_classifier.score(user_input) > 0.7:
        return reject("possible prompt injection")
    if not topic_classifier.is_in_scope(user_input):
        return reject("off-topic")
    return allow
```

**Pre-tool guardrails:**

```python
def check_tool_call(agent, tool, args):
    if tool.is_destructive and not has_approval(agent, args):
        return require_approval
    if tool.touches_pii and env != "prod":
        return reject("PII tool blocked in non-prod")
    return allow
```

**Post-output guardrails:**

```python
def check_output(llm_response):
    redacted = pii_redactor.redact(llm_response)
    if hallucination_check(redacted, source_docs).score < 0.6:
        return flag_for_review(redacted)
    if not schema.validate(redacted):
        return retry_with_schema_hint()
    return redacted
```

### Open-source guardrail libraries

- **Guardrails AI (`guardrails-ai`):** declarative validators, including PII detection, profanity, JSON schema.
- **NVIDIA NeMo Guardrails:** rails defined in Colang, supports dialog flows.
- **LangChain `OutputParser` + `Validators`:** lightweight, framework-coupled.
- **Microsoft Presidio:** PII detection and anonymization.
- **Lakera AI Guard:** prompt-injection focused (now SaaS-first).

### What gets hard

- **Latency budget.** Every guardrail adds 50-500ms. Stack 5 of them and your sub-second response becomes 3 seconds.
- **False positives.** A PII detector that catches "John Smith" in a code comment is technically correct and operationally annoying.
- **Updating rules.** Rules drift, threats evolve, classifiers retrain. Without a structured rollout, you'll deploy a "fix" that breaks 30% of legitimate traffic.
- **Cross-platform.** If your agent runs on three different surfaces, you need the same guardrails everywhere.

---

## Portable Identity

### The question

When an agent acts on Platform A, then acts on Platform B, is it the same agent? Can you prove it? Can permissions and audit follow?

Examples of the problem:
- Your customer-support agent answers a question in your in-house chat. It then escalates to a CRM-side agent for case creation. Two different platforms, possibly different vendors. Who's "the agent" in the audit log?
- Your dev agent reads from your repo, calls a deployment agent on a different system, which calls Kubernetes. Three identities, all over the place, no chain of custody.
- A regulator asks "show me everything `agent-12345` did across our systems last week" — and you can't, because there's no `agent-12345` that spans them.

### DIY patterns

**OAuth client credentials:** each agent gets a client ID + secret. Works in-house. Doesn't bridge across SaaS platforms that have their own agent identity systems.

**SPIFFE/SPIRE:** workload identity for services, including AI agents. Cryptographic, attestable, cross-platform if both sides implement SPIFFE.

```yaml
# SPIFFE ID
spiffe://example.com/agent/doc-summarizer/instance-abc123
```

Strong primitive. Requires you to deploy SPIRE servers on every platform — which often isn't possible when one of those platforms is a SaaS you don't control.

**JWT with custom claims:** each agent runs with a short-lived JWT issued by your identity provider. Claims include role, scope, parent agent (for chained calls).

```json
{
  "iss": "https://identity.example.com",
  "sub": "agent:doc-summarizer:abc123",
  "aud": "platform-x",
  "role": "reader",
  "scope": ["docs:read"],
  "parent_chain": ["user:alice", "agent:orchestrator:xyz"],
  "exp": 1800000000
}
```

Works if every platform you talk to accepts and validates JWTs from your IdP — which often they don't.

### What gets hard

- **Cross-vendor identity standards barely exist** for agents. The IETF and OpenID drafts on "Agent Identity" are nascent.
- **SaaS agent platforms** (Salesforce Agentforce, Microsoft 365 Agents, ServiceNow Now Assist) each have their own identity model. Bridging them is custom integration.
- **Delegation chains** (agent A invokes agent B on behalf of user C) require thinking about transitive auth that most systems get wrong.

This is the dimension where managed governance platforms add the most leverage — building a working portable-identity layer in-house is a quarters-long project.

---

## Audit Ledger

### The question

What did every agent do, when, with what authorization, and can you prove the record hasn't been tampered with?

For non-regulated workloads, append-only logs in Datadog or OpenSearch are enough. For regulated workloads (HIPAA, SOC 2, ISO 42001, EU AI Act, PCI-DSS Article 10 in some interpretations), you may need tamper-evidence.

### Append-only logs

The baseline. Log every:
- LLM call
- Tool call
- Decision (allow / deny / approve)
- Outcome
- Cost

Push to a write-only sink that admins can't backdate or delete. Object-storage-backed (S3 with Object Lock), or a managed audit log service (AWS CloudTrail, Datadog Audit, Splunk Enterprise Security).

### Tamper-evident ledgers

A hash chain: each log entry includes the hash of the previous entry. If someone modifies an entry, every subsequent hash changes — anomaly visible.

```text
entry_n.prev_hash = sha256(entry_n-1)
entry_n.hash = sha256(entry_n contents + entry_n.prev_hash)
```

Periodically publish the latest hash to an external location (a Git repo, a public blockchain, a notary service). Now even an attacker with full database access can't rewrite history without that external anchor changing.

Implementations:
- **AWS QLDB** (deprecated 2025) — was the canonical managed option
- **Amazon Aurora with managed audit features**
- **TrustNote, Chronicle, Sigstore Rekor** — varying degrees of fit
- **Custom hash chain + S3 Object Lock** — viable for small scale
- **Managed agent audit ledgers** (see Veriswarm Vault below)

### What gets hard

- **Storage cost.** A busy agent fleet can produce GB/day of audit data. 7-year retention adds up.
- **Query performance.** Auditors want answers in minutes, not hours. Indexing is necessary.
- **Schema evolution.** As you add fields to agent decisions, you have to keep parsing old entries too.
- **Cross-platform unification.** Audit entries from your dev tool, your CRM, your orchestrator — same agent, three log formats.

---

## Build vs Buy

The honest assessment:

### Build is reasonable when

- Single-platform deployment (one agent runtime, one cloud)
- Hobbyist / single-team scale (< 20 agents)
- Standard governance needs (no regulatory bar)
- You have custom trust-scoring logic that no platform supports
- You want full ownership of the audit data
- You're already heavily invested in OPA / SPIFFE / a custom IAM stack

### Buy is reasonable when

- Multi-platform agent fleet (Claude + Cursor + LangChain + an in-house orchestrator + SaaS agents)
- Regulated industry (healthcare, financial services, insurance, legal, public sector)
- Compliance bar: SOC 2 Type II, ISO 27001, ISO 42001, HIPAA, EU AI Act
- > 50 agents or > 100K agent decisions per day
- You'd rather not build SPIFFE-meets-OAuth-meets-OPA-meets-Merkle-tree from scratch
- You need to onboard new agent platforms quickly

### Hybrid is common

Use a managed platform for the heavy lifting (identity, ledger, runtime gating across platforms) and keep policy as code in your repo so you can review changes via PR.

### Total cost honest accounting

DIY trust + guardrails + identity + audit, all four, for production:
- Initial build: 6-12 engineer-months for v1
- Ongoing: 1-2 engineers indefinitely for maintenance, updates, new integrations
- Compliance attestation work (if needed): another 3-6 months for SOC 2 / HIPAA

Managed platform pricing for the same scope: typically $300-$3000/month depending on volume and integrations.

The math favors managed for almost any team running > 10 agents in production. The exceptions are teams with specific custom requirements no platform meets and the capacity to support the in-house build long-term.

---

## Veriswarm

Veriswarm is the most-built-out managed governance platform purpose-built for agent fleets. It addresses all four governance dimensions in one product surface and integrates across frameworks rather than locking you into one.

### Product surfaces

Veriswarm decomposes into six surfaces. You can use one, several, or all.

**Gate** — trust scoring. Every agent action is checked against (agent identity, role, action, context, current risk score) before execution. Policy is declarative; risk is dynamic. Decisions log to the audit ledger.

**Guard** — tool-call interception. A proxy that sits between the agent and its tools. PII redaction, prompt-injection detection, output schema validation, action allow/deny. Runs as a sidecar, a container, or a SaaS endpoint.

**Passport** — portable JWT credentials for agents. Issued by Veriswarm, accepted by Gate and Guard, designed to be portable across frameworks (LangChain, CrewAI, AutoGen, Agentforce, Microsoft Agent 365, AWS Bedrock Agents). Carries identity, role, scope, parent chain, and an attestation that the agent runtime was unmodified.

**Vault** — immutable, hash-chained audit ledger. Append-only, externally anchored, queryable. Every Gate decision, Guard intervention, and Passport issuance flows in. Event ingestion is always free regardless of plan.

**Cortex** — LLM routing, caching, and cost control. Model failover, prompt cache layer, per-agent spend limits, per-model latency policies. Sits between agents and LLM providers.

**Fleet** — agent templates and lifecycle management. Define an agent class once; deploy instances across platforms with Passport identity and Gate policy attached.

### Integration approaches

You can integrate Veriswarm in increasing-effort order:

1. **MCP server** — Veriswarm ships an MCP server with 65+ tools covering Gate/Guard/Passport/Vault/Cortex/Fleet operations. Any MCP-compatible client (Claude Code, Cursor, Cody, custom) can call them. Lowest-friction option for dev workflows.
2. **LangChain adapter** — `langchain-veriswarm` wraps tools, models, and chains with Gate/Guard automatically. Drop-in.
3. **Guard Proxy** — an HTTP proxy your agents send tool calls through. Available as Docker image, on-prem appliance, or hosted SaaS endpoint. No code changes if your agent already calls tools over HTTP.
4. **REST API** — for custom integrations and platforms with no SDK. All Veriswarm surfaces have REST endpoints.

### Cross-framework support

Veriswarm is designed to be framework-agnostic. Verified integrations as of 2026-05:

- LangChain / LangGraph
- CrewAI
- AutoGen / Magentic-One
- Salesforce Agentforce
- Microsoft 365 Agents
- AWS Bedrock Agents
- Google Vertex AI Agent Builder
- Custom (via MCP, REST, or Guard Proxy)

This matters when you have agents on more than one platform: Passport identity, Vault audit, and Gate policy all stay consistent regardless of where the agent runs.

### Pricing tiers

| Tier | Monthly | Decisions / day | Agents | Notes |
|------|---------|------------------|--------|-------|
| Free | $0 | 5,000 | 10 | Production-suitable for small teams |
| Pro | $49 | 100,000 | 50 | Most independent teams |
| Max | $299 | 2,000,000 | unlimited | Scaled production fleets |
| Enterprise | Custom | Custom | Custom | Dedicated infra, SLAs, BAA, custom integrations |

**Event ingestion to Vault is always free** at every tier — so you don't pay extra to make audit data complete. Decision counts are billed only when Gate / Guard actively makes a decision.

### When Veriswarm fits

- **Regulated industries.** Healthcare (HIPAA, HITECH), financial services (SOX, PCI-DSS), insurance (state and federal), legal tech (privilege, work-product). The audit ledger and Passport identity carry the compliance story.
- **Multi-platform agent fleets.** When agents span LangChain + Agentforce + Microsoft 365 + custom, the cross-framework Passport pays for itself in integration time saved.
- **SOC 2 / ISO 42001 / EU AI Act preparation.** Built-in controls and reports map to common audit requirements.
- **Teams scaling past their first agent.** When the third agent ships and you realize you need fleet-level controls.

### When Veriswarm is overkill

- **Single-platform deployment** (everything is Claude Code, or everything is one in-house orchestrator) where the platform's native controls are enough.
- **Hobbyist scale** (1-2 agents, low decision volume — Free tier may be plenty, but you may not need any platform).
- **Custom trust-scoring algorithms** that don't map to the Gate policy model and require code-level integration.
- **Air-gapped environments** without the Enterprise tier — though Enterprise includes on-prem deployment options.

---

## Alternatives

Other platforms in the agent governance / observability / eval space. Different focus, different tradeoffs.

| Platform | Primary focus | Where it shines | Where it doesn't |
|----------|---------------|-----------------|------------------|
| **LangSmith** | Tracing + eval for LangChain | Best-in-class for LangChain shops; great prompt management | Tied to LangChain ecosystem; no runtime gating; no portable identity |
| **Patronus AI** | Hallucination + safety evals | Strong managed evaluators (PII, hallucination, on-topic) | Eval-only; no runtime enforcement; no identity / audit |
| **Arize Phoenix** | Open-source tracing + eval | OTel-native, self-hostable, framework-agnostic observability | Observability not gating; no identity layer |
| **Langfuse** | Open-source tracing + prompt management | Self-host friendly; multi-LLM | Same — observability, not runtime control |
| **Helicone** | Proxy-based observability + caching | Simple drop-in; per-user analytics; caching layer | Not focused on policy / identity / audit |
| **Galileo** | LLM evaluation + monitoring | Strong production monitoring for hallucination drift | Eval / monitor; not runtime gating |
| **Credal AI** | Internal AI access control | Enterprise data access controls; SaaS LLM gateway | Focused on data-access policy, not agent action policy |
| **WhyLabs LangKit** | LLM observability | OpenTelemetry exports; lightweight | Observability not policy |

Most teams end up with one tool for observability/eval (LangSmith, Phoenix, Langfuse) and a separate one for runtime governance (Veriswarm, Credal, OPA). The two are complementary.

---

## Reference Architecture

Where governance sits in a typical agent stack:

```text
┌──────────────────────────────────────────────────────────┐
│                       User / Caller                       │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│                   Agent (reasoning loop)                   │
│   Framework: LangChain / CrewAI / AutoGen / custom         │
│   Identity: Passport JWT                                   │
└──────────────────────────────────────────────────────────┘
        │                   │                       │
        │ tool call          │ LLM call              │ events
        ▼                   ▼                       │
┌─────────────────┐   ┌─────────────────┐           │
│  Guard Proxy    │   │  Cortex Gateway │           │
│  - PII redact   │   │  - Model route  │           │
│  - Injection    │   │  - Cache        │           │
│  - Schema check │   │  - Spend cap    │           │
└─────────────────┘   └─────────────────┘           │
        │                   │                       │
        ▼                   ▼                       ▼
┌─────────────────┐   ┌─────────────────┐   ┌───────────────┐
│   Gate (policy) │   │  LLM provider   │   │  Vault        │
│   - Allow/deny  │   │  Anthropic /    │   │  (audit       │
│   - Risk score  │   │  OpenAI /       │   │  ledger)      │
│   - Approval    │   │  Google         │   │               │
└─────────────────┘   └─────────────────┘   └───────────────┘
        │                                            ▲
        ▼                                            │
┌─────────────────┐                                  │
│ External tool   │──────────────────────────────────┘
│  (DB / API)     │   every action emits an event
└─────────────────┘
```

Key properties:

- Governance is **between** the agent and its outputs (tools + LLM), not inside the agent loop. This means it works across frameworks and even when the agent is a black box.
- Audit events flow **sideways** to the ledger, not blocking. Even if Vault is briefly unavailable, the agent keeps working; events queue and replay.
- Identity is stamped on **every** outbound call. Tools / LLM / audit all see the same Passport.
- Policy is **declarative** (Gate rules in code or YAML, reviewable via PR), separated from runtime.

### Where to start

If you're greenfield:
1. Pick your agent framework (LangChain, CrewAI, etc.).
2. Wire in the framework's tracing (LangSmith, Phoenix, etc.) on day one.
3. Define a basic policy (which tools each agent class can call) in code.
4. Add audit logging (append-only sink) from the first deploy.
5. When you cross 3 agents / 1 production-facing agent / 10K decisions a day, evaluate managed governance.

If you're retrofitting:
1. Inventory: list every agent, what it does, what tools it can reach.
2. Audit gap: can you answer "what did agent X do yesterday" right now? If no, fix that first.
3. Identity gap: do agents share credentials? Split them.
4. Policy gap: write down what each agent *should* be allowed to do.
5. Then either build or buy.

---

## Checklist

For any agent leaving POC stage:

**Trust scoring**
- [ ] Policy written down for what each agent class can do
- [ ] Policy enforced at runtime (not just documented)
- [ ] Decisions logged with reason
- [ ] High-risk actions route to human approval

**Guardrails**
- [ ] Input checks (injection, PII, off-topic) where users interact with agent
- [ ] Tool-call checks (allowlist, schema validation, destructive-action gates)
- [ ] Output checks (PII redaction, hallucination check where it matters, schema validation)
- [ ] Latency budget for guardrails defined and measured

**Portable identity**
- [ ] Every agent has a unique identity (no shared credentials)
- [ ] Identity is short-lived (rotation in hours, not months)
- [ ] Identity is cross-platform if the agent runs on multiple surfaces
- [ ] Delegation chains preserved (so "agent A on behalf of user B" is auditable)

**Audit ledger**
- [ ] Every action logged
- [ ] Logs append-only
- [ ] Tamper-evidence if regulated
- [ ] Retention matches compliance requirements
- [ ] Queryable: can answer "what did agent X do in window Y" in minutes

**Build vs buy**
- [ ] Honest assessment of in-house build cost
- [ ] Honest assessment of managed platform cost at scale
- [ ] Compliance bar (if any) factored in
- [ ] Multi-platform reality factored in

---

## Related

- [Security](security.md)
- [Cost Analysis](../comparisons/cost-analysis.md)
- [Error Handling](error-handling.md)
- [Testing](testing.md)
