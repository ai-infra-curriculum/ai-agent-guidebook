# AI Coding Assistant Feature Comparison

Comparison of Claude Code, OpenAI Codex, GitHub Copilot, and Gemini CLI / Antigravity CLI, plus the AI editors (Cursor, VS Code, Google Antigravity).

Last updated 2026-10-21. Feature claims are checked against each vendor's docs as of October 2026; see each tool's guide for source-cited detail.

---

## Quick Comparison

| Feature | Claude Code | OpenAI Codex | GitHub Copilot | Gemini CLI / Antigravity CLI |
|---------|-------------|--------------|----------------|------------------------------|
| **Surfaces** | CLI, desktop app, VS Code + JetBrains extensions, Agent SDK | CLI, IDE extension, ChatGPT desktop/web/mobile, Codex Cloud | IDE extensions, Copilot CLI, cloud agent on GitHub | CLI (Antigravity CLI is the successor for consumer plans) |
| **Real-time Completions** | ❌ | ❌ | ✅ | ❌ |
| **MCP Server Support** | ✅ | ✅ | ✅ | ✅ |
| **Subagents / Multi-Agent** | ✅ Built-in + custom subagents, background agents, agent teams | ✅ Subagents | ⚠️ Custom agents; CLI delegates to specialized agents | ✅ Subagents |
| **Skills** | ✅ | ✅ Skills and plugins | ✅ Agent skills | ✅ Agent Skills |
| **Event Hooks** | ✅ | ✅ | ✅ (Copilot CLI) | ✅ |
| **Plan Mode** | ✅ | ⚠️ See [Codex guide](../guides/codex/README.md) | ✅ (Copilot CLI) | ⚠️ See guide |
| **Async Agent (issue → PR)** | ⚠️ Via GitHub Actions / background agents | ✅ Codex Cloud + GitHub code review | ✅ Copilot cloud agent | ❌ |
| **Project Instructions** | `CLAUDE.md` | `AGENTS.md` | `.github/copilot-instructions.md`, custom instructions | `GEMINI.md` |
| **Context Window** | 1M tokens (all current Claude models) | ~1.05M tokens (GPT-6 models) | Up to 1M on latest models | Model-dependent (Gemini 4 Argon: 1M) |
| **Pricing (as of Oct 2026)** | Claude Pro $20 / Max from $100, Team, or API | ChatGPT Free → Pro ($100-500), Business, or API key | Free / $10 / $39 / $100; Business $19, Enterprise $39 per user | Gemini CLI: paid API key or Code Assist Standard/Enterprise; Antigravity CLI: no charge for individuals |

Notes:

- **Gemini CLI status.** On June 18, 2026, Gemini CLI stopped serving free individual, Google AI Pro, and Google AI Ultra users, who moved to **Antigravity CLI**. Gemini CLI remains available to Gemini Code Assist Standard/Enterprise organizations and with paid Gemini API keys. Skills, hooks, subagents, and extensions (now "Antigravity plugins") carry over, without full parity at launch ([Google Developers Blog](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/)).
- **Codex** is new to this matrix; see the [Codex guide](../guides/codex/README.md).
- ⚠️ means partial support or not confirmed in primary docs for this revision.

The table above covers the CLI / assistant tools. The GUI editors and
agent-first IDEs below are a distinct category: full editing environments
rather than CLIs or extensions.

### AI Editors & Agentic IDEs

| Feature | Cursor | VS Code (agentic) | Google Antigravity |
|---------|--------|-------------------|--------------------|
| **Type** | AI-first editor (VS Code fork) | Editor + AI/agent layer (Copilot) | Agent-first platform: desktop app, IDE, CLI, Python SDK |
| **Real-time Completions** | ✅ Tab | ✅ (via Copilot) | ⚠️ Agent-centric |
| **Agent Mode** | ✅ Agent | ✅ Agent mode in chat | ✅ Agent manager; parallel local agents |
| **Plan Mode** | ✅ | ⚠️ Plan via agent | ✅ Plans / task lists |
| **MCP Server Support** | ✅ | ✅ `.vscode/mcp.json` | ✅ |
| **Custom Rules / Skills** | ✅ Rules, skills, plugins | ✅ instructions + `*.agent.md` | ✅ Skills, plugins |
| **Models** | Cursor's Composer models and Grok models; third-party models billed by usage | Copilot models, BYOK | Gemini models (Gemini 4 Argon for Google AI Pro/Ultra) |
| **Multi-Agent** | ⚠️ Cloud agents (Premium and up) | ⚠️ Agent mode | ✅ Multiple agents in parallel |
| **Platforms** | macOS, Windows, Linux | macOS, Windows, Linux | macOS, Windows, Linux |
| **Pricing (as of Oct 2026)** | Free / Plus $8 / Premium $30 / Super $100 / Ultra $200 / Teams $30+ per user | Free editor; Copilot $0-100/mo | No charge for individuals; higher limits on Google AI Pro/Ultra |

> Model lists, pricing tiers, and config paths for these editors change
> often. See each tool's guide for current, source-cited detail:
> [Cursor](../guides/cursor/), [VS Code](../guides/vscode/),
> [Antigravity](../guides/antigravity/).

---

## Detailed Comparison

### Code Completion

#### Claude Code
- **Type**: Conversational and agentic, no inline completions
- **Scope**: Multi-file, project-wide
- **Context**: 1M tokens on current models
- **Best For**: Complex refactoring, architecture changes
- **Limitations**: No real-time completions

#### OpenAI Codex
- **Type**: Conversational and agentic (local CLI/IDE, or cloud tasks), no inline completions
- **Scope**: Multi-file, project-wide
- **Context**: ~1.05M tokens on GPT-6 models
- **Best For**: Delegated tasks, parallel cloud tasks, PR review
- **Limitations**: No real-time completions

#### GitHub Copilot
- **Type**: Real-time inline suggestions, plus chat, agent mode, CLI, and cloud agent
- **Scope**: Inline completions are file-local; agent mode and the CLI work across the repo
- **Best For**: Writing code line-by-line; GitHub-native issue → PR flows

#### Gemini CLI / Antigravity CLI
- **Type**: Conversational and agentic, no inline completions
- **Context**: Model-dependent; Gemini 4 Argon documents a 1M window
- **Best For**: Terminal agent work in Google's ecosystem
- **Limitations**: Consumer users must move to Antigravity CLI (see notes above)

---

### Chat & Conversation

| | Claude Code | OpenAI Codex | GitHub Copilot | Gemini / Antigravity CLI |
|---|---|---|---|---|
| **Interface** | Terminal, desktop app, IDE panel | Terminal, IDE panel, ChatGPT apps | IDE sidebar + inline, terminal (CLI) | Terminal |
| **Multi-turn** | ✅ | ✅ | ✅ | ✅ |
| **Runs commands** | ✅ Bash / PowerShell tools | ✅ Sandboxed, with approval modes | ✅ Agent mode / CLI | ✅ |
| **Session resume** | ✅ | ✅ | ⚠️ | ⚠️ |

---

### Extensibility

#### Claude Code
- **MCP Servers**: ✅ Databases, infrastructure, APIs, quality tools
- **Skills**: ✅ Reusable task packs
- **Hooks**: ✅ Event-driven customization
- **Plugins**: ✅ Bundle skills, agents, hooks, MCP servers

#### OpenAI Codex
- **MCP**: ✅
- **Skills and plugins**: ✅
- **Hooks**: ✅
- **Config**: `AGENTS.md`, `config.toml`, sandboxing and permission profiles

#### GitHub Copilot
- **MCP**: ✅ Agent mode, CLI, and cloud agent
- **Custom agents**: ✅
- **Skills**: ✅
- **Hooks**: ✅ Copilot CLI runs shell commands at key points during agent execution

#### Gemini CLI / Antigravity CLI
- **Extensions / plugins**: ✅ (Gemini CLI extensions became Antigravity plugins)
- **MCP**: ✅
- **Skills and hooks**: ✅

**Takeaway**: All four now support MCP, skills, and hooks. The differences are in maturity, configuration surface, and ecosystem; compare the tool guides rather than the checkmarks.

---

### Multi-Agent Capabilities

#### Claude Code
- **Agent Types**: built-in Explore, Plan, and general-purpose subagents, plus custom subagents
- **Custom Agents**: `.claude/agents/*.md` with `name`, `description`, optional `tools` and `model` frontmatter
- **Spawning**: the Agent tool (renamed from Task in v2.1.63; `Task` still works as an alias)
- **Parallel Execution**: ✅ Background subagents run concurrently (20 by default); agent teams for coordinated sessions
- **Programmatic**: Claude Agent SDK (`claude-agent-sdk` for Python, `@anthropic-ai/claude-agent-sdk` for TypeScript)

#### OpenAI Codex
- **Subagents**: ✅ (see [Codex guide](../guides/codex/README.md))
- **Cloud tasks**: run in parallel in Codex Cloud environments

#### GitHub Copilot
- **Agents**: Agent mode, custom agents, Copilot CLI (delegates common tasks to specialized agents), cloud agent (issue → PR)
- **Third-party agents**: Pro+ and Max can delegate tasks to Claude and OpenAI Codex agents (preview)

#### Gemini CLI / Antigravity CLI
- **Subagents**: ✅ (Antigravity CLI manages background subagents)

---

### IDE Integration

| | Claude Code | OpenAI Codex | GitHub Copilot | Gemini / Antigravity CLI |
|---|---|---|---|---|
| **VS Code** | ✅ Official extension | ✅ IDE extension | ✅ | ⚠️ Antigravity IDE instead |
| **JetBrains** | ✅ Official plugin | ⚠️ See guide | ✅ | ❌ |
| **Vim/Neovim** | ⚠️ Runs in any terminal | ⚠️ Runs in any terminal | ✅ | ⚠️ Runs in any terminal |

**Winner**: GitHub Copilot for breadth of editor coverage and inline completions.

---

### Development Workflow

#### Claude Code
- **Best For**: Complex refactoring, multi-file changes, architecture design, research, long-running and multi-phase workflows
- **Workflow**: Conversational, task-oriented, with plan mode and subagents

#### OpenAI Codex
- **Best For**: Delegating well-scoped tasks (local or cloud), parallel task runs, automated PR review, CI use via API key
- **Workflow**: Task-oriented; sandboxed execution with approval modes

#### GitHub Copilot
- **Best For**: Daily coding, function implementation, test generation, quick completions, GitHub-native issue → PR
- **Workflow**: Real-time suggestions plus agent mode

#### Gemini CLI / Antigravity CLI
- **Best For**: Terminal agent work tied to Google Cloud or Gemini models
- **Workflow**: Conversational

---

### Context Management

| | Claude Code | OpenAI Codex | GitHub Copilot | Gemini / Antigravity CLI |
|---|---|---|---|---|
| **Context Window** | 1M tokens | ~1.05M (GPT-6 models) | Up to 1M on latest models | Model-dependent |
| **Project memory** | `CLAUDE.md` (also reads imports) | `AGENTS.md` | Custom instruction files | `GEMINI.md` |
| **Exclude files** | `permissions.deny` in `.claude/settings.json` | Sandbox / permission profiles | Org-level content exclusion | `.geminiignore` |

With every major tool at or near 1M tokens, context size no longer separates them. How well each tool *chooses* what to load (grep-first navigation, compaction, subagent isolation) matters more. See [context-management.md](../best-practices/context-management.md).

---

### Testing, Databases, Infrastructure, Documentation

All four agentic CLIs can run tests, linters, migrations, `kubectl`, and `terraform` through their shell tools, and all four can reach databases and cloud APIs through MCP servers. The practical differences:

- **Claude Code**: deepest local customization (hooks to enforce lint/test, skills, subagents for review). Strong for infra and database work through MCP.
- **OpenAI Codex**: sandboxed execution with approval modes; Codex Cloud and GitHub code review fit test-and-review loops on PRs.
- **GitHub Copilot**: test generation inline; code review in GitHub PRs; cloud agent runs in GitHub Actions.
- **Gemini / Antigravity CLI**: comparable shell and MCP access; tightest fit with Google Cloud.

---

### Cost

All prices as of October 2026; see [cost-analysis.md](cost-analysis.md) for full tables and sources.

#### Claude Code
- **Models**: Fable 5.1, Opus 5.5, Sonnet 5.5, Haiku 5.5
- **Pricing**: Claude Pro ($20/mo), Max (from $100/mo), Team, Enterprise, or per-token API (Sonnet 5.5 $2 / $10 per MTok)

#### OpenAI Codex
- **Models**: GPT-6 Astra, GPT-6.1 Sol, GPT-6 Luna
- **Pricing**: Included in ChatGPT Free, Go ($8), Plus ($20), Pro ($100/$200/$500), Business; or API key at API rates

#### GitHub Copilot
- **Free**: $0 (limited)
- **Pro**: $10/mo; **Pro+**: $39/mo; **Max**: $100/mo
- **Business**: $19/user/mo; **Enterprise**: $39/user/mo
- **Note**: Usage is metered in GitHub AI Credits (1 credit = $0.01)

#### Gemini CLI / Antigravity CLI
- **Gemini CLI**: paid Gemini API key (Gemini 3.8 Flash $0.75 / $3.75 per MTok) or a Gemini Code Assist Standard/Enterprise license
- **Antigravity**: no charge for individuals; higher limits with Google AI Pro/Ultra

**Winner**: Varies by usage pattern.

---

## Use Case Recommendations

| Use case | Pick | Why |
|----------|------|-----|
| Daily coding (inline) | GitHub Copilot | Real-time completions, broadest IDE coverage |
| Complex refactoring | Claude Code | Subagents, plan mode, hooks, deep customization |
| Delegated / parallel tasks | OpenAI Codex or Copilot cloud agent | Cloud task runs that end in a PR |
| Large codebase analysis | Any 1M-context tool | Context size is no longer a differentiator; use grep-first navigation |
| Infrastructure management | Claude Code | MCP + hooks + subagents for multi-step infra work |
| Test generation | Claude Code or Copilot | Agentic suites vs. inline speed |
| PR review | Copilot or Codex | GitHub-native review integrations |
| Google Cloud-centric work | Antigravity CLI / Gemini CLI | Native fit with Gemini and Google Cloud |
| Multi-phase projects | Claude Code | Agent orchestration, state persistence |

---

## Combined Usage Strategy

### Optimal Workflow

**Use GitHub Copilot for**: daily coding, real-time completions, quick functions, inline docs, GitHub PR review.

**Use Claude Code for**: project setup and architecture, complex multi-file refactoring, database and infrastructure work, multi-phase workflows, quality gates via hooks.

**Use OpenAI Codex for**: delegating scoped tasks to the cloud in parallel, automated PR review, CI jobs on an API key.

**Use Antigravity CLI / Gemini CLI for**: work centered on Gemini models or Google Cloud.

### Example: Building a New Feature

1. **Research** (Claude Code): Explore subagent maps the codebase; analyze requirements.
2. **Design** (Claude Code): plan mode produces an implementation plan for review.
3. **Implementation** (Copilot or Claude Code): completions for line-level work; agent for multi-file changes.
4. **Parallel side tasks** (Codex Cloud or Copilot cloud agent): docs, test backfill, small fixes as separate PRs.
5. **Testing** (Claude Code + Copilot): Claude generates suites; Copilot for quick fixes.
6. **Review** (Copilot or Codex code review on the PR, plus a human).
7. **Deployment** (Claude Code): K8s configs, CI/CD changes, monitoring.

---

## Summary

**Claude Code**:
- Best for: complex tasks, infrastructure, orchestration
- Unique: subagents, agent teams, skills, hooks, plugins, Agent SDK
- Weakness: no inline completions

**OpenAI Codex**:
- Best for: delegated and parallel tasks, PR review, CI automation
- Unique: local + cloud surfaces under one ChatGPT plan; sandboxing and approval modes
- Weakness: no inline completions

**GitHub Copilot**:
- Best for: daily coding, real-time completions, GitHub-native flows
- Unique: broadest IDE coverage, cloud agent, third-party agent delegation
- Weakness: deep customization is newer and spread across surfaces

**Gemini CLI / Antigravity CLI**:
- Best for: Gemini- and Google Cloud-centric work
- Unique: Antigravity platform (app, IDE, CLI, SDK) at no charge for individuals
- Weakness: consumer Gemini CLI was retired in June 2026; Antigravity CLI is not at full feature parity yet

**Recommendation**: Pair one agentic tool (Claude Code or Codex) with one IDE tool (Copilot or Cursor).

---

**Last Updated**: 2026-10-21
