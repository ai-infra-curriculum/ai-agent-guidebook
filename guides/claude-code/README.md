# Claude Code Guide

Complete guide to using Claude Code, Anthropic's official CLI for AI-assisted development.

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
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

Claude Code is an interactive CLI tool that helps with software engineering tasks. It provides:

- **AI-Assisted Coding** - Natural language to code generation
- **MCP Server Integration** - Extend functionality with 50+ servers
- **Multi-Agent Systems** - Spawn specialized agents for complex tasks
- **Claude Skills** - Reusable task packs and workflows
- **Event Hooks** - Customize behavior with shell commands
- **Context Management** - Efficient token usage

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

- macOS 13+, Windows 10 1809+ (native or WSL 2), or Linux (Ubuntu 20.04+, Debian 10+)
- Node.js 18+ (only if installing via npm)
- A Claude subscription (Pro/Max/Team/Enterprise) or Anthropic API access

### Install via native installer (recommended)

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### Install via npm

```bash
npm install -g @anthropic-ai/claude-code
```

### Install via Homebrew (macOS)

```bash
brew install --cask claude-code
```

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
- Project-specific: `.claude/` directory (settings, skills, agents, hooks)

---

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

Built-in tools:
- **Read** - Read files
- **Write** - Create/modify files
- **Edit** - Precise file edits
- **Bash** - Execute shell commands
- **Grep** - Search code
- **Glob** - Find files by pattern

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
claude mcp add github -- npx -y @modelcontextprotocol/server-github

# HTTP server (remote)
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Pass environment variables, share with your team via .mcp.json
claude mcp add --scope project --env GITHUB_TOKEN=ghp_xxx github -- \
  npx -y @modelcontextprotocol/server-github
```

Storage by scope: `local` and `user` scopes live in `~/.claude.json`; `project` scope lives in `.mcp.json` at the repo root (committed to version control):

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
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
- `@modelcontextprotocol/server-github` - GitHub operations
- `@modelcontextprotocol/server-filesystem` - File operations
- `@modelcontextprotocol/server-git` - Git operations

**Databases:**
- `@modelcontextprotocol/server-postgres` - PostgreSQL
- `@modelcontextprotocol/server-sqlite` - SQLite

**Infrastructure:**
- `@containers/kubernetes-mcp-server` - Kubernetes
- Docker MCP servers

**Quality Assurance:**
- `@mojoatomic/quality-guard-mcp` - Code quality
- `@MarcusJellinghaus/mcp-code-checker` - Testing
- `@drewsonne/ruff-mcp-server` - Python linting

**See full catalog**: [MCP Server Catalog](../mcp-servers/catalog.md)

### Installing MCP Servers

MCP servers are installed automatically on first use:

```bash
# Claude Code will install when needed
# No manual npm install required
```

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
- Run independently with their own context
- Report results back to the orchestrator
- Cannot spawn further sub-agents (nesting is limited to one level)

### Agent Types

**Built-in Agents:**

1. **general-purpose** - Complex multi-step tasks
2. **Explore** - Codebase exploration and search
3. **Plan** - Task planning and breakdown

**Custom Agents:**

Define as Markdown files with YAML frontmatter in `.claude/agents/` (project) or `~/.claude/agents/` (user). Manage interactively with the `/agents` command.

### Using Agents

**Automatically:**
```
"Search the codebase for all authentication logic"
→ Claude spawns Explore agent
```

**Explicitly:**
```
"Use a general-purpose agent to refactor the entire API module"
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
- **Memory**: Shared state via Memory MCP

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

The directory name becomes the slash command (`/code-validator`); the `description` is what Claude uses to decide when to load the skill automatically.

See: [Skills Guide](../skills/guide.md)

---

## Event Hooks

Hooks customize Claude Code behavior at specific events.

### What are Hooks?

Hooks are shell commands that run:
- Before/after tool calls
- On specific events
- For validation or side effects

### Hook Types

Core lifecycle events:

- `UserPromptSubmit` - After the user submits a prompt, before the model sees it
- `PreToolUse` / `PostToolUse` - Before/after tool calls
- `SessionStart` / `SessionEnd` - When the session starts/ends
- `Stop` - When the assistant turn ends

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

Hooks receive a JSON event description on stdin (including `tool_name` and `tool_input`). Exit code 2 blocks the action and surfaces stderr to the model.

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

### 3. Parallel Operations

Run multiple agents in parallel:

```
"Launch three agents in parallel:
- Agent 1: Generate unit tests
- Agent 2: Update documentation
- Agent 3: Refactor utilities"
```

### 4. Memory Persistence

Use Memory MCP for cross-session state:

```
"Remember that we're using PostgreSQL for this project"
"What database are we using?" → "PostgreSQL"
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
- Document project conventions for any agent tool, not just Claude Code

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

**Problem**: "Context window exceeded"

**Solution**:
- Run `/compact` to summarize older turns
- Be more specific about files to read
- Use agents for sub-tasks
- Clear conversation (`/clear`) and start fresh

#### Agent Timeout

**Problem**: Agent doesn't complete

**Solution**:
- Break task into smaller steps
- Use checkpoints
- Increase timeout if possible

### Getting Help

- **Documentation**: https://code.claude.com/docs/en/overview
- **GitHub Issues**: https://github.com/anthropics/claude-code/issues
- **Community**: https://github.com/anthropics/claude-code/discussions

---

## Related Guides

- [MCP Servers Guide](../mcp-servers/guide.md)
- [Agent Architecture](../agents-subagents/architecture.md)
- [Skills Guide](../skills/guide.md)
- [CLAUDE.md Template](../../templates/CLAUDE.md)
- [AGENTS.md Template](../../templates/AGENTS.md)

---

## Resources

- **Official Docs**: https://code.claude.com/docs/en/overview
- **MCP Specification**: https://spec.modelcontextprotocol.io/
- **Awesome MCP**: https://github.com/wong2/awesome-mcp-servers
- **MCP Directory**: https://mcpservers.org/

---

**Next Steps:**
1. [Install Claude Code](#installation)
2. [Write a lean CLAUDE.md](claude-md.md) for your project
3. [Configure settings & permissions](settings-and-permissions.md) to cut approval prompts
4. [Configure MCP Servers](mcp-servers.md)
5. [Try your first agent](agents.md#quick-start)

**Configuration deep dives:** [CLAUDE.md & memory](claude-md.md) · [Settings & permissions](settings-and-permissions.md) · [Event hooks](hooks.md) · [Advanced usage](advanced.md) — plus the cross-tool [agentic workflow](../../best-practices/agentic-workflow.md).
