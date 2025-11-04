# GitHub Copilot Guide

Complete guide to using GitHub Copilot, GitHub's AI pair programmer for IDE and CLI.

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Copilot in IDE](#copilot-in-ide)
- [Copilot CLI](#copilot-cli)
- [Copilot Chat](#copilot-chat)
- [Copilot Workspace](#copilot-workspace)
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
- Command-line assistance with `gh copilot`
- Generate and explain shell commands
- Git command help
- Available via GitHub CLI

**GitHub Copilot Workspace** (Preview)
- Task-oriented development
- Multi-file editing
- Plan → Build → Test workflow

### Key Features

- ✅ **Real-time Completions** - Suggestions as you type
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
   - Choose plan (Individual, Business, Enterprise)
   - Free for students and verified open-source maintainers

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

```bash
# Install GitHub CLI first (if not installed)
# macOS
brew install gh

# Linux
# See https://github.com/cli/cli/blob/trunk/docs/install_linux.md

# Install Copilot CLI extension
gh extension install github/gh-copilot

# Verify installation
gh copilot --version
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
- `/help` - Get help with Copilot
- `/clear` - Clear chat history
- `/api` - Ask about API usage

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

### Basic Commands

**Get command suggestions:**
```bash
gh copilot suggest "command description"
```

**Examples:**

```bash
# Git commands
gh copilot suggest "undo last commit but keep changes"
# Suggests: git reset --soft HEAD~1

# File operations
gh copilot suggest "find all python files modified in last 7 days"
# Suggests: find . -name "*.py" -mtime -7

# Process management
gh copilot suggest "kill process using port 3000"
# Suggests: lsof -ti:3000 | xargs kill -9
```

**Explain commands:**
```bash
gh copilot explain "tar -xzvf archive.tar.gz"
# Explains each flag and what the command does
```

### Interactive Mode

```bash
# Start interactive session
gh copilot suggest -t shell

# Then ask questions interactively
? What would you like the shell command to do?
> find all large files over 100MB

# Copilot suggests command
# You can revise or execute
```

### Git Commands

```bash
gh copilot suggest -t git "create branch from main"
# Suggests: git checkout -b new-branch main

gh copilot suggest -t git "show changes in last commit"
# Suggests: git show HEAD

gh copilot suggest -t git "interactive rebase last 3 commits"
# Suggests: git rebase -i HEAD~3
```

### GitHub CLI Commands

```bash
gh copilot suggest -t gh "create issue with title and body"
# Suggests: gh issue create --title "..." --body "..."

gh copilot suggest -t gh "list open pull requests"
# Suggests: gh pr list --state open
```

### Aliases

**Create shortcuts:**

```bash
# Add to ~/.bashrc or ~/.zshrc
alias gcs='gh copilot suggest'
alias gce='gh copilot explain'

# Usage
gcs "list docker containers"
gce "docker ps -a"
```

---

## Copilot Workspace

> **Note**: Copilot Workspace is in preview and may not be available to all users.

### What is Workspace?

Copilot Workspace is a task-oriented development environment that helps you:
- Plan features and fixes
- Generate code across multiple files
- Run and validate changes
- Create pull requests

### Workflow

**1. Start from Issue**
```
Open GitHub issue → Click "Open in Workspace"
```

**2. Specification Phase**
- Copilot analyzes issue
- Generates implementation plan
- Lists files to modify

**3. Implementation Phase**
- Review proposed changes
- Modify plan if needed
- Generate code

**4. Validation Phase**
- Run tests
- Fix issues
- Iterate

**5. Pull Request**
- Review all changes
- Create PR from Workspace
- Link to original issue

### Best Practices

✅ **Clear Issue Descriptions**
- Provide context and requirements
- Include acceptance criteria
- Mention relevant files

✅ **Review Generated Plans**
- Validate approach before implementation
- Adjust if needed
- Consider edge cases

✅ **Iterate**
- Test early and often
- Refine as you go
- Use feedback loops

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

### CLI Not Installed

```bash
# Reinstall Copilot CLI extension
gh extension remove gh-copilot
gh extension install github/gh-copilot

# Check GitHub CLI authentication
gh auth status
gh auth login  # if not authenticated
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
gh copilot suggest   # Get command suggestion
gh copilot explain   # Explain command
gh copilot suggest -t git    # Git commands
gh copilot suggest -t gh     # GitHub CLI commands
```

---

## Resources

### Official Documentation

- **Copilot Docs**: https://docs.github.com/copilot
- **VS Code Extension**: https://marketplace.visualstudio.com/items?itemName=GitHub.copilot
- **Copilot CLI**: https://githubnext.com/projects/copilot-cli

### Community Resources

- **GitHub Community**: https://github.com/orgs/community/discussions/categories/copilot
- **Changelog**: https://github.blog/changelog/label/copilot

### Support

- **Feedback**: https://github.com/community/community/discussions/categories/copilot
- **Issues**: Report via IDE or GitHub support

---

## Pricing

**GitHub Copilot Individual**
- $10/month or $100/year
- For personal use

**GitHub Copilot Business**
- $19/user/month
- For organizations
- Additional management features

**GitHub Copilot Enterprise**
- $39/user/month
- Includes Workspace
- Custom models on your codebase
- Advanced security

**Free Access:**
- Verified students
- Open-source maintainers
- Apply at https://education.github.com/

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
