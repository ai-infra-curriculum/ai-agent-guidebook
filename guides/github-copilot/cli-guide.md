# GitHub Copilot CLI Guide

Complete guide to using GitHub Copilot in the command line with `gh copilot`.

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Basic Commands](#basic-commands)
- [Command Suggestions](#command-suggestions)
- [Command Explanations](#command-explanations)
- [Git Commands](#git-commands)
- [GitHub CLI Commands](#github-cli-commands)
- [Advanced Usage](#advanced-usage)
- [Configuration](#configuration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

GitHub Copilot CLI (`gh copilot`) provides AI-powered assistance for command-line operations, helping you find the right commands, understand complex syntax, and work more efficiently in the terminal.

### Key Features

- ✅ **Command Suggestions** - Get command recommendations from natural language
- ✅ **Command Explanations** - Understand what commands do
- ✅ **Git Integration** - Specialized help for git commands
- ✅ **GitHub CLI Integration** - Help with `gh` commands
- ✅ **Interactive Mode** - Conversational command assistance
- ✅ **Shell Context** - Understands your shell environment
- ✅ **Safety** - Review before executing

---

## Installation

### Prerequisites

- GitHub CLI (`gh`) installed
- GitHub Copilot subscription
- Authenticated GitHub CLI session

### Install GitHub CLI

**macOS:**
```bash
brew install gh
```

**Linux:**
```bash
# Debian/Ubuntu
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Fedora/CentOS/RHEL
sudo dnf install gh
```

**Windows:**
```powershell
winget install GitHub.cli
```

### Authenticate GitHub CLI

```bash
gh auth login
```

Follow the prompts to authenticate.

### Install Copilot CLI Extension

```bash
gh extension install github/gh-copilot
```

### Verify Installation

```bash
gh copilot --version
```

### Update Copilot CLI

```bash
gh extension upgrade gh-copilot
```

---

## Basic Commands

### Two Main Commands

**1. `gh copilot suggest`** - Get command suggestions
```bash
gh copilot suggest "description of what you want to do"
```

**2. `gh copilot explain`** - Explain a command
```bash
gh copilot explain "command to explain"
```

### Quick Examples

```bash
# Get suggestions
gh copilot suggest "find all python files modified today"

# Explain commands
gh copilot explain "tar -xzvf archive.tar.gz"

# Git-specific
gh copilot suggest -t git "undo last commit"

# GitHub CLI-specific
gh copilot suggest -t gh "list my pull requests"
```

---

## Command Suggestions

### Basic Syntax

```bash
gh copilot suggest [options] "what you want to do"
```

### Options

- `-t, --target` - Target type: `shell`, `git`, or `gh`
- `--shell-out` - Execute suggestion without confirmation

### Shell Commands

```bash
# File operations
gh copilot suggest "find all files larger than 100MB"
# Suggests: find . -type f -size +100M

gh copilot suggest "count lines of code in python files"
# Suggests: find . -name "*.py" -exec wc -l {} + | awk '{sum+=$1} END {print sum}'

# Process management
gh copilot suggest "kill process on port 3000"
# Suggests: lsof -ti:3000 | xargs kill -9

# System information
gh copilot suggest "show disk usage by directory"
# Suggests: du -sh */ | sort -h

# Archive operations
gh copilot suggest "extract tar.gz file"
# Suggests: tar -xzvf filename.tar.gz

# Network operations
gh copilot suggest "check if port 8080 is open"
# Suggests: nc -zv localhost 8080
```

### File and Directory Operations

```bash
# Search
gh copilot suggest "find files containing TODO"
# Suggests: grep -r "TODO" .

# Bulk operations
gh copilot suggest "rename all jpg files to lowercase"
# Suggests: for f in *.JPG; do mv "$f" "${f,,}"; done

# Permissions
gh copilot suggest "make all sh files executable"
# Suggests: find . -name "*.sh" -exec chmod +x {} \;

# Find and delete
gh copilot suggest "delete all node_modules folders"
# Suggests: find . -name "node_modules" -type d -prune -exec rm -rf {} +
```

### Interactive Mode

```bash
# Start interactive shell command session
gh copilot suggest -t shell

# Then describe commands interactively
? What would you like the shell command to do?
> find all log files from last week
```

**Interactive workflow:**
1. Copilot suggests command
2. Review suggestion
3. Options:
   - Execute (copies to clipboard or runs)
   - Revise (provide more details)
   - Exit

---

## Command Explanations

### Basic Syntax

```bash
gh copilot explain "command to explain"
```

### Examples

**Complex tar command:**
```bash
gh copilot explain "tar -xzvf archive.tar.gz"

# Output:
# This command extracts files from a compressed tar archive:
#   tar: Archive manipulation utility
#   -x: Extract files from archive
#   -z: Decompress using gzip
#   -v: Verbose output (show files being extracted)
#   -f: Specify archive file
#   archive.tar.gz: The archive file to extract
```

**Docker command:**
```bash
gh copilot explain "docker run -d -p 8080:80 --name web nginx"

# Explains:
# - docker run: Create and start container
# - -d: Detached mode (background)
# - -p 8080:80: Port mapping (host:container)
# - --name web: Container name
# - nginx: Image to use
```

**Complex find command:**
```bash
gh copilot explain "find . -name '*.log' -mtime +7 -delete"

# Explains each flag and what the command does
```

**Git command:**
```bash
gh copilot explain "git rebase -i HEAD~3"

# Explains interactive rebase for last 3 commits
```

---

## Git Commands

### Specialized Git Assistance

```bash
gh copilot suggest -t git "description"
```

### Common Git Tasks

**Undo operations:**
```bash
gh copilot suggest -t git "undo last commit but keep changes"
# Suggests: git reset --soft HEAD~1

gh copilot suggest -t git "undo all uncommitted changes"
# Suggests: git restore .
```

**Branch operations:**
```bash
gh copilot suggest -t git "create and switch to new branch"
# Suggests: git checkout -b branch-name

gh copilot suggest -t git "delete remote branch"
# Suggests: git push origin --delete branch-name
```

**History and logs:**
```bash
gh copilot suggest -t git "show commits by specific author"
# Suggests: git log --author="name"

gh copilot suggest -t git "find commit that introduced a bug"
# Suggests: git bisect start
```

**Stash operations:**
```bash
gh copilot suggest -t git "temporarily save changes"
# Suggests: git stash

gh copilot suggest -t git "apply stashed changes to different branch"
# Suggests: git stash apply stash@{n}
```

**Rebase and merge:**
```bash
gh copilot suggest -t git "rebase my branch on main"
# Suggests: git rebase main

gh copilot suggest -t git "interactive rebase last 5 commits"
# Suggests: git rebase -i HEAD~5
```

**Remote operations:**
```bash
gh copilot suggest -t git "change remote url"
# Suggests: git remote set-url origin new-url

gh copilot suggest -t git "fetch all remote branches"
# Suggests: git fetch --all
```

---

## GitHub CLI Commands

### Specialized `gh` Assistance

```bash
gh copilot suggest -t gh "description"
```

### Common GitHub CLI Tasks

**Issues:**
```bash
gh copilot suggest -t gh "create issue with labels"
# Suggests: gh issue create --label bug,urgent

gh copilot suggest -t gh "list my open issues"
# Suggests: gh issue list --assignee @me --state open
```

**Pull Requests:**
```bash
gh copilot suggest -t gh "create pull request"
# Suggests: gh pr create --title "..." --body "..."

gh copilot suggest -t gh "list open pull requests"
# Suggests: gh pr list --state open

gh copilot suggest -t gh "review pull request"
# Suggests: gh pr review PR-NUMBER
```

**Repositories:**
```bash
gh copilot suggest -t gh "clone repository"
# Suggests: gh repo clone owner/repo

gh copilot suggest -t gh "create new repository"
# Suggests: gh repo create repo-name --public

gh copilot suggest -t gh "fork repository"
# Suggests: gh repo fork owner/repo
```

**Workflows:**
```bash
gh copilot suggest -t gh "list workflow runs"
# Suggests: gh run list

gh copilot suggest -t gh "view workflow run details"
# Suggests: gh run view RUN-ID
```

**Releases:**
```bash
gh copilot suggest -t gh "create release"
# Suggests: gh release create v1.0.0

gh copilot suggest -t gh "download release asset"
# Suggests: gh release download v1.0.0
```

---

## Advanced Usage

### Aliases for Convenience

Add to your shell profile (`~/.bashrc`, `~/.zshrc`):

```bash
# Short aliases
alias gcs='gh copilot suggest'
alias gce='gh copilot explain'

# Domain-specific aliases
alias gcsg='gh copilot suggest -t git'
alias gcsh='gh copilot suggest -t gh'

# Interactive aliases
alias gcsi='gh copilot suggest -t shell'
```

**Usage:**
```bash
gcs "find large files"
gce "tar -xzvf file.tar.gz"
gcsg "undo last 3 commits"
```

### Shell Integration

**Add to `~/.bashrc` or `~/.zshrc`:**

```bash
# Function for quick suggestions
ghelp() {
    gh copilot suggest "$*"
}

# Function for quick explanations
gexplain() {
    gh copilot explain "$*"
}

# Git-specific helper
ggit() {
    gh copilot suggest -t git "$*"
}
```

**Usage:**
```bash
ghelp find all python files
gexplain ps aux | grep python
ggit create branch and push to remote
```

### Pipe Integration

```bash
# Get suggestion and execute
gh copilot suggest "list docker containers" --shell-out

# Chain with other commands
gh copilot suggest "current git branch" | sh
```

### Complex Workflows

**Multi-step operations:**
```bash
# 1. Get suggestion
gh copilot suggest "backup database"

# 2. Review and modify
# 3. Execute

# 4. Get next step
gh copilot suggest "compress backup file"
```

---

## Configuration

### Environment Variables

```bash
# Set default target
export GH_COPILOT_TARGET=shell

# Disable confirmation prompts (use carefully!)
export GH_COPILOT_AUTO_EXECUTE=true
```

### GitHub CLI Configuration

```bash
# Configure GitHub CLI
gh config set editor vim
gh config set prompt enabled

# View configuration
gh config list
```

---

## Best Practices

### Be Specific

❌ **Too vague:**
```bash
gh copilot suggest "find files"
```

✅ **Specific:**
```bash
gh copilot suggest "find all Python files modified in the last 7 days"
```

### Include Context

❌ **No context:**
```bash
gh copilot suggest "delete them"
```

✅ **With context:**
```bash
gh copilot suggest "delete all log files older than 30 days"
```

### Use Appropriate Target

```bash
# For shell commands
gh copilot suggest -t shell "list processes"

# For git commands
gh copilot suggest -t git "create branch"

# For GitHub CLI commands
gh copilot suggest -t gh "list issues"
```

### Review Before Executing

**Always review suggested commands**, especially:
- Commands that delete files
- Commands that modify git history
- Commands with `sudo`
- Commands affecting production systems

### Learn from Explanations

```bash
# Instead of just using suggestions, learn from them
gh copilot explain "the command you just used"

# This helps you understand and remember
```

### Combine with Documentation

```bash
# Get suggestion
gh copilot suggest "docker compose up with rebuild"

# Verify with docs if unsure
gh copilot explain "docker compose up --build"
```

---

## Troubleshooting

### Installation Issues

**Copilot CLI not found:**
```bash
# Reinstall extension
gh extension remove gh-copilot
gh extension install github/gh-copilot

# Verify
gh extension list
```

**Authentication errors:**
```bash
# Re-authenticate
gh auth logout
gh auth login

# Check status
gh auth status
```

### Usage Issues

**No suggestions appearing:**
```bash
# Check internet connection
# Verify Copilot subscription at https://github.com/settings/copilot

# Try explicit target
gh copilot suggest -t shell "your query"
```

**Rate limiting:**
```bash
# Wait a few minutes
# Check status: https://www.githubstatus.com/
```

**Slow responses:**
```bash
# Check network
ping github.com

# Try shorter queries
# Restart if needed
```

### Getting Help

```bash
# View help
gh copilot --help
gh copilot suggest --help
gh copilot explain --help

# Check version
gh copilot --version

# GitHub CLI help
gh help
```

---

## Examples by Category

### DevOps & System Administration

```bash
# Docker
gh copilot suggest "remove all stopped containers"
gh copilot suggest "view docker container logs in real-time"

# Kubernetes
gh copilot suggest "get all pods in namespace"
gh copilot suggest "describe failing pod"

# System monitoring
gh copilot suggest "show top memory-consuming processes"
gh copilot suggest "check system uptime"

# Network
gh copilot suggest "test network connectivity to host"
gh copilot suggest "show all listening ports"
```

### Development Workflows

```bash
# Project setup
gh copilot suggest "initialize git repository"
gh copilot suggest "create gitignore for python project"

# Dependencies
gh copilot suggest "update all npm packages"
gh copilot suggest "check for security vulnerabilities"

# Testing
gh copilot suggest "run tests with coverage"
gh copilot suggest "find failing tests"

# Building
gh copilot suggest "build docker image with tag"
gh copilot suggest "create production build"
```

### Data Processing

```bash
# CSV/JSON
gh copilot suggest "convert csv to json"
gh copilot suggest "extract column from csv"

# Text processing
gh copilot suggest "count unique lines in file"
gh copilot suggest "remove duplicate lines"

# Compression
gh copilot suggest "compress directory to tar.gz"
gh copilot suggest "split large file into chunks"
```

---

## Resources

- **Official Docs**: https://docs.github.com/copilot/github-copilot-in-the-cli
- **GitHub CLI Docs**: https://cli.github.com/manual/
- **Copilot Settings**: https://github.com/settings/copilot
- **GitHub Status**: https://www.githubstatus.com/

---

## Related Guides

- [GitHub Copilot Overview](README.md)
- [Copilot IDE Guide](ide-guide.md)
- [Copilot Chat Guide](chat-guide.md)
- [Comparison with Other Tools](../../comparisons/feature-matrix.md)

---

**Last Updated**: 2025-11-04

**Version**: Copilot CLI 1.0+
