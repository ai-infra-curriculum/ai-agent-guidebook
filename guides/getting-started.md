# Getting Started

Three-question decision tree, choose-your-tool flowchart, and cross-links to detailed install guides.

Last updated 2026-05.

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
  $0 ── Cursor Free        IDE ──► Cursor                │
        Copilot Free                                     │
                           Terminal ──► Claude Code      │
  $10-30 ── Copilot Pro                                  │
            Cursor Pro     Both ──► Cursor + Claude      │
                          Code combination               │
  $50+ ── Cursor Pro                                     │
          + Claude Code Max                              │
                                              ┌─────────┴─────────┐
                                              │                   │
                                       Whole repo            Background
                                       Q&A / docs            agents
                                              │                   │
                                              ▼                   ▼
                                     Gemini CLI (free        Claude Code
                                     tier, 2M context)       (--print mode)
                                     or Cody (multi-repo)    + governance
                                                             at scale
```

---

## Recommendations

### Solo / hobbyist, no budget

- **Cursor Free** (50 slow + 2K completions/mo) is the most generous free tier with a real IDE.
- Add **Gemini CLI** for big-context Q&A on the side (free Vertex AI Studio tier).
- Optional: **GitHub Copilot Free** if you maintain OSS or want a second opinion.

Setup time: 30 minutes.

### Solo developer, $10-30 budget

Pick one:

- **GitHub Copilot Pro ($10/mo)** if you live in VS Code or JetBrains and want polished inline completions plus agent mode.
- **Cursor Pro ($20/mo)** if you want a richer agent-mode experience and don't mind switching to a VS Code fork.

If unsure, try Cursor first. Most developers find the agent experience more leveraging than Copilot's inline completions.

### Solo power user, $50-200 budget

Combination:

- **Cursor Pro ($20)** for daily IDE work.
- **Claude Code via Claude Pro ($20)** or **Max 5x ($100)** for terminal, multi-file refactors, agent work.
- Optional: **Copilot Pro ($10)** for inline completions if you prefer Copilot's specific tab-completion behavior.

Total: $40-130/mo. Covers all common workflows.

### Heavy user, $200+ budget

- **Cursor Ultra ($200)** or **Cursor Business** for unlimited premium requests.
- **Claude Code Max 5x ($100)** or direct API billing.
- **Gemini CLI** for large analysis (free or pay-as-you-go).
- Optional: **Cody Pro ($9)** if you have multi-repo work.

Total: $300-400/mo. You will recoup it in saved time within days.

### Team

See [cost-analysis.md](../comparisons/cost-analysis.md) Team scenarios. Default starting point for most teams:

- **Cursor Business ($40/user/mo)** as the daily driver
- **Claude Code via Anthropic API** with team budget for terminal / agent work
- **Observability tooling** (LangSmith free tier or Langfuse self-hosted) from day one if you're building anything beyond chat

### Enterprise / regulated

See [agent-governance.md](../best-practices/agent-governance.md). The tool layer is the easy part. The governance, identity, audit, and compliance layer is what determines time to production.

---

## What to Do Next

After picking a tool:

1. **Install it.** See [basic-setup.md](basic-setup.md) for the generic walkthrough.
2. **Sign in and run hello-world.** Verify the tool works on a throwaway file.
3. **Set up `.gitignore` / `.claudeignore` / `.cursorignore`.** Prevent the tool from indexing junk. See [context-management.md](../best-practices/context-management.md).
4. **Write project rules.** CLAUDE.md, AGENTS.md, .cursorrules, .github/copilot-instructions.md — whichever your tool reads. Start with 20 lines of project-specific conventions.
5. **Try a real task.** Pick something small but real. See [first-steps.md](first-steps.md).

For tool-specific deep dives:

- [Claude Code Guide](claude-code/) — installation, configuration, MCP servers, skills
- [GitHub Copilot Guide](github-copilot/) — IDE setup, Workspace, agent mode
- [Gemini CLI Guide](gemini-cli/) — installation, large-context patterns
- [Agents & Subagents Guide](agents-subagents/) — multi-agent design
- [MCP Servers Guide](mcp-servers/) — installing and writing MCP servers
- [Skills Guide](skills/) — writing reusable skill packs

---

## If You Already Have a Tool

If you already use one tool and you're wondering if you should add another:

| You have | Consider adding | Why |
|----------|-----------------|-----|
| Copilot | Claude Code | Multi-file refactors and agent workflows Copilot doesn't do |
| Copilot | Cursor | If you find Copilot's inline-only model limiting |
| Cursor | Claude Code | Terminal / agent / background workflows |
| Cursor | Gemini CLI | Whole-repo Q&A beyond 200K context |
| Claude Code | Cursor | Inline IDE experience for daily coding |
| Claude Code | Copilot | Inline completions if you live in VS Code |
| Gemini CLI | Cursor or Claude Code | Anything that needs deep tool use |
| Cody | Anything with agent mode | Cody is great for Q&A, less for active edits |

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
8. **Cheap-tier-only.** Haiku 4.5 / Gemini Flash are amazing for routing and simple tasks; they fail on hard ones. Use Sonnet / Opus / GPT-5 / Gemini Pro when the task demands it.
9. **Ignoring cost dashboards.** Agents in loops can burn $100 in an hour. Set spend limits before you need them.
10. **Skipping security review on AI-generated code.** "It compiles" is not "it's safe."

---

## Three-Sentence Summary

If you write code daily in an IDE, install Cursor or Copilot Pro and use it for everything. If you need multi-file refactors, background agents, or DevOps tooling, also install Claude Code. If you need to understand a huge codebase, also install Gemini CLI for its 2M-token context.

---

## Decision Matrix (Quick Reference)

When you can't decide and want a one-line answer:

| Constraint | Pick |
|------------|------|
| Cheapest, IDE | Cursor Free or Copilot Free |
| Cheapest, terminal | Gemini CLI (free Vertex tier) |
| Best inline completion (typing experience) | GitHub Copilot Pro |
| Best agent mode in IDE | Cursor Pro |
| Best for multi-file refactors | Claude Code (Sonnet 4.6) |
| Best for whole-repo Q&A | Gemini CLI (2M context) |
| Best for multi-repo Q&A | Sourcegraph Cody |
| Best for infra / DevOps | Claude Code with MCP servers |
| Best for spec → PR flow | GitHub Copilot Workspace |
| Best for background agents | Claude Code --print mode |
| Best for regulated / enterprise | Claude Code + governance platform (see [agent-governance.md](../best-practices/agent-governance.md)) |

---

## What Each Tool Is Not For

Sometimes the clearest decision is what to rule out:

- **Copilot is not the right tool for** multi-file architecture changes, infra work, background agents, or whole-repo Q&A.
- **Cursor is not the right tool for** anything you need to run unattended in CI, or anything that primarily lives outside the IDE.
- **Claude Code is not the right tool for** inline completion while typing, IDE-integrated debugging, or visual previews.
- **Gemini CLI is not the right tool for** active multi-step coding sessions; it's better at large reads and one-shot analysis.
- **Cody is not the right tool for** deep agent workflows; it shines as a Q&A tool with strong repo context.

The mistake is buying the most popular tool and trying to force it onto every task.

---

## FAQ

### "I already use Copilot at work. Should I add Claude Code at home?"

Yes if you find yourself wanting agent-mode and multi-file capabilities Copilot doesn't have. The Claude Pro $20/mo subscription includes Claude Code usage with reasonable caps; many developers use it for personal projects as a complement to Copilot at work.

### "Cursor or Claude Code — which one should I pick if I can only have one?"

If you live in an IDE and want everything in one place: Cursor. If you do a lot of terminal work, infra, or background agents: Claude Code. If you genuinely can only have one and your work is mixed: Cursor edges out for most developers because the IDE integration covers more cases.

### "Is GPT-5 better than Claude Sonnet 4.6 for coding?"

They trade off depending on task. Aider polyglot benchmark and SWE-bench show them within a few percentage points of each other in 2026. Claude Sonnet 4.6 tends to win on long agent loops; GPT-5 Codex tends to win on tight inline completion. Use whichever your tool defaults to and switch only if you observe specific failure modes.

### "How much does this actually cost in practice?"

For a working developer using AI heavily: $50-200/month covers tool subs + API usage for everything from chat to multi-file agent work. See [cost-analysis.md](../comparisons/cost-analysis.md) for the full breakdown by usage pattern.

### "Will the AI tool eat my codebase?"

Most paid subscriptions (Cursor Business+, Copilot Business+, Anthropic API) do not train on your code. Free tiers vary — read each tool's privacy policy before using on sensitive code. Enable privacy mode where available. Use content exclusions for sensitive paths.

### "What about local / self-hosted models?"

Possible. Cursor and Continue support Bring-Your-Own-Key for local models (Ollama, vLLM). Quality is lower than frontier models in 2026 — Llama 4 70B is competitive with GPT-4-class models but not with Sonnet 4.6 or GPT-5. Self-hosting matters most for privacy / compliance reasons, not for capability.

### "Do I need to learn prompt engineering?"

A little. The basics (specificity, context, structured requests) get you 90% of the value. See [prompting.md](../best-practices/prompting.md). The rest is muscle memory you build over a couple of weeks.

### "What's MCP and do I need it?"

MCP (Model Context Protocol) is the standard for connecting AI tools to external systems (databases, APIs, services). You don't need it on day one. By week 2 or 3, when you find yourself manually pasting info from the same source repeatedly, set up an MCP server for it. See [MCP Servers guide](mcp-servers/).

---

## Five-Minute Setup Path

If you want to start right now and read the rest later:

1. `npm install -g @anthropic-ai/claude-code` — installs Claude Code.
2. `claude /login` — opens browser, sign in with your Anthropic account (or set `ANTHROPIC_API_KEY` from [console.anthropic.com](https://console.anthropic.com)).
3. `cd` into a real repo. Create a 20-line `CLAUDE.md` describing the project.
4. Add a `.claudeignore` (copy the template from [basic-setup.md](basic-setup.md)).
5. Run `claude` and ask "What does this codebase do? What's the test command?"

If it answers reasonably, you're set up. Total time: under 10 minutes.

For Cursor, the equivalent is: download Cursor, open the folder, press `Cmd/Ctrl + L`, ask the question. Same 10 minutes.

---

## Team Rollout (Bonus)

If you're rolling out to a team:

### Week 1: Pilot
- 3-5 volunteer developers
- Pick one tool (Cursor Business or Copilot Business is the typical starting point)
- One project, one rules file, one shared `.claudeignore` / `.cursorignore`
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
