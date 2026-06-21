# AI Agent Guidebook

<!-- aicg:site-banner -->
> 🎓 Part of the **[AI Infrastructure Curriculum](https://ai-infra-curriculum.github.io/)** — a free, open-source ladder of role-based AI-infrastructure programs. [Explore the ladder](https://ai-infra-curriculum.github.io/) · [Join the first live cohort](https://ai-infra-curriculum.github.io/junior.html)
<!-- /aicg:site-banner -->

Comprehensive guides for AI-powered coding assistants, multi-agent orchestration, and Model Context Protocol (MCP) servers.

---

## ⚠️ AI-Generated Content Disclaimer

> **Important Notice**: This repository contains AI-generated documentation and guides. While we strive for accuracy and completeness, **generated content may contain errors, inaccuracies, or outdated information**.
>
> **Status**: 🔄 Active development
>
> Please use this guidebook responsibly:
> - Verify information against official documentation
> - Test code examples in safe environments
> - Cross-reference with authoritative sources
> - Report issues or inaccuracies via GitHub Issues
>
> We appreciate your understanding as we develop comprehensive resources for AI-assisted development.

---

## Overview

This guidebook provides in-depth documentation, best practices, templates, and examples for working with modern AI coding assistants. Whether you're using Claude Code, GitHub Copilot, Gemini CLI, or building multi-agent systems, this repository is your complete reference.

## What's Inside

### 🤖 AI Assistant Guides

Complete documentation for major AI coding assistants:

- **[Claude Code](guides/claude-code/)** - Anthropic's CLI tool with MCP servers, agents, and skills
- **[GitHub Copilot](guides/github-copilot/)** - GitHub's AI pair programmer (CLI and IDE)
- **[Gemini CLI](guides/gemini-cli/)** - Google's Gemini integration for command line
- **[Cursor](guides/cursor/)** - AI-first code editor: Agent, Plan mode, `.cursor/rules`, and MCP
- **[VS Code](guides/vscode/)** - VS Code as an agentic environment: agent mode, MCP, and custom instructions
- **[Google Antigravity](guides/antigravity/)** - Agent-first IDE: Editor view + Agent Manager, built on Gemini

### 🔌 MCP Servers

Model Context Protocol server documentation:

- **[MCP Server Catalog](guides/mcp-servers/catalog.md)** - Comprehensive list of 50+ MCP servers
- **[MCP Server Guide](guides/mcp-servers/guide.md)** - Installation, configuration, and usage
- **[Building MCP Servers](guides/mcp-servers/building.md)** - Create your own MCP servers

### 🎭 Agents & Orchestration

Multi-agent systems and orchestration patterns:

- **[Agent Architecture](guides/agents-subagents/architecture.md)** - Design patterns and best practices
- **[Orchestration Patterns](guides/agents-subagents/orchestration.md)** - Coordinate multiple agents
- **[Agent Communication](guides/agents-subagents/communication.md)** - Message passing and state management

### 🎯 Claude Skills

Reusable task packs for Claude Code:

- **[Skills Guide](guides/skills/guide.md)** - Creating and using Claude Skills
- **[Skill Templates](guides/skills/templates/)** - Ready-to-use skill examples
- **[Skill Catalog](guides/skills/catalog.md)** - Community skills collection

### 📋 Templates

Production-ready templates for project setup:

- **[CLAUDE.md Template](templates/CLAUDE.md)** - Project orchestration file
- **[AGENTS.md Template](templates/AGENTS.md)** - Multi-agent system configuration
- **[MCP Configuration Template](templates/mcp-config.json)** - MCP server setup
- **[Skills Template](templates/skill-template/)** - Claude Skills structure
- **[Prompt Templates](templates/prompt-templates/)** - Fill-in-the-blank prompts for the Explore → Plan → Implement → Verify workflow

### 📊 Comparisons & Best Practices

- **[Feature Comparison Matrix](comparisons/feature-matrix.md)** - Compare AI assistants
- **[Use Case Guide](comparisons/use-cases.md)** - Which tool for which task
- **[Best Practices](best-practices/)** - Proven patterns and anti-patterns

### 💡 Examples

Real-world examples and case studies:

- **[Content Generation System](examples/content-generation/)** - Multi-agent curriculum builder
- **[DevOps Automation](examples/devops-automation/)** - Infrastructure management
- **[Code Review System](examples/code-review/)** - Automated code analysis

---

## Quick Start

### Choose Your Tool

**Starting with Claude Code?**
```bash
# Read the Claude Code guide
cat guides/claude-code/README.md

# Copy CLAUDE.md template to your project
cp templates/CLAUDE.md /path/to/your/project/
```

**Using GitHub Copilot?**
```bash
# Read the Copilot guide
cat guides/github-copilot/README.md

# Install Copilot CLI
gh extension install github/gh-copilot
```

**Trying Gemini CLI?**
```bash
# Read the Gemini CLI guide
cat guides/gemini-cli/README.md
```

### Set Up MCP Servers

```bash
# Copy the MCP configuration template into your project as .mcp.json
# (Claude Code's project-scope MCP config)
cp templates/mcp-config.json /path/to/your/project/.mcp.json

# Edit with your server configuration
nano /path/to/your/project/.mcp.json

# Or add servers via the CLI instead:
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem "$(pwd)"
```

### Create Multi-Agent System

```bash
# Copy AGENTS.md template to your project
cp templates/AGENTS.md /path/to/your/project/

# Customize for your workflow
nano /path/to/your/project/AGENTS.md
```

---

## Repository Structure

```
ai-agent-guidebook/
├── README.md                           # This file
├── guides/
│   ├── claude-code/
│   │   ├── README.md                   # Claude Code overview
│   │   ├── installation.md             # Setup and installation
│   │   ├── mcp-servers.md              # MCP server integration
│   │   ├── agents.md                   # Agent orchestration
│   │   ├── skills.md                   # Claude Skills usage
│   │   ├── hooks.md                    # Event hooks
│   │   ├── advanced.md                 # Advanced techniques
│   │   └── troubleshooting.md          # Common issues
│   ├── github-copilot/
│   │   ├── README.md                   # Copilot overview
│   │   ├── cli-guide.md                # CLI usage
│   │   ├── ide-guide.md                # IDE integration
│   │   ├── chat-guide.md               # Copilot Chat
│   │   ├── workspace-guide.md          # Workspace context
│   │   └── best-practices.md           # Usage patterns
│   ├── gemini-cli/
│   │   ├── README.md                   # Gemini CLI overview
│   │   ├── installation.md             # Setup guide
│   │   ├── usage.md                    # Command reference
│   │   └── integration.md              # Integration patterns
│   ├── mcp-servers/
│   │   ├── guide.md                    # MCP introduction
│   │   ├── catalog.md                  # Server catalog (50+)
│   │   ├── installation.md             # Setup instructions
│   │   ├── configuration.md            # Configuration guide
│   │   ├── building.md                 # Build your own
│   │   └── advanced.md                 # Advanced topics
│   ├── agents-subagents/
│   │   ├── architecture.md             # System design
│   │   ├── orchestration.md            # Coordination patterns
│   │   ├── communication.md            # Message protocols
│   │   ├── state-management.md         # State persistence
│   │   └── examples.md                 # Real examples
│   └── skills/
│       ├── guide.md                    # Skills overview
│       ├── creating.md                 # Build skills
│       ├── catalog.md                  # Skill collection
│       └── templates/                  # Skill templates
├── templates/
│   ├── CLAUDE.md                       # Claude orchestration template
│   ├── AGENTS.md                       # Multi-agent template
│   ├── mcp-config.json                 # MCP configuration
│   ├── skill-template/                 # Claude Skill template
│   └── prompt-templates/               # Explore→Plan→Implement→Verify prompts
├── examples/
│   ├── content-generation/             # Curriculum builder example
│   ├── devops-automation/              # Infrastructure automation
│   ├── code-review/                    # Code analysis system
│   └── data-pipeline/                  # Data processing example
├── comparisons/
│   ├── feature-matrix.md               # Tool comparison
│   ├── use-cases.md                    # Which tool when
│   ├── performance.md                  # Performance benchmarks
│   └── cost-analysis.md                # Cost comparison
├── best-practices/
│   ├── prompting.md                    # Effective prompts
│   ├── context-management.md           # Managing context
│   ├── error-handling.md               # Error recovery
│   ├── security.md                     # Security practices
│   ├── testing.md                      # Testing AI systems
│   ├── performance.md                  # Model selection & cost/latency
│   └── agent-governance.md             # Agent governance & trust
└── .github/
    └── workflows/
        └── ci.yml                      # CI validation
```

---

## Key Features

### Claude Code

- ✅ **MCP Server Integration** - 50+ pre-built servers for extended functionality
- ✅ **Multi-Agent Orchestration** - Spawn specialized agents for complex tasks
- ✅ **Claude Skills** - Reusable task packs and workflows
- ✅ **Event Hooks** - Customize behavior with shell commands
- ✅ **Checkpoint System** - Save and resume long-running tasks
- ✅ **Context Management** - Efficient token usage with smart context

### GitHub Copilot

- ✅ **IDE Integration** - Deep integration with VS Code, JetBrains, Vim
- ✅ **CLI Assistant** - Command-line helper with `gh copilot`
- ✅ **Copilot Chat** - Conversational coding assistance
- ✅ **Workspace Context** - Project-aware suggestions
- ✅ **Code Completion** - Real-time code suggestions

### Gemini CLI

- ✅ **Google AI Integration** - Access to Gemini models
- ✅ **Command Line Interface** - Terminal-based interaction
- ✅ **Multimodal Support** - Text, images, and more
- ✅ **Context Windows** - Large context support

---

## Use Cases

### Choose the Right Tool

**Use Claude Code when:**
- Building complex multi-agent systems
- Need MCP server ecosystem (databases, APIs, tools)
- Orchestrating long-running content generation
- Require checkpoint/resume functionality
- Building custom Claude Skills

**Use GitHub Copilot when:**
- Writing code in your IDE
- Need real-time code completion
- Working with GitHub workflows
- Quick command-line assistance
- Pair programming scenarios

**Use Gemini CLI when:**
- Need multimodal AI capabilities
- Working with Google ecosystem
- Terminal-based workflows
- Large context requirements

---

## Getting Started Guides

### For Beginners

1. **[Start Here](guides/getting-started.md)** - Choose the right tool
2. **[Basic Setup](guides/basic-setup.md)** - Install and configure
3. **[First Steps](guides/first-steps.md)** - Your first AI-assisted task

### For Advanced Users

1. **[Multi-Agent Systems](guides/agents-subagents/architecture.md)** - Build complex orchestration
2. **[MCP Server Development](guides/mcp-servers/building.md)** - Create custom servers
3. **[Custom Skills](guides/skills/creating.md)** - Build reusable task packs
4. **[Performance Optimization](best-practices/performance.md)** - Maximize efficiency

---

## Examples & Case Studies

### Real-World Applications

**[AI Infrastructure Curriculum Generator](examples/content-generation/)**
- 8-phase multi-agent workflow
- Checkpoint-based progress tracking
- 50+ MCP servers integrated
- Generated 200,000+ words of content

**[DevOps Automation System](examples/devops-automation/)**
- Infrastructure as Code generation
- Kubernetes resource management
- CI/CD pipeline orchestration
- Multi-cloud deployments

**[Code Review Automation](examples/code-review/)**
- Automated code analysis
- Security vulnerability scanning
- Best practices enforcement
- Documentation generation

---

## Best Practices

### Prompting

- ✅ Be specific and detailed
- ✅ Provide context and examples
- ✅ Break complex tasks into steps
- ✅ Iterate and refine prompts

### Context Management

- ✅ Use `permissions.deny` rules (Claude Code) and ignore files (`.cursorignore`, `.geminiignore`) to exclude irrelevant files
- ✅ Reference specific files and line numbers
- ✅ Provide focused code snippets
- ✅ Use MCP servers for external data

### Multi-Agent Systems

- ✅ Define clear agent responsibilities
- ✅ Use message protocols for communication
- ✅ Implement state persistence
- ✅ Design for failure recovery

### Security

- ✅ Never commit API keys or secrets
- ✅ Use environment variables
- ✅ Review generated code before execution
- ✅ Validate AI outputs

---

## Contributing

We welcome contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

### How to Contribute

1. **Add Guide Content** - Expand existing guides or create new ones
2. **Share Examples** - Submit real-world use cases
3. **Create Templates** - Build reusable templates
4. **Document MCP Servers** - Add to the catalog
5. **Share Skills** - Contribute Claude Skills

---

## Resources

### Official Documentation

- **[Claude Code Docs](https://docs.claude.com/claude-code)** - Official Claude Code documentation
- **[GitHub Copilot Docs](https://docs.github.com/copilot)** - Official Copilot documentation
- **[Gemini API Docs](https://ai.google.dev/docs)** - Google Gemini documentation
- **[MCP Specification](https://spec.modelcontextprotocol.io/)** - Model Context Protocol spec

### Community Resources

- **[Awesome MCP Servers](https://github.com/wong2/awesome-mcp-servers)** - Curated MCP server list
- **[MCP Directory](https://mcpservers.org/)** - Searchable MCP server directory
- **[Claude Code Community](https://github.com/anthropics/claude-code/discussions)** - Community discussions

### Related Projects

- **[AI Infrastructure Content Generator](https://github.com/ai-infra-curriculum/ai-infra-content-generator)** - Curriculum generation framework
- **[MCP Servers Repository](https://github.com/modelcontextprotocol/servers)** - Official MCP servers
- **[Veriswarm](https://veriswarm.ai)** - Trust infrastructure for AI agents (real-time trust scoring, PII/prompt-injection guardrails, portable agent credentials, hash-chained audit ledger). Cross-framework — works with LangChain, CrewAI, AutoGen, Agentforce, Microsoft Agent 365, AWS Bedrock. See [Agent Governance & Trust](best-practices/agent-governance.md) for where this fits.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contact

- **GitHub**: https://github.com/ai-infra-curriculum/ai-agent-guidebook
- **Issues**: https://github.com/ai-infra-curriculum/ai-agent-guidebook/issues
- **Discussions**: https://github.com/ai-infra-curriculum/ai-agent-guidebook/discussions

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

---

**Version**: 1.2.0

**Last Updated**: 2026-06-11

**Status**: 🚀 Active Development — covering the current Claude models (Fable 5, Opus 4.8, Sonnet 4.6, Haiku 4.5), the standalone GitHub Copilot CLI + coding agent, Gemini CLI (Gemini 3.x), and MCP spec revision 2025-11-25.

---

<!-- aicg:maintained-by -->
Maintained by [VeriSwarm.ai](https://veriswarm.ai)
