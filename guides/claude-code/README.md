# Claude Code Guide

Complete guide to using Claude Code, Anthropic's agentic coding tool — available as a CLI, in VS Code and JetBrains, in the Claude Desktop app, on the web, and from mobile.

Last verified: 2026-10 (against [code.claude.com/docs](https://code.claude.com/docs/en/overview); latest release at time of writing: v2.1.306).

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Models](#models)
- [Core Features](#core-features)
- [MCP Servers](#mcp-servers)
- [Multi-Agent Orchestration](#multi-agent-orchestration)
- [Claude Skills](#claude-skills)
- [Event Hooks](#event-hooks)
- [Advanced Usage](#advanced-usage)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

Claude Code is an agentic coding tool that reads your codebase, edits files, runs commands, and integrates with your development tools. It provides:

- **AI-Assisted Coding** - Natural language to code changes, with checkpoints you can rewind
- **MCP Server Integration** - Connect databases, issue trackers, and internal APIs
- **Multi-Agent Systems** - Background and nested sub-agents, forks, agent teams, and script-driven [dynamic workflows](background-and-scheduled-work.md#dynamic-workflows)
- **Claude Skills** - Reusable task packs following the open [Agent Skills](https://agentskills.io) standard
- **Event Hooks** - Customize behavior with shell commands, HTTP calls, or model checks
- **Auto Mode** - A classifier reviews actions instead of prompting you (the interactive default since v2.1.283)
- **Background & Scheduled Work** - Background sessions (`claude agents`), `/goal`, `/loop`, and cloud scheduled tasks
- **Artifacts** - Publish live, shareable pages from a session to claude.ai
- **Plugins** - Bundle skills, agents, hooks, MCP servers, and output styles; install from marketplaces

### Key Differentiators

**vs GitHub Copilot:**
- More conversational and explanatory
- Multi-agent orchestration capabilities
- MCP server ecosystem for extended functionality
- Better for complex, multi-step workflows

**vs Gemini CLI:**
- Specialized for software engineering
- Deep IDE and tool integration via MCP
- Skills system for reusable workflows
- Agent orchestration for large projects

---

## Installation

### Prerequisites

- macOS 13+, Windows 10 1809+ / Server 2019+ (native or WSL 2), or Linux (Ubuntu 20.04+, Debian 10+, Alpine 3.19+)
- Node.js 22+ (only if installing via npm)
- A Claude subscription (Pro/Max/Team/Enterprise), a Claude Console (API) account, or a cloud provider (Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry). The free claude.ai plan doesn't include Claude Code.

### Install via native installer (recommended)

```bash
# macOS, Linux, WSL
curl -fsSL https://claude.ai/install.sh | bash
```

```powershell
# Windows PowerShell
irm https://claude.ai/install.ps1 | iex
```

Native installs auto-update in the background.

### Install via npm

```bash
npm install -g @anthropic-ai/claude-code
```

### Install via Homebrew (macOS) or WinGet (Windows)

```bash
brew install --cask claude-code
```

```powershell
winget install Anthropic.ClaudeCode
```

Homebrew and WinGet installs don't auto-update by default. Signed apt/dnf/apk repositories also exist. See [installation.md](installation.md) for details.

### First Run

```bash
# Start Claude Code from your project directory
cd /path/to/project
claude
```

### Configuration

Claude Code looks for configuration in:
- `~/.claude/settings.json` - User settings (model, permissions, hooks)
- `~/.claude.json` - User- and local-scoped MCP servers
- `.mcp.json` (project root) - Project-scoped MCP servers, committed to version control
- Project-specific: `.claude/` directory (`settings.json`, `settings.local.json`, skills, agents, rules, hooks, output styles)
- Managed settings deployed by your organization override all of the above

See [settings-and-permissions.md](settings-and-permissions.md).

---

## Models

Current Claude models (Anthropic API IDs; list prices per million input/output tokens from the [official pricing page](https://platform.claude.com/docs/en/about-claude/pricing)):

| Model | ID | Alias | Price (in / out) | Notes |
|-------|----|-------|------------------|-------|
| Claude Fable 5.1 | `claude-fable-5-1` | `fable` | $10 / $50 | Most capable; long-horizon, ambiguous work. Never the default; may bill to usage credits on subscriptions |
| Claude Opus 5.5 | `claude-opus-5-5` | `opus` | $4 / $20 | **Default model** on Pro, Max, Team, Enterprise, and the API since v2.1.280 |
| Claude Sonnet 5.5 | `claude-sonnet-5-5` | `sonnet` | $2 / $10 | Speed/intelligence balance |
| Claude Haiku 5.5 | `claude-haiku-5-5` | `haiku` | $0.10 / $0.50 (prompts ≤100K tokens; $0.50 / $2.50 above) | Fast, high-volume work |

All four have a 1M-token context window and 128K max output, and always use adaptive thinking (steer it with `/effort`). Switch with `/model <alias>` — the choice is saved as your default; press `s` in the picker for this session only. On Bedrock, Agent Platform, and Foundry, aliases may resolve to older models; pin full IDs there. Previous models (Fable 5, Opus 5, Sonnet 5, Opus 4.8 and earlier) remain available as legacy models.

## Core Features

### 1. Natural Language Interface

Ask Claude Code to perform tasks in natural language:

```
"Add authentication to this API"
"Refactor the UserService class to use dependency injection"
"Write tests for the payment processing module"
```

### 2. File Operations

Claude Code can:
- Read and write files
- Search codebases
- Refactor code
- Generate documentation
- Run commands

### 3. Context Awareness

- Automatically understands project structure
- Reads relevant files on demand
- Maintains conversation context
- Uses `permissions.deny` rules (e.g. `"Read(./.env)"`) in `.claude/settings.json` to keep sensitive files out of reach

### 4. Tool Integration

Built-in tools include:
- **Read** / **Write** / **Edit** - Read, create, and precisely edit files
- **Bash** (and **PowerShell** on Windows) - Execute shell commands, optionally in the background
- **Grep** / **Glob** - Search code and find files (on macOS, Linux, and WSL these are left out by default; Claude searches with embedded `grep`/`find` via Bash)
- **WebFetch** / **WebSearch** - Fetch pages and search the web
- **Agent** - Spawn sub-agents (formerly `Task`)
- **Monitor** - Watch a background command or WebSocket and react to each event
- **Skill**, **ToolSearch**, **LSP**, **Artifact**, and more — see the [tools reference](https://code.claude.com/docs/en/tools-reference)

---

## MCP Servers

Model Context Protocol servers extend Claude Code's capabilities.

### What are MCP Servers?

MCP servers provide external functionality:
- **Database access** - Query PostgreSQL, SQLite, etc.
- **API integration** - GitHub, Slack, Jira, etc.
- **File systems** - Enhanced file operations
- **Web services** - Fetch web content, search
- **Development tools** - Linting, testing, deployment

### Configuration

Add servers with the `claude mcp` CLI:

```bash
# stdio server (local process) — everything after -- runs the server
claude mcp add git -- uvx mcp-server-git

# HTTP server (remote); OAuth servers sign in via /mcp or `claude mcp login <name>`
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Remote server with a header, shared with your team via .mcp.json
# (\$ keeps the literal ${GITHUB_TOKEN} in the file; Claude Code expands it at connect time)
claude mcp add --scope project --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer \${GITHUB_TOKEN}"
```

Storage by scope: `local` and `user` scopes live in `~/.claude.json`; `project` scope lives in `.mcp.json` at the repo root (committed to version control):

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_TOKEN}"
      }
    },
    "notion": {
      "type": "http",
      "url": "https://mcp.notion.com/mcp"
    }
  }
}
```

### Popular MCP Servers

**Development:**
- GitHub's official server — hosted at `https://api.githubcopilot.com/mcp/` or self-hosted from `github/github-mcp-server` (the old `@modelcontextprotocol/server-github` npm package is archived and deprecated)
- `mcp-server-git` (Python, via `uvx`) - Git operations
- `@modelcontextprotocol/server-filesystem` - File operations outside the project (Claude Code's built-in file tools already cover the project itself)

**Databases:**
- `postgres-mcp` ("Postgres MCP Pro", via `uvx`) - PostgreSQL; the reference `@modelcontextprotocol/server-postgres` is archived
- `mcp-server-sqlite` (Python, via `uvx`) - SQLite

**Infrastructure:**
- `kubernetes-mcp-server` (from the `containers` GitHub org) - Kubernetes
- Docker MCP servers

Package names and maintenance status change often — check the catalog before adopting one.

**See full catalog**: [MCP Server Catalog](../mcp-servers/catalog.md)

### Installing MCP Servers

Claude Code doesn't install servers itself. For `npx`/`uvx` stdio servers, the package runner downloads the package the first time the server starts (and again after cache eviction); remote HTTP servers need no local install at all. Project-scoped servers from `.mcp.json` wait for your approval in `/mcp` before they connect in interactive sessions.

### Using MCP Servers

Once configured, Claude Code automatically uses appropriate servers:

```
"Create a new GitHub repository called 'my-project'"
→ Uses GitHub MCP server

"Query the users table in PostgreSQL"
→ Uses PostgreSQL MCP server

"Deploy to Kubernetes cluster"
→ Uses Kubernetes MCP server
```

---

## Multi-Agent Orchestration

Claude Code can spawn specialized agents for complex tasks.

### What are Agents?

Agents are autonomous Claude instances that:
- Focus on specific sub-tasks
- Run independently with their own context window (forks are the exception: they inherit the conversation)
- Run in the background by default, surfacing permission prompts in your main session
- Report results back to the orchestrator
- Can spawn their own sub-agents, up to three layers deep by default

### Agent Types

**Built-in Agents:**

1. **general-purpose** - Complex multi-step tasks
2. **Explore** - Read-only codebase exploration and search
3. **Plan** - Read-only research during plan mode

**Custom Agents:**

Define as Markdown files with YAML frontmatter in `.claude/agents/` (project) or `~/.claude/agents/` (user). Ask Claude to write one or create the file directly; `/tasks` shows running agents. (`/agents` no longer opens a management UI as of v2.1.198.)

### Using Agents

**Automatically:**
```
"Search the codebase for all authentication logic"
→ Claude spawns Explore agent
```

**Explicitly:**
```
"Use a general-purpose agent to refactor the entire API module"
@"code-reviewer (agent)" look at the auth changes
```

### Agent Configuration

**Project file**: `.claude/agents/<name>.md`

```markdown
---
name: code-reviewer
description: Review code for best practices and potential issues. Use after any code change.
tools: Read, Grep, Glob
model: sonnet
---

You are a code reviewer. For each file named by the orchestrator, check
naming, error handling, and test coverage, and report issues with
file:line references.
```

Only `name` and `description` are required. The `description` is what the orchestrator uses to decide when to delegate; the markdown body becomes the agent's system prompt.

### Agent Communication

Agents communicate via:
- **Input**: Task description and context
- **Output**: Results and findings
- **SendMessage**: Resume a finished sub-agent, message agent-team teammates, or reach your other Claude Code sessions
- **Files**: Shared state written to disk (or an MCP server such as a memory server)

### Multi-Phase Workflows

Use multiple agents for complex workflows:

```markdown
# Phase 1: Research (research-agent)
- Analyze requirements
- Research best practices

# Phase 2: Design (architecture-agent)
- Create system design
- Define interfaces

# Phase 3: Implementation (coding-agent)
- Write code
- Create tests

# Phase 4: Quality Assurance (qa-agent)
- Review code
- Run tests
- Security scan
```

See: [Agent Architecture Guide](../agents-subagents/architecture.md)

---

## Claude Skills

Skills are reusable task packs for common workflows.

### What are Skills?

Skills package:
- Prompts and instructions
- Tool configurations
- Workflow definitions
- Best practices

### Using Skills

**Invoke a skill:**
```bash
# In Claude Code
/skill-name

# Or
"Use the code-review skill on src/api/"
```

### Available Skills

Skills are defined in:
- Bundled skills (ship with Claude Code and plugins)
- Project skills (`.claude/skills/`)
- User skills (`~/.claude/skills/`)

### Creating Skills

**Location**: `.claude/skills/my-skill/`

```
my-skill/
├── SKILL.md            # YAML frontmatter + instructions
├── runbook.md          # Optional supporting reference
├── scripts/            # Optional helper scripts
└── examples/           # Example usage
```

**SKILL.md:**
```markdown
---
name: code-validator
description: |
  Validate code quality through automated checks. Use when the user asks to
  "validate", "check code quality", or before a release.
allowed-tools: Bash(ruff *), Bash(pytest *)
---

# Code Validator Skill

Validate code quality through automated linting, testing, and security scanning.

## Process

1. Run Ruff linting on all Python files
2. Execute pytest test suite
3. Run Bandit security scan
4. Generate quality report

## Output

Provide a summary of:
- Linting issues found
- Test results (pass/fail counts)
- Security vulnerabilities
- Actionable recommendations
```

The frontmatter `name` (or, if omitted, the directory name) becomes the slash command (`/code-validator`); the `description` is what Claude uses to decide when to load the skill automatically. `allowed-tools` *pre-approves* those tools for the invoking turn — it doesn't restrict others. Claude Code also ships bundled skills such as `/code-review`, `/simplify`, `/doctor`, `/loop`, and `/verify`.

See: [Skills Guide](../skills/guide.md)

---

## Event Hooks

Hooks customize Claude Code behavior at specific events.

### What are Hooks?

Hooks are handlers — shell commands, HTTP endpoints, MCP tools, or model/agent checks — that run:
- Before/after tool calls
- On ~30 lifecycle events (prompts, compaction, sub-agents, model switches, file changes, …)
- For validation or side effects

### Hook Types

Core lifecycle events:

- `UserPromptSubmit` - After the user submits a prompt, before the model sees it
- `PreToolUse` / `PostToolUse` - Before/after tool calls
- `SessionStart` / `SessionEnd` - When the session starts/ends
- `Stop` - When the assistant turn ends

See [hooks.md](hooks.md) for the rest.

### Configuration

Configured in `settings.json` (`~/.claude/settings.json` or `.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/validate-tool-call.sh" }
        ]
      }
    ]
  }
}
```

Hooks receive a JSON event description on stdin (including `tool_name` and `tool_input`). Exit code 2 blocks the action and surfaces stderr to the model. In interactive sessions, hooks run only after you accept the workspace trust dialog; `claude -p` treats the folder as trusted, so review a repo's `.claude/settings.json` before scripting against it.

### Example Hooks

**Pre-commit validation:**
```bash
#!/bin/bash
# .claude/hooks/pre-commit.sh — wire to PreToolUse with matcher "Bash"
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Run tests before git commit
if [[ "$command" == git\ commit* ]]; then
  pytest tests/ || { echo "Tests failing — fix before committing." >&2; exit 2; }
fi
```

**Logging:**
```bash
# Log all tool calls (PostToolUse, matcher "*")
input=$(cat)
echo "$(date): $(echo "$input" | jq -r '.tool_name')" >> .claude/tool-log.txt
```

---

## Advanced Usage

### 1. Context Management

**Optimize token usage:**

There is no `.claudeignore` file — keep noise and secrets out of context with `permissions.deny` rules in `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  }
}
```

**Provide focused context:**
```
"Review the authentication logic in src/auth/auth.service.ts:45-120"
```

### 2. Checkpoint System

Claude Code automatically checkpoints the state of your code before each edit; every user prompt creates a new checkpoint. To undo, run `/rewind` (or press `Esc` twice with an empty prompt) and choose whether to restore the code, the conversation, or both. Note: files changed by bash commands are not tracked.

For long or parallel work, see [background-and-scheduled-work.md](background-and-scheduled-work.md): background sessions (`claude --bg`, `claude agents`), `/goal`, `/loop`, and cloud scheduled tasks.

### 3. Parallel Operations

Run multiple agents in parallel:

```
"Launch three agents in parallel:
- Agent 1: Generate unit tests
- Agent 2: Update documentation
- Agent 3: Refactor utilities"
```

### 4. Memory Persistence

Durable project facts belong in `CLAUDE.md` (ask Claude to add them). Claude Code also has built-in **auto memory**, where Claude saves its own notes about your preferences and project across sessions; review and edit it with `/memory`. See [claude-md.md](claude-md.md).

```
"Add to the project CLAUDE.md: we use PostgreSQL 16 and Alembic for migrations"
```

### 5. Custom Tools

Add custom tools via MCP servers:

```typescript
// my-custom-tool/index.ts
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';

const server = new McpServer({
  name: 'my-custom-tool',
  version: '1.0.0'
});

server.registerTool(
  'custom-operation',
  {
    description: 'Perform custom operation',
    inputSchema: { /* zod shape */ }
  },
  async (params) => {
    // Implementation
    return { content: [{ type: 'text', text: 'done' }] };
  }
);
```

---

## Best Practices

### Prompting

✅ **Be Specific**
```
❌ "Fix the bug"
✅ "Fix the null pointer exception in UserService.getUser() at line 45"
```

✅ **Provide Context**
```
"We're using NestJS with TypeORM. Add authentication middleware that validates JWT tokens and attaches user info to the request."
```

✅ **Break Down Complex Tasks**
```
"Let's implement user registration in phases:
1. Create the User entity and database migration
2. Implement the registration service
3. Add the registration controller endpoint
4. Write tests"
```

### Project Organization

✅ **Use CLAUDE.md**
- Document project structure
- Define workflows
- List key conventions

✅ **Define sub-agents in `.claude/agents/`**
- One Markdown file per agent, with frontmatter
- Document agent responsibilities in sharp `description` fields
- Restrict each agent's `tools` to the minimum needed

✅ **Use AGENTS.md**
- A shared instructions file read by many coding agents
- Claude Code reads it natively only when there's no `CLAUDE.md`; if you have both, start `CLAUDE.md` with `@AGENTS.md`

✅ **Configure MCP Servers**
- Install relevant servers
- Configure environment variables
- Test connections

### Code Quality

✅ **Review Generated Code**
- Always review before committing
- Test thoroughly
- Validate security implications

✅ **Iterative Refinement**
```
"The authentication implementation looks good, but let's add rate limiting"
"Can we optimize this database query?"
```

### Security

✅ **Never Commit Secrets**
```bash
# Use environment variables
GITHUB_TOKEN=xxx claude

# Or .env files (add to .gitignore)
echo "GITHUB_TOKEN=xxx" > .env
```

✅ **Review Security-Sensitive Code**
- Authentication logic
- Input validation
- API endpoints
- Database queries

---

## Troubleshooting

### Common Issues

#### MCP Server Not Found

**Problem**: "MCP server 'xyz' not configured"

**Solution**:
```bash
# Check configured servers
claude mcp list
claude mcp get <name>

# Add the missing server
claude mcp add <name> -- <command> [args...]
```

#### Tool Execution Failed

**Problem**: Bash commands fail or hang

**Solution**:
```bash
# Check command syntax
# Use absolute paths
# Set appropriate timeout
```

#### Context Window Full

**Problem**: "Prompt is too long" / context limit reached

**Solution**:
- Run `/compact` to summarize older turns (auto-compaction normally does this near the limit)
- Be more specific about files to read
- Use agents for sub-tasks
- Clear conversation (`/clear`) and start fresh

#### Agent Timeout

**Problem**: Agent doesn't complete

**Solution**:
- Check `/tasks` — sub-agents run in the background by default and may simply still be working
- Break task into smaller steps; set `maxTurns` in the agent definition
- Use checkpoints

### Getting Help

- **Documentation**: https://code.claude.com/docs/en/overview
- **GitHub Issues**: https://github.com/anthropics/claude-code/issues
- **Community**: https://github.com/anthropics/claude-code/discussions

---

## Related Guides

- [Background and Scheduled Work](background-and-scheduled-work.md)
- [MCP Servers Guide](../mcp-servers/guide.md)
- [Agent Architecture](../agents-subagents/architecture.md)
- [Skills Guide](../skills/guide.md)
- [CLAUDE.md Template](../../templates/CLAUDE.md)
- [AGENTS.md Template](../../templates/AGENTS.md)

---

## Resources

- **Official Docs**: https://code.claude.com/docs/en/overview
- **Changelog**: https://code.claude.com/docs/en/changelog (weekly digests: https://code.claude.com/docs/en/whats-new/index)
- **MCP Specification**: https://modelcontextprotocol.io/specification
- **Awesome MCP**: https://github.com/wong2/awesome-mcp-servers
- **MCP Directory**: https://mcpservers.org/

---

**Next Steps:**
1. [Install Claude Code](#installation)
2. [Write a lean CLAUDE.md](claude-md.md) for your project
3. [Configure settings & permissions](settings-and-permissions.md) to cut approval prompts
4. [Configure MCP Servers](mcp-servers.md)
5. [Try your first agent](agents.md#what-the-agent-tool-does)
6. [Run work in the background](background-and-scheduled-work.md)

**Configuration deep dives:** [CLAUDE.md & memory](claude-md.md) · [Settings & permissions](settings-and-permissions.md) · [Event hooks](hooks.md) · [Advanced usage](advanced.md) · [Background & scheduled work](background-and-scheduled-work.md) — plus the cross-tool [agentic workflow](../../best-practices/agentic-workflow.md).
