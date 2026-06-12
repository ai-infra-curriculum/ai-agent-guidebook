# GitHub Copilot Guide

Complete guide to using GitHub Copilot, GitHub's AI pair programmer for IDE and CLI.

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Copilot in IDE](#copilot-in-ide)
- [Copilot CLI](#copilot-cli)
- [Copilot Chat](#copilot-chat)
- [Copilot Coding Agent](#copilot-coding-agent)
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
- Available in VS Code, JetBrains, Vim, Visual Studio

**GitHub Copilot Chat**
- Conversational AI in your IDE
- Explain code, fix bugs, write tests
- Context-aware suggestions
- Slash commands for common tasks

**GitHub Copilot CLI**
- Standalone agentic terminal assistant, invoked as `copilot`
- Plans and executes tasks: edits files, runs commands (with approval)
- MCP support, model selection, custom instructions
- Replaces the retired `gh copilot` extension (dead since Oct 25, 2025)

**Copilot Coding Agent**
- Assign a GitHub issue to Copilot; it opens a draft PR
- Runs in an ephemeral GitHub Actions environment
- Successor to the sunset Copilot Workspace preview

### Key Features

- ✅ **Real-time Completions** - Suggestions as you type
- ✅ **Agent Mode** - Autonomous multi-step tasks in IDE, CLI, and cloud
- ✅ **Model Picker** - Choose among Claude, GPT, and Gemini models per task
- ✅ **Custom Instructions** - Repo conventions via `.github/copilot-instructions.md`
- ✅ **MCP Support** - Extend Copilot with Model Context Protocol servers
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
   - Choose plan (Free, Pro, Pro+, Business, Enterprise)
   - Free tier available; expanded free access for students and verified open-source maintainers

2. **Authorize in Settings**
   - Go to https://github.com/settings/copilot
   - Enable Copilot access

### Install IDE Extension

#### VS Code

```bash
# Install from VS Code Marketplace
# Search for "GitHub Copilot"
# Or via command line:
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
```

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
- Click Copilot icon in sidebar
- Or: `Ctrl + Shift + I` / `Cmd + Shift + I`

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

- `/explain` - Explain selected code
- `/fix` - Propose fix for problems
- `/tests` - Generate unit tests
- `/doc` - Add documentation comments
- `/optimize` - Suggest performance improvements
- `/clear` - Clear chat history
- `/help` - Get help with Copilot
- `/new` - Start a fresh thread

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
Shift+Tab             # toggle plan mode (plan before code)
```

### Key Slash Commands

```text
/login        # authenticate with GitHub
/model        # pick the model for the session
/mcp add      # add an MCP server (GitHub's is pre-configured)
/agent        # select a built-in or custom agent
/usage        # session stats, including AI Credits used
/feedback     # send feedback
```

### Programmatic Use

```bash
# One-shot prompt (scripts, CI)
copilot --prompt "list TODO comments in src/ grouped by file"

# Resume your last session
copilot --continue
```

### Approvals

Copilot asks before running any tool that modifies files or executes programs. Approve once, approve for the session, or reject with feedback. `--allow-all` skips approvals — only use it in disposable environments.

See the [full CLI guide](cli-guide.md) for installation, MCP configuration, custom agents, and migration from the dead `gh copilot` extension.

---

## Copilot Coding Agent

> **Note**: Copilot Workspace (the browser-based preview) was sunset on May 30, 2025. Its issue-to-PR workflow lives on in the **Copilot coding agent**, available on all paid Copilot plans.

### What is the Coding Agent?

The coding agent works asynchronously in the cloud: hand it a task and it researches your repo, implements the change on a branch, runs tests, and opens a draft pull request for review.

### Workflow

**1. Hand off a task**
```
Assign a GitHub issue to "Copilot" — or start a task from
the agents panel at https://github.com/copilot/agents,
or comment @copilot on an existing PR
```

**2. The agent works**
- Spins up an ephemeral GitHub Actions environment
- Explores the code, plans, and implements on a branch
- Runs your tests and linters

**3. Review the draft PR**
- Read the agent's description and session log
- Leave PR comments; the agent pushes revisions
- Merge when satisfied — the agent can't bypass branch protections

### Setup

- **Environment**: preinstall your toolchain in `.github/workflows/copilot-setup-steps.yml` (job must be named `copilot-setup-steps`)
- **Conventions**: encode build/test commands and style rules in `.github/copilot-instructions.md` or `AGENTS.md`
- **MCP**: GitHub and Playwright MCP servers are enabled by default; add more in repo settings

### Best Practices

✅ **Clear Issue Descriptions**
- Acceptance criteria, relevant files, constraints, how to verify

✅ **Review Like a Teammate's PR**
- Check the diff against the issue; push back via PR comments

✅ **Invest in Setup and Instructions**
- Fix recurring environment failures in `copilot-setup-steps.yml`, not per-issue

See the [full coding agent guide](workspace-guide.md) for details and limitations.

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
    "plaintext": false
  },
  "github.copilot.inlineSuggest.enable": true,
  "github.copilot.editor.enableAutoCompletions": true
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
- Copilot doesn't store your code
- But be cautious with secrets
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
- Copilot can suggest improvements
- Available in review comments

**Issue Triage:**
- Copilot can help categorize issues
- Suggest labels and assignments

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
- Issue management
- GitHub CLI operations

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
- `Alt/Option + \` - Open suggestions panel

**Chat:**
- `Ctrl/Cmd + Shift + I` - Open chat
- `Ctrl/Cmd + I` - Inline chat
- `Ctrl/Cmd + K` - Quick actions

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

> **Billing change (June 1, 2026):** Copilot moved from "premium requests" to **GitHub AI Credits** — usage-based, token-metered billing where 1 credit = $0.01 and cost depends on the model and tokens used. Each paid plan includes a monthly credit allowance; overage and budgets are managed in billing settings.

**GitHub Copilot Free**
- $0 — limited completions and chat per month
- Includes Copilot CLI

**GitHub Copilot Pro**
- $10/month
- Unlimited completions, coding agent, code review
- Monthly AI Credit allowance included

**GitHub Copilot Pro+**
- $39/month
- Everything in Pro, larger AI Credit allowance, premium models

**GitHub Copilot Business**
- $19/user/month
- Organization license and policy management, pooled AI Credits

**GitHub Copilot Enterprise**
- $39/user/month
- Everything in Business, GitHub.com-native integration, codebase indexing, larger pooled credits

**Free Access:**
- Verified students and teachers
- Maintainers of popular open-source projects
- Apply at https://education.github.com/

Current details: https://github.com/features/copilot/plans

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

**Last Updated**: 2026-06-11
