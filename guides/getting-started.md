# Getting Started

Three-question decision tree, choose-your-tool flowchart, and cross-links to detailed install guides.

Last updated 2026-10-21. Prices are as of October 2026; check each vendor's pricing page before buying.

---

## Table of Contents

- [Three Questions](#three-questions)
- [The Flowchart](#the-flowchart)
- [Recommendations](#recommendations)
- [What to Do Next](#what-to-do-next)
- [If You Already Have a Tool](#if-you-already-have-a-tool)
- [Common Mistakes](#common-mistakes)

---

## Three Questions

Before picking a tool, answer these three questions. They map cleanly to a recommendation.

### 1. Where will you mostly use it?

- **A. In an IDE you already love** (VS Code, JetBrains, Vim, etc.)
- **B. In the terminal**
- **C. Both, depending on the task**

### 2. What's the dominant work shape?

- **A. Daily coding** — typing, completing functions, small edits, debugging in place
- **B. Multi-file refactors / new features** — coherent changes across many files
- **C. Background automation** — agents that run without you watching
- **D. Whole-repo analysis** — understanding, auditing, documenting large code

### 3. How much budget do you have per developer per month?

- **A. $0** — free tier only
- **B. $10-30** — one subscription
- **C. $50-200** — power user, can combine subs and API
- **D. $200+** — heavy use, multiple tools, agent fleets

---

## The Flowchart

Start at the top. Follow the answers.

```text
                   What's the dominant work shape?
                                │
        ┌───────────────────────┼───────────────────────────┐
        │                       │                           │
   Daily coding         Multi-file work               Background /
   completions          / new features                whole-repo
        │                       │                           │
        ▼                       ▼                           ▼

  Budget?                  Where do you work?         Whole repo? or
                                                      Background?
  $0 ── Copilot Free       IDE ──► Cursor / Copilot      │
        Antigravity                                      │
                           Terminal ──► Claude Code      │
  $10-30 ── Copilot Pro               or Codex CLI       │
            Claude / ChatGPT  Both ──► IDE tool +        │
            Plus/Pro         terminal agent              │
  $50+ ── IDE tool                                       │
          + Claude Max / ChatGPT Pro                     │
                                              ┌─────────┴─────────┐
                                              │                   │
                                       Whole repo            Background
                                       Q&A / docs            agents
                                              │                   │
                                              ▼                   ▼
                                     Antigravity CLI /       Claude Code
                                     Gemini CLI (1M ctx)     (-p mode) or
                                     or Claude Code          Codex cloud
                                                             + governance
```

---

## Recommendations

### Solo / hobbyist, no budget

- **GitHub Copilot Free** (2,000 completions and 50 chat requests a month) in VS Code or JetBrains.
- **Google Antigravity** is available at no charge for individuals and includes the Antigravity CLI. Note that Gemini CLI stopped serving free individual accounts on June 18, 2026 — Antigravity CLI is its replacement for those users.
- Optional: **Cursor Free** or the ChatGPT Free plan (which includes light Codex use) for a second opinion. Free-tier limits are described only as "limited" by those vendors.

Setup time: 30 minutes.

### Solo developer, $10-30 budget

Pick one:

- **GitHub Copilot Pro ($10/mo)** if you live in VS Code or JetBrains and want polished inline completions plus agent mode and the cloud coding agent.
- **Claude Pro ($20/mo billed monthly)** if you want Claude Code in the terminal, IDE extensions, and desktop app.
- **ChatGPT Plus ($20/mo)** if you want OpenAI Codex (CLI, IDE extension, desktop app, cloud). See the [Codex Guide](codex/README.md).
- **Cursor Plus ($8/mo) or Premium ($30/mo)** if you want an AI-first VS Code fork. Note: as of October 2026 Cursor states that third-party models are "billed separately by usage"; check which models each plan includes before choosing.

If unsure, try the one that matches where you already work (IDE vs terminal) for two weeks.

### Solo power user, $50-200 budget

Combination:

- **Copilot Pro ($10) or Pro+ ($39)**, or a Cursor plan, for daily IDE work.
- **Claude Code via Claude Pro ($20)** or **Max (from $100)** — or **Codex via ChatGPT Plus ($20) / Pro (from $100)** — for terminal, multi-file refactors, agent work.

Total: roughly $30-140/mo. Covers all common workflows.

### Heavy user, $200+ budget

- **Cursor Super ($100) / Ultra ($200)** or **Copilot Max ($100)** for heavy IDE agent use.
- **Claude Max** (5x or 20x Pro usage, from $100) or **ChatGPT Pro** ($100 / $200 / $500 tiers), or direct API billing.
- **Antigravity** (Gemini 4 Argon is available to Google AI Pro and Ultra subscribers) for large analysis.

Total: $200-500/mo. You will recoup it in saved time within days.

### Team

See [cost-analysis.md](../comparisons/cost-analysis.md) Team scenarios. Default starting point for most teams:

- **Copilot Business ($19/user/mo)**, **Cursor Teams ($30+/user/mo)**, **Claude Team** (standard seat $25/mo monthly, $20 annual; premium seat $125/$100), or **ChatGPT Business** ($25/user/mo monthly, $20 annual; includes Codex) as the daily driver
- **Claude Code or Codex via API key** with a team budget for CI / agent work
- **Observability tooling** (LangSmith free tier or Langfuse self-hosted) from day one if you're building anything beyond chat

### Enterprise / regulated

See [agent-governance.md](../best-practices/agent-governance.md). The tool layer is the easy part. The governance, identity, audit, and compliance layer is what determines time to production.

---

## What to Do Next

After picking a tool:

1. **Install it.** See [basic-setup.md](basic-setup.md) for the generic walkthrough.
2. **Sign in and run hello-world.** Verify the tool works on a throwaway file.
3. **Set up `.gitignore` / `.cursorignore`, and `permissions.deny` in `.claude/settings.json` for Claude Code.** Prevent the tool from pulling in junk or secrets. See [context-management.md](../best-practices/context-management.md).
4. **Write project rules.** CLAUDE.md, AGENTS.md, `.cursor/rules/`, .github/copilot-instructions.md — whichever your tool reads (AGENTS.md is read by Codex, Copilot, Cursor and others). Start with 20 lines of project-specific conventions.
5. **Try a real task.** Pick something small but real. See [first-steps.md](first-steps.md).

For tool-specific deep dives:

- [Claude Code Guide](claude-code/) — installation, configuration, MCP servers, skills
- [GitHub Copilot Guide](github-copilot/) — IDE setup, coding agent, agent mode
- [OpenAI Codex Guide](codex/README.md) — CLI, IDE extension, cloud tasks
- [Gemini CLI Guide](gemini-cli/) — installation, large-context patterns (and the Antigravity CLI transition)
- [Google Antigravity Guide](antigravity/) — agent-first IDE, app, and CLI
- [Agents & Subagents Guide](agents-subagents/) — multi-agent design
- [MCP Servers Guide](mcp-servers/) — installing and writing MCP servers
- [Skills Guide](skills/) — writing reusable skill packs

---

## If You Already Have a Tool

If you already use one tool and you're wondering if you should add another:

| You have | Consider adding | Why |
|----------|-----------------|-----|
| Copilot | Claude Code or Codex | Terminal-first agent workflows and long multi-file sessions |
| Copilot | Cursor | If you want an AI-first editor rather than an extension |
| Cursor | Claude Code | Terminal / agent / background workflows |
| Cursor | Claude Code or Codex | A second agent from a different vendor for review |
| Claude Code | Cursor | Inline IDE experience for daily coding |
| Claude Code | Copilot | Inline completions if you live in VS Code |
| Gemini CLI | Antigravity CLI | Required for free / Google AI Pro / Ultra users since June 18, 2026 |
| Codex | Claude Code (or vice versa) | Cross-vendor second opinion on plans and reviews |

You rarely lose by adding a second tool if it covers a different work shape. The mistake is buying multiple tools that do the same thing.

---

## Common Mistakes

1. **Picking the trendiest tool, not the one that fits your work.** A great tool you don't use is worse than a good tool you use daily.
2. **Skipping project rules.** A 50-line CLAUDE.md / .cursorrules makes the model 2x more useful. Most teams skip this for months.
3. **Letting the tool index lockfiles and generated code.** Sets the context wrong from turn one. Add ignore files immediately.
4. **Trying to learn agent mode on a complex task first.** Start with a refactor of a single file. Build intuition. Then tackle big tasks.
5. **Trusting AI output without tests.** AI-generated code passes review by humans more often than humans realize. Run the tests.
6. **Treating an agent like a search engine.** Agents excel at multi-step tasks with tool calls. If you only want a quick answer, use chat — agents are overkill.
7. **Spending too long evaluating before committing.** Pick something, use it for two weeks, then re-evaluate. Don't paralysis-analyze.
8. **Cheap-tier-only.** Haiku 5.5 / GPT-6 Luna / Gemini Flash-Lite are amazing for routing and simple tasks; they fail on hard ones. Use Sonnet 5.5 / Opus 5.5 / GPT-6.1 Sol / Gemini 3.8 Flash or stronger when the task demands it.
9. **Ignoring cost dashboards.** Agents in loops can burn $100 in an hour. Set spend limits before you need them.
10. **Skipping security review on AI-generated code.** "It compiles" is not "it's safe."

---

## Three-Sentence Summary

If you write code daily in an IDE, install Copilot or Cursor and use it for everything. If you need multi-file refactors, background agents, or DevOps tooling, also install a terminal agent — Claude Code or OpenAI Codex. All current Claude models, GPT-6 models, and Gemini 4 Argon offer roughly 1M-token context, so whole-repo questions no longer require a separate tool.

---

## Decision Matrix (Quick Reference)

When you can't decide and want a one-line answer:

| Constraint | Pick |
|------------|------|
| Cheapest, IDE | Copilot Free or Antigravity (no charge for individuals) |
| Cheapest, terminal | Antigravity CLI, or Codex on the ChatGPT Free plan (light use) |
| Best inline completion (typing experience) | GitHub Copilot Pro |
| Best agent mode in IDE | Cursor, Copilot agent mode, or Antigravity — try two |
| Best for multi-file refactors | Claude Code (Opus 5.5 / Sonnet 5.5) or Codex (GPT-6.1 Sol) |
| Best for whole-repo Q&A | Any 1M-context terminal agent (Claude Code, Codex, Antigravity CLI) |
| Best for multi-repo Q&A | Sourcegraph (Cody is Enterprise-only since July 2025) |
| Best for infra / DevOps | Claude Code with MCP servers |
| Best for spec → PR flow | GitHub Copilot cloud agent or Codex cloud |
| Best for background agents | Claude Code `-p` (print) mode or Codex via API key in CI |
| Best for regulated / enterprise | Claude Code + governance platform (see [agent-governance.md](../best-practices/agent-governance.md)) |

---

## What Each Tool Is Not For

Sometimes the clearest decision is what to rule out:

- **Copilot is not the right tool for** multi-file architecture changes, infra work, background agents, or whole-repo Q&A.
- **Cursor is not the right tool for** anything you need to run unattended in CI, or anything that primarily lives outside the IDE.
- **Claude Code is not the right tool for** inline completion while typing, IDE-integrated debugging, or visual previews.
- **Gemini CLI is not the right tool for** new individual users — free and Google AI Pro/Ultra accounts were moved to Antigravity CLI on June 18, 2026. It remains available to Gemini Code Assist Standard/Enterprise orgs and paid Gemini API keys.
- **Cody is not the right tool for** individuals — Cody Free and Pro were discontinued on July 23, 2025; only Cody Enterprise remains.

The mistake is buying the most popular tool and trying to force it onto every task.

---

## FAQ

### "I already use Copilot at work. Should I add Claude Code at home?"

Yes if you want a terminal-first agent alongside Copilot. Claude Pro ($20/mo billed monthly) includes Claude Code usage with caps; the free Claude plan does not include Claude Code. ChatGPT Plus ($20/mo) is the equivalent entry point for OpenAI Codex.

### "Cursor or Claude Code — which one should I pick if I can only have one?"

If you live in an IDE and want everything in one place: Cursor. If you do a lot of terminal work, infra, or background agents: Claude Code. If your work is mixed, note that Claude Code also ships VS Code and JetBrains extensions and a desktop app, so the gap is smaller than it used to be.

### "Is GPT-6.1 Sol better than Claude Opus 5.5 for coding?"

They trade off depending on task, and vendor-reported benchmarks shift with every release (see [performance.md](../comparisons/performance.md) for sourced numbers). Use whichever your tool defaults to and switch only if you observe specific failure modes on your own workload.

### "How much does this actually cost in practice?"

For a working developer using AI heavily: $50-200/month covers tool subs + API usage for everything from chat to multi-file agent work. See [cost-analysis.md](../comparisons/cost-analysis.md) for the full breakdown by usage pattern.

### "Will the AI tool eat my codebase?"

Business and API offerings from the major vendors (for example Copilot Business/Enterprise, Cursor Teams, the Anthropic and OpenAI APIs) generally state they do not train on your code — confirm in each vendor's current data-usage terms. Free tiers vary — read each tool's privacy policy before using on sensitive code. Enable privacy mode where available. Use content exclusions for sensitive paths.

### "What about local / self-hosted models?"

Possible. Continue supports local models (Ollama, vLLM), and Copilot CLI can use your own OpenAI-compatible or Anthropic provider, including local models via Ollama, as long as the model supports tool calling and streaming. Open-weight models generally trail the current frontier models on agentic coding. Self-hosting matters most for privacy / compliance reasons, not for capability.

### "Do I need to learn prompt engineering?"

A little. The basics (specificity, context, structured requests) get you 90% of the value. See [prompting.md](../best-practices/prompting.md). The rest is muscle memory you build over a couple of weeks.

### "What's MCP and do I need it?"

MCP (Model Context Protocol) is the standard for connecting AI tools to external systems (databases, APIs, services). You don't need it on day one. By week 2 or 3, when you find yourself manually pasting info from the same source repeatedly, set up an MCP server for it. See [MCP Servers guide](mcp-servers/).

---

## Five-Minute Setup Path

If you want to start right now and read the rest later:

1. `curl -fsSL https://claude.ai/install.sh | bash` (macOS / Linux / WSL; Windows: `irm https://claude.ai/install.ps1 | iex`) — installs Claude Code. `npm install -g @anthropic-ai/claude-code` also works with Node.js 22+.
2. Run `claude` and follow the browser prompts — sign in with a Pro, Max, Team, Enterprise, or Console account (the free Claude plan doesn't include Claude Code), or set `ANTHROPIC_API_KEY` from [platform.claude.com](https://platform.claude.com/).
3. `cd` into a real repo. Create a 20-line `CLAUDE.md` describing the project.
4. Add `permissions.deny` entries to `.claude/settings.json` for secrets and junk paths (copy the template from [basic-setup.md](basic-setup.md)).
5. In the `claude` session, ask "What does this codebase do? What's the test command?"

If it answers reasonably, you're set up. Total time: under 10 minutes.

For Codex, the equivalent is `curl -fsSL https://chatgpt.com/codex/install.sh | sh`, then `codex` and "Sign in with ChatGPT". For Cursor: download Cursor, open the folder, open the agent panel, ask the question. Same 10 minutes.

---

## Team Rollout (Bonus)

If you're rolling out to a team:

### Week 1: Pilot
- 3-5 volunteer developers
- Pick one tool (Copilot Business, Cursor Teams, Claude Team, or ChatGPT Business are typical starting points)
- One project, one rules file, one shared `.claude/settings.json` (permissions) / `.cursorignore`
- Daily Slack thread for "what did you try, what worked"

### Week 2-3: Iterate
- Refine the rules file based on pilot feedback
- Add 2-3 shared skills / prompts
- Establish "AI-generated PR" review conventions (label, extra reviewer for sensitive areas)
- Decide on cost controls (per-seat or shared API key with budget)

### Week 4: Expand
- Roll out to next 10-20 developers
- Document onboarding (link this guide!)
- Set up cost alerts at provider level
- If running anything production-facing, start the governance conversation (see [agent-governance.md](../best-practices/agent-governance.md))

### Ongoing
- Quarterly tool review (re-evaluate vs new alternatives)
- Monthly cost review
- Continuous CLAUDE.md / rules file updates as conventions evolve
- Shared `skills/` or `prompts/` directory in the repo or dotfiles

The cultural piece matters more than the tool choice. Teams that share patterns and openly discuss failures get to productive use weeks faster than teams where each developer figures it out alone.

---

## Related

- [Basic Setup](basic-setup.md)
- [First Steps](first-steps.md)
- [Feature Matrix](../comparisons/feature-matrix.md)
- [Use Cases](../comparisons/use-cases.md)
- [Cost Analysis](../comparisons/cost-analysis.md)
