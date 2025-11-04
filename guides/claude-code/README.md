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

- Node.js 18+ or Bun
- macOS or Linux (Windows via WSL)
- API access to Claude

### Install via npm

```bash
npm install -g @anthropic-ai/claude-code
```

### Install via Homebrew (macOS)

```bash
brew install anthropic/claude/claude-code
```

### First Run

```bash
# Start Claude Code
claude-code

# Or specify a directory
claude-code /path/to/project
```

### Configuration

Claude Code looks for configuration in:
- `~/.config/claude-code/mcp.json` - MCP servers
- `~/.config/claude-code/.env` - Environment variables
- Project-specific: `.claude/` directory

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
- Uses `.claudeignore` to exclude files

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

**Location**: `~/.config/claude-code/mcp.json`

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
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/project"
      ]
    },
    "memory": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-memory",
        "--memory-path",
        "/path/to/memory"
      ]
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
- Can spawn their own sub-agents

### Agent Types

**Built-in Agents:**

1. **general-purpose** - Complex multi-step tasks
2. **Explore** - Codebase exploration and search
3. **Plan** - Task planning and breakdown

**Custom Agents:**

Define in project's `AGENTS.md` file (see templates).

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

**Project file**: `AGENTS.md`

```markdown
# Project Agents

## code-reviewer
Review code for best practices and potential issues.
Tools: Read, Grep, Quality-Guard MCP

## test-generator
Generate comprehensive test suites.
Tools: Read, Write, pytest, code-checker MCP

## documentation-writer
Create API documentation and guides.
Tools: Read, Write, filesystem MCP
```

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
- System skills (built-in)
- Project skills (`.claude/skills/`)
- User skills (`~/.config/claude-code/skills/`)

### Creating Skills

**Location**: `.claude/skills/my-skill/`

```
my-skill/
├── skill.json          # Skill metadata
├── prompt.md           # Main prompt
├── tools.json          # Required tools/MCP servers
└── examples/           # Example usage
```

**skill.json:**
```json
{
  "name": "code-validator",
  "description": "Validate code quality through automated checks",
  "version": "1.0.0",
  "tools": ["ruff-mcp", "code-checker"],
  "triggers": ["validate", "check code quality"]
}
```

**prompt.md:**
```markdown
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

- `user-prompt-submit-hook` - After user submits prompt
- `tool-call-hook` - Before/after tool calls
- `session-start-hook` - When session starts
- `session-end-hook` - When session ends

### Configuration

**Settings**: Preferences → Hooks

```json
{
  "hooks": {
    "user-prompt-submit-hook": "echo 'Processing...'",
    "tool-call-hook": "./scripts/validate-tool-call.sh"
  }
}
```

### Example Hooks

**Pre-commit validation:**
```bash
#!/bin/bash
# .claude/hooks/pre-commit.sh

# Run tests before git commit
if [[ "$TOOL_NAME" == "Bash" ]] && [[ "$COMMAND" == git\ commit* ]]; then
  pytest tests/ || exit 1
fi
```

**Logging:**
```bash
# Log all tool calls
echo "$(date): $TOOL_NAME - $DESCRIPTION" >> .claude/tool-log.txt
```

---

## Advanced Usage

### 1. Context Management

**Optimize token usage:**

```bash
# Create .claudeignore
cat > .claudeignore << EOF
node_modules/
*.log
.git/
dist/
build/
EOF
```

**Provide focused context:**
```
"Review the authentication logic in src/auth/auth.service.ts:45-120"
```

### 2. Checkpoint System

Save progress for long-running tasks:

```
"Save a checkpoint of the current progress"
"Resume from the last checkpoint"
```

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
import { MCPServer } from '@modelcontextprotocol/sdk';

const server = new MCPServer({
  name: 'my-custom-tool',
  version: '1.0.0'
});

server.tool({
  name: 'custom-operation',
  description: 'Perform custom operation',
  parameters: { /* ... */ },
  handler: async (params) => {
    // Implementation
  }
});
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

✅ **Use AGENTS.md**
- Define specialized agents
- Document agent responsibilities
- Define communication protocols

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
GITHUB_TOKEN=xxx claude-code

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
# Check MCP configuration
cat ~/.config/claude-code/mcp.json

# Add missing server
# Edit mcp.json to include server
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
- Use .claudeignore
- Be more specific about files to read
- Use agents for sub-tasks
- Clear conversation and start fresh

#### Agent Timeout

**Problem**: Agent doesn't complete

**Solution**:
- Break task into smaller steps
- Use checkpoints
- Increase timeout if possible

### Getting Help

- **Documentation**: https://docs.claude.com/claude-code
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

- **Official Docs**: https://docs.claude.com/claude-code
- **MCP Specification**: https://spec.modelcontextprotocol.io/
- **Awesome MCP**: https://github.com/wong2/awesome-mcp-servers
- **MCP Directory**: https://mcpservers.org/

---

**Next Steps:**
1. [Install Claude Code](#installation)
2. [Configure MCP Servers](installation.md#mcp-server-setup)
3. [Create CLAUDE.md](../../templates/CLAUDE.md) for your project
4. [Try your first agent](agents.md#quick-start)
