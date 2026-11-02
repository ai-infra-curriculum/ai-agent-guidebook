# GitHub Copilot Guide

Complete guide to using GitHub Copilot, GitHub's AI pair programmer for IDE and CLI.

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Copilot in IDE](#copilot-in-ide)
- [Copilot CLI](#copilot-cli)
- [Copilot Chat](#copilot-chat)
- [Copilot Cloud Agent](#copilot-cloud-agent)
- [GitHub Copilot App](#github-copilot-app)
- [Best Practices](#best-practices)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

---

## Overview

GitHub Copilot is an AI-powered code completion and chat assistant that helps you write code faster and with less work.

### Available Products

**GitHub Copilot (IDE)**
- Real-time code completions
- Inline suggestions as you type
- Multi-line completions
- Available in VS Code, Visual Studio, JetBrains, Vim/Neovim, Xcode, and Eclipse

**GitHub Copilot Chat**
- Conversational AI in your IDE
- Explain code, fix bugs, write tests
- Context-aware suggestions
- Slash commands for common tasks

**GitHub Copilot CLI**
- Standalone agentic terminal assistant, invoked as `copilot`
- Plans and executes tasks: edits files, runs commands (with approval)
- Plan and autopilot modes, MCP, custom agents, skills, hooks, BYOK/local models
- Replaces the retired `gh copilot` extension (dead since Oct 25, 2025)

**GitHub Copilot App**
- Desktop app (macOS, Windows, Linux) for running agent sessions in parallel, each on its own branch and worktree
- Built on the Copilot CLI; GA June 17, 2026, available on every plan since July 7, 2026

**Copilot Cloud Agent** (formerly "coding agent")
- Assign a GitHub issue to Copilot; it opens a pull request
- Runs in an ephemeral cloud environment built on GitHub Actions
- Successor to the sunset Copilot Workspace preview
- Third-party Claude and Codex agents (public preview) run on the same Copilot subscription

**Copilot Code Review**
- Request Copilot as a PR reviewer, or configure automatic reviews
- Agentic context gathering; Lite and Balanced (default) effort levels

### Key Features

- ✅ **Real-time Completions** - Suggestions as you type
- ✅ **Agent Mode** - Autonomous multi-step tasks in IDE, CLI, desktop app, and cloud
- ✅ **Model Picker** - Choose among Claude, GPT, Gemini, and other models per task, or let **Auto** pick
- ✅ **Custom Instructions** - Repo conventions via `.github/copilot-instructions.md` or `AGENTS.md`
- ✅ **Custom Agents and Skills** - Reusable agent profiles (`.github/agents/`) and skills (`.github/skills/`)
- ✅ **MCP Support** - Extend Copilot with Model Context Protocol servers
- ✅ **Copilot Spaces** - Curated, shareable context (repos, files, issues, notes) for chat
- ✅ **Multi-language Support** - Python, JavaScript, TypeScript, Go, Ruby, and more
- ✅ **Context-Aware** - Understands your codebase
- ✅ **Comment-to-Code** - Generate code from comments
- ✅ **Test Generation** - Create tests from functions
- ✅ **Documentation** - Write docstrings and comments
- ✅ **Refactoring** - Improve existing code

---

## Installation

### Prerequisites

- GitHub account with Copilot subscription
- Supported IDE or GitHub CLI

### Enable Copilot

1. **Subscribe to Copilot**
   - Visit https://github.com/features/copilot
   - Choose plan (Free, Pro, Pro+, Max, Business, Enterprise)
   - Free tier available; verified students get Copilot Student, and verified teachers and maintainers of popular open-source projects can get Copilot Pro free

2. **Authorize in Settings**
   - Go to https://github.com/settings/copilot
   - Enable Copilot access

### Install IDE Extension

#### VS Code

Copilot ships as built-in AI features in VS Code — you don't install extensions by hand:

1. Hover over the Copilot icon in the Status Bar and select **Use AI Features** (or run **GitHub Copilot: Sign in** from the Command Palette).
2. Sign in with GitHub. Your existing Copilot plan is used; otherwise you're signed up for Copilot Free.
3. The required Copilot extensions install automatically on first setup.

See the [VS Code guide](../vscode/README.md) for agent mode, MCP, and customization.

#### JetBrains IDEs

1. Open IDE Settings
2. Go to Plugins
3. Search for "GitHub Copilot"
4. Install and restart

#### Vim/Neovim

```vim
" Using vim-plug
Plug 'github/copilot.vim'

" Then run
:Copilot setup
```

### Install Copilot CLI

> The old `gh copilot` GitHub CLI extension stopped working on October 25, 2025. Install the standalone CLI instead:

```bash
# npm (all platforms)
npm install -g @github/copilot

# macOS/Linux via Homebrew
brew install copilot-cli

# Windows via WinGet
winget install GitHub.Copilot

# macOS/Linux via install script
curl -fsSL https://gh.io/copilot-install | bash

# Launch
copilot
```

---

## Copilot in IDE

### Code Completions

**How it works:**
- Copilot suggests code as you type
- Gray text shows suggestions
- Press Tab to accept
- Press Esc to dismiss

**Trigger suggestions:**
1. Start typing code or comments
2. Copilot analyzes context
3. Suggestions appear in gray text
4. Accept, modify, or dismiss

### Comment-to-Code

Write a comment describing what you want, then Copilot generates the code:

**Python Example:**
```python
# Function to validate email address using regex
# Copilot suggests:
import re

def validate_email(email: str) -> bool:
    """Validate email address using regex."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None
```

**TypeScript Example:**
```typescript
// Function to fetch user data from API with error handling
// Copilot suggests:
async function fetchUserData(userId: string): Promise<User> {
  try {
    const response = await fetch(`/api/users/${userId}`);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Failed to fetch user data:', error);
    throw error;
  }
}
```

### Multiple Suggestions

**View alternatives:**
- macOS: `Option + ]` (next) / `Option + [` (previous)
- Windows/Linux: `Alt + ]` (next) / `Alt + [` (previous)

**Open suggestions panel:**
- macOS: `Option + \`
- Windows/Linux: `Alt + \`

### Function Generation

**Start with signature:**
```python
def calculate_compound_interest(principal, rate, time, frequency):
# Copilot completes the implementation
```

### Test Generation

**Select function, then:**
```python
# Generate test for this function
# Copilot suggests test cases
```

---

## Copilot Chat

### Accessing Chat

**VS Code:**
- Open the Chat view
- Or: `Ctrl + Alt + I` / `Ctrl + Cmd + I`
- Pick **Ask**, **Plan**, or **Agent** (or a custom agent) from the agent picker

**Inline Chat:**
- Select code
- Press `Ctrl + I` / `Cmd + I`
- Type your question

### Common Chat Commands

**Explain Code:**
```
Explain what this function does
```

**Fix Bugs:**
```
Fix the bug in this code
```

**Write Tests:**
```
Generate unit tests for this function
```

**Refactor:**
```
Refactor this code to use async/await
```

**Generate Documentation:**
```
Add docstring to this function
```

**Optimize:**
```
Optimize this code for performance
```

### Slash Commands

**Quick actions in chat:**

- `/explain` - Explain selected code (inline chat)
- `/fix` - Propose fix for problems (inline chat)
- `/tests` - Generate unit tests (inline chat)
- `/doc` - Add documentation comments (inline chat)
- `/plan` - Draft an implementation plan before coding
- `/new` or `/clear` - Start a fresh session
- `/compact` - Summarize the conversation to free context
- `/delegate` - Hand the session to Copilot cloud agent

The exact list varies by IDE — type `/` to see what's available.

**Example:**
```
/tests
Generate comprehensive tests including edge cases
```

### Context Awareness

Copilot Chat understands:
- Currently open files
- Selected code
- Cursor position
- Recent edits
- Project structure

**Provide more context:**
```
Given the UserService in services/user.service.ts,
create a function to handle password reset with email verification
```

---

## Copilot CLI

The standalone Copilot CLI is an agentic terminal assistant — it plans tasks, edits files, and runs shell commands with your approval, in the same product family as Claude Code.

### Interactive Use

```bash
# Start a session in your project directory
copilot

# Then ask in plain language:
> Fix the failing test in tests/test_orders.py and explain the bug
> Find all files over 100MB in this directory
```

Useful in-session tricks:

```text
@path/to/file.py      # pull a file into context
!git status           # run a shell command directly (no model call)
Shift+Tab             # cycle standard / plan / autopilot modes
```

### Key Slash Commands

```text
/login        # authenticate with GitHub
/model        # pick the model (or Auto) for the session
/plan         # build an implementation plan before coding
/mcp          # manage MCP servers (GitHub's is built in)
/agent        # select a built-in or custom agent
/delegate     # hand the task to cloud agent as a pull request
/usage        # session stats, including AI Credits used
/feedback     # send feedback
```

### Programmatic Use

```bash
# One-shot prompt (scripts, CI)
copilot -p "list TODO comments in src/ grouped by file"

# Resume your last session
copilot --continue
```

### Approvals

Copilot asks before running any tool that modifies files or executes programs. Approve once, approve for the session, or reject with feedback. Prefer targeted `--allow-tool` / `--deny-tool` rules and the local sandbox (`/sandbox enable`); `--allow-all` skips approvals entirely — only use it in disposable environments.

See the [full CLI guide](cli-guide.md) for installation, MCP configuration, custom agents, BYOK, and migration from the dead `gh copilot` extension.

---

## Copilot Cloud Agent

> **Note**: GitHub renamed the "Copilot coding agent" to **Copilot cloud agent** in 2026. Copilot Workspace (the browser-based preview) was sunset on May 30, 2025; its issue-to-PR workflow lives on in cloud agent.

### What is Cloud Agent?

Cloud agent works asynchronously in the cloud: hand it a task and it researches your repo, implements the change on a branch, runs tests, and opens a pull request for review. It's included on Pro, Pro+, Max, Business, Enterprise, and Copilot Student (not Copilot Free).

### Workflow

**1. Hand off a task**
```
Assign a GitHub issue to "Copilot" — or start a task from
the agents panel at https://github.com/copilot/agents,
comment @copilot on an existing PR, or /delegate from the CLI
```

**2. The agent works**
- Spins up an ephemeral cloud environment built on GitHub Actions
- Explores the code, plans, and implements on a branch
- Runs your tests and linters

**3. Review the PR**
- Read the agent's description and session log
- Leave PR comments; the agent pushes revisions
- Merge when satisfied — repository rules and branch protections still apply

### Setup

- **Environment**: preinstall your toolchain in `.github/workflows/copilot-setup-steps.yml` (job must be named `copilot-setup-steps`)
- **Conventions**: encode build/test commands and style rules in `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`, or `GEMINI.md`
- **MCP**: GitHub and Playwright MCP servers are enabled by default; add more in repo settings

### Third-Party Agents

On Pro, Pro+, Max, Business, and Enterprise you can also enable the **Anthropic Claude** and **OpenAI Codex** coding agents (public preview). They run on your Copilot subscription and are started the same ways — agents tab, issue assignment, or `@AGENT_NAME` in a PR comment.

### Best Practices

✅ **Clear Issue Descriptions**
- Acceptance criteria, relevant files, constraints, how to verify

✅ **Review Like a Teammate's PR**
- Check the diff against the issue; push back via PR comments

✅ **Invest in Setup and Instructions**
- Fix recurring environment failures in `copilot-setup-steps.yml`, not per-issue

See the [full cloud agent guide](workspace-guide.md) for details and limitations.

---

## GitHub Copilot App

The **GitHub Copilot app** is a desktop app (macOS, Windows, Linux) for agent-driven development, built on the Copilot CLI. It went GA on June 17, 2026 and has been available on every Copilot plan — including Copilot Free and GitHub Education — since July 7, 2026.

- Start sessions from an issue, a pull request, or a prompt; run several in parallel across repositories, each on its own branch and worktree
- Review diffs and validate work in the integrated terminal and browser, then open a PR that runs your normal checks
- **Canvases**: shared surfaces where you and the agent work on the same plan, PR, terminal, or browser session
- **Cloud automations**: schedule recurring agent work that runs in the cloud
- Pick the model per session, connect tools via MCP, or bring your own model provider (BYOK) — no Copilot subscription required with BYOK

Download it from <https://github.com/github/app>, or run `copilot app` from a terminal. On Business and Enterprise plans an admin must enable Copilot CLI in policy settings before members can use the app.

---

## Best Practices

### Getting Better Suggestions

✅ **Provide Context**
```python
# Good: Specific context
# Parse ISO 8601 datetime string and return timezone-aware datetime object
def parse_datetime(datetime_str: str) -> datetime:
```

```python
# Less specific
# Parse datetime
def parse_datetime(datetime_str):
```

✅ **Use Descriptive Names**
```python
# Good
def calculate_monthly_payment(principal, annual_rate, years):

# Less clear
def calc_pmt(p, r, t):
```

✅ **Break Down Complex Tasks**
```python
# Instead of one massive function
# Break into smaller, focused functions
def validate_user_input(data):
    """Validate user registration data."""
    pass

def hash_password(password):
    """Hash password using bcrypt."""
    pass

def create_user_account(user_data, hashed_password):
    """Create user account in database."""
    pass
```

### IDE Settings

**Adjust Copilot behavior:**

VS Code Settings:
```json
{
  "github.copilot.enable": {
    "*": true,
    "yaml": false,
    "plaintext": false,
    "markdown": false
  },
  "github.copilot.nextEditSuggestions.enabled": true
}
```

**Disable for specific languages:**
- Useful for config files
- Or languages with strict formatting

### Security Considerations

✅ **Review Generated Code**
- Check for security vulnerabilities
- Validate input handling
- Review authentication logic

✅ **Don't Trust Blindly**
- Copilot suggestions may have bugs
- May not follow your security policies
- Always review before committing

✅ **Sensitive Data**
- On Free, Pro, and Pro+, interaction data may be used for model training unless you opt out (see [Pricing](#pricing))
- Use content exclusion for paths Copilot shouldn't read — but note it isn't honored by every agentic surface
- Never commit API keys or passwords

### Performance Tips

**Faster completions:**
- Keep context focused
- Close unnecessary files
- Use `.gitignore` to exclude large files

**Better quality:**
- Provide more context in comments
- Use consistent coding style
- Name variables descriptively

---

## Advanced Usage

### Multi-line Completions

**Accept partial suggestions:**
- `Tab` - Accept entire suggestion
- `Ctrl/Cmd + →` - Accept next word
- `Alt/Option + →` - Accept next line

### Custom Prompts

**Inline comments for guidance:**
```python
# TODO: Implement with retry logic and exponential backoff
# Use requests library, max 3 retries
# Raise custom exception on failure
def fetch_with_retry(url):
```

### Workspace-aware Features

**Copilot understands:**
- Your project's file structure
- Import statements
- Function definitions in other files
- Coding patterns in your codebase

**Leverage this:**
```python
# Copilot will match your existing auth implementation
# It sees AuthService is already defined elsewhere
from services.auth_service import AuthService

def login_user(username, password):
    # Copilot suggests code consistent with existing AuthService
```

### Integration with GitHub

**Pull Request Summaries:**
- GitHub Copilot can summarize PRs
- Available in PR description

**Code Review:**
- Add Copilot as a reviewer, or configure automatic reviews (on open, on new pushes, on drafts) per user, repo, or org — rulesets can trigger them too
- Agentic: gathers full-repo context on GitHub Actions runners, and can use repository MCP servers and skills
- Effort levels: **Lite** (fast, targeted) and **Balanced** (higher-reasoning; the default since September 28, 2026)
- Reads `.github/copilot-instructions.md`, path-specific instructions, and `AGENTS.md` from the PR's head branch
- Can be requested through the REST and GraphQL APIs (GA October 2, 2026)
- Consumes AI Credits (plus Actions minutes); not included in Copilot Free

**Copilot Spaces:**
- Curate repositories, files, PRs, issues, notes, and uploads into a shareable context collection
- Use it in Copilot Chat on GitHub.com, or from your IDE through the GitHub MCP server

---

## Comparison with Claude Code

### When to Use GitHub Copilot

✅ **Real-time coding in IDE**
- Writing code line by line
- Quick completions and suggestions
- Inline code generation

✅ **Simple, focused tasks**
- Single function implementation
- Test generation
- Documentation

✅ **GitHub workflow integration**
- PR summaries and reviews
- Issue-to-PR delegation via cloud agent
- One subscription covering Copilot, Claude, and Codex agents on GitHub

### When to Use Claude Code

✅ **Complex, multi-file changes**
- Large refactoring
- Architecture changes
- Multiple related files

✅ **Multi-agent orchestration**
- Research → Design → Implement → Test
- Parallel independent tasks
- Long-running workflows

✅ **Extended functionality via MCP**
- Database operations
- Kubernetes management
- Custom tooling

### Using Both Together

**Copilot for**: Day-to-day coding, completions
**Claude Code for**: Complex tasks, orchestration, research

**Example workflow:**
1. Use Claude Code to design architecture
2. Use Copilot to write individual functions
3. Use Claude Code to generate tests
4. Use Copilot for quick fixes
5. Use Claude Code for final review

---

## Troubleshooting

### Copilot Not Working

**Check:**
```bash
# Verify Copilot status in VS Code
# View → Output → GitHub Copilot

# Check subscription
https://github.com/settings/copilot

# Check network connection
# Copilot requires internet access
```

### No Suggestions Appearing

**Try:**
1. Reload VS Code window
2. Check if Copilot is enabled for file type
3. Check editor settings
4. Sign out and sign back in

### Poor Quality Suggestions

**Improve by:**
- Adding more context in comments
- Using descriptive variable names
- Providing examples in comments
- Keeping files focused and organized

### CLI Not Working

```bash
# Reinstall the standalone CLI
npm install -g @github/copilot

# Check that the npm global bin directory is on PATH
npm prefix -g

# Authenticate inside the CLI
copilot
/login
```

If you still have the old extension installed, remove it — it stopped working in October 2025:

```bash
gh extension remove gh-copilot
```

### Rate Limiting

**If you hit rate limits:**
- Wait a few minutes
- Close unnecessary IDE windows
- Reduce request frequency

---

## Keyboard Shortcuts

### VS Code

**Completions:**
- `Tab` - Accept suggestion
- `Esc` - Dismiss suggestion
- `Alt/Option + ]` - Next suggestion
- `Alt/Option + [` - Previous suggestion
- `Alt/Option + \` - Trigger suggestion

**Chat:**
- `Ctrl + Alt + I` / `Ctrl + Cmd + I` - Open Chat view
- `Ctrl/Cmd + I` - Inline chat (editor and terminal)
- `Ctrl + Shift + Alt + L` / `Shift + Option + Cmd + L` - Quick Chat
- `Ctrl/Cmd + N` (in the Chat view) - New chat session

### CLI

```bash
copilot                     # Start interactive session
copilot --prompt "..."      # One-shot prompt
copilot --continue          # Resume last session
copilot help                # Full command reference
```

---

## Resources

### Official Documentation

- **Copilot Docs**: https://docs.github.com/copilot
- **VS Code Extension**: https://marketplace.visualstudio.com/items?itemName=GitHub.copilot
- **Copilot CLI**: https://github.com/github/copilot-cli

### Community Resources

- **GitHub Community**: https://github.com/orgs/community/discussions/categories/copilot
- **Changelog**: https://github.blog/changelog/label/copilot

### Support

- **Feedback**: https://github.com/community/community/discussions/categories/copilot
- **Issues**: Report via IDE or GitHub support

---

## Pricing

> **Billing model (since June 1, 2026):** Copilot bills model usage in **GitHub AI Credits** — usage-based, token-metered billing where **1 credit = $0.01** and cost depends on the model and tokens used. The old "premium requests" system is gone. Code completions and next edit suggestions are **not** billed in credits and are unlimited on paid plans. Credits reset monthly (00:00 UTC on the 1st) and don't roll over; beyond your allowance you can upgrade, set a USD budget for additional usage, or wait for the reset.

Individual paid plans include **base** credits (equal to the price, fixed) plus a **flex** allotment (can change over time; used after base credits):

| Plan | Price | Monthly AI Credits | Highlights |
|------|-------|--------------------|------------|
| **Copilot Free** | $0 | Limited allowance | 2,000 completions/month, limited chat and agents, Auto model selection only |
| **Copilot Student** | $0 (verified students) | Limited allowance | Auto model selection only; agents included except third-party agents |
| **Copilot Pro** | $10/month | 1,000 base + 500 flex = 1,500 | Cloud agent, agent mode, code review, MCP, third-party agents, a selection of models |
| **Copilot Pro+** | $39/month | 3,900 base + 3,100 flex = 7,000 | Everything in Pro, premium models |
| **Copilot Max** | $100/month | 10,000 base + 10,000 flex = 20,000 | Everything in Pro+, priority access to premium models |
| **Copilot Business** | $19/user/month | 1,900 per user | Centralized management and policy control |
| **Copilot Enterprise** | $39/user/month | 3,900 per user | Everything in Business, priority premium-model access; requires GitHub Enterprise Cloud |

**Auto discount:** using Auto model selection in Copilot Chat, the CLI, the Copilot app, or cloud agent gets a 10% discount on model costs on paid plans.

**Free Access:**
- Verified students: Copilot Student
- Verified teachers and maintainers of popular open-source projects: Copilot Pro at no cost
- Apply at https://education.github.com/

**Data use:** since April 24, 2026, GitHub may use interaction data from Copilot Free, Pro, and Pro+ for AI model training unless you opt out in the **Privacy** section of <https://github.com/settings/copilot>. Business and Enterprise are not affected.

Current details: https://docs.github.com/en/copilot/get-started/plans

---

## Next Steps

1. [Install Copilot](#installation) in your IDE
2. [Try Copilot Chat](#copilot-chat) for code explanations
3. [Install Copilot CLI](#install-copilot-cli) for command-line help
4. [Review best practices](#best-practices) for better results
5. Compare with [Claude Code](../claude-code/) for complex tasks

---

## Related Guides

- [Claude Code Guide](../claude-code/README.md)
- [Gemini CLI Guide](../gemini-cli/README.md)
- [Feature Comparison](../../comparisons/feature-matrix.md)
- [Best Practices](../../best-practices/prompting.md)

---

**Last Updated**: 2026-10-21
