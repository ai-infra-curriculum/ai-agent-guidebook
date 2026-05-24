# Basic Setup

The first hour. Install one tool, authenticate, run hello-world, hit one MCP server, write one skill.

Last updated 2026-05.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Choose Your Tool](#choose-your-tool)
- [Install](#install)
- [Authenticate](#authenticate)
- [Verify with Hello-World](#verify-with-hello-world)
- [Connect One MCP Server](#connect-one-mcp-server)
- [Write One Skill / Prompt Snippet](#write-one-skill--prompt-snippet)
- [Add Project Rules](#add-project-rules)
- [What You Have Now](#what-you-have-now)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

A working developer environment:

- Git installed and configured
- Node.js 20+ (for Claude Code, most MCP servers)
- Python 3.11+ (for some MCP servers, evaluation tools)
- A terminal you're comfortable in
- A code editor (VS Code, JetBrains, Vim, or any other)
- An account with the model provider you're using (Anthropic, OpenAI, Google, or GitHub)
- A credit card on file with the provider (for non-free tiers)

If you don't have Node.js: install via `nvm` (`curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash`) or `mise` or `fnm`.

If you don't have Python: install via `pyenv` (`curl https://pyenv.run | bash`) or `uv` (`curl -LsSf https://astral.sh/uv/install.sh | sh`).

---

## Choose Your Tool

This walkthrough covers three paths. Pick one based on the [getting-started](getting-started.md) decision tree:

- **Path A: Claude Code** — terminal-first, agentic, MCP-rich
- **Path B: Cursor** — IDE-first, integrated agent mode
- **Path C: GitHub Copilot** — IDE-first, inline completions + chat + Workspace

The setup steps differ. The principles (auth, project rules, MCP, skills) are similar.

---

## Install

### Path A: Claude Code

```bash
# Install globally via npm
npm install -g @anthropic-ai/claude-code

# Verify
claude --version
```

You should see something like `claude 1.x.x`.

### Path B: Cursor

1. Download from [cursor.com](https://cursor.com/download)
2. Install the .dmg / .exe / .deb
3. Launch. The Cursor app is a fork of VS Code with AI built in.

### Path C: GitHub Copilot

In VS Code:

1. Open Extensions sidebar.
2. Search for "GitHub Copilot".
3. Install both **GitHub Copilot** and **GitHub Copilot Chat**.
4. Reload the editor.

In JetBrains:

1. Settings → Plugins → Marketplace.
2. Search "GitHub Copilot". Install.
3. Restart the IDE.

In Vim/Neovim: install via your plugin manager — see [github.com/github/copilot.vim](https://github.com/github/copilot.vim).

---

## Authenticate

### Path A: Claude Code

Two options:

**Option 1: Claude Pro / Max subscription.**

```bash
claude /login
```

Opens a browser, log in with your Anthropic account. Subscription usage tracked there.

**Option 2: API key.**

```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

Add to your shell profile (`~/.zshrc` or `~/.bashrc`) to persist.

Get your API key from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys).

### Path B: Cursor

1. Launch Cursor.
2. On first launch, you'll be prompted to sign in.
3. Sign in with email, GitHub, or Google.
4. Free tier works immediately. For Pro features, upgrade in Settings → Account.

For Bring-Your-Own-Key (use your own Anthropic / OpenAI / Google API keys):

1. Settings → Models.
2. Toggle "Use my API key" for the provider.
3. Paste the key.

### Path C: GitHub Copilot

1. In VS Code, click the Copilot icon in the status bar (bottom right).
2. "Sign in to use GitHub Copilot."
3. Browser opens. Authorize GitHub.
4. You need an active Copilot subscription on the GitHub account.

If you don't have one yet:
- Go to [github.com/settings/copilot](https://github.com/settings/copilot).
- Subscribe to Pro ($10/mo) or use Copilot Free if eligible.

---

## Verify with Hello-World

### Path A: Claude Code

```bash
mkdir hello-claude
cd hello-claude
claude
```

A REPL opens. Try:

```text
Create a Python script that prints "hello from claude" and a Bash script that does the same. Save them as hello.py and hello.sh.
```

Claude will propose tool calls (Write) and ask for permission. Approve.

Verify:

```bash
ls
python hello.py
bash hello.sh
```

Type `exit` or Ctrl+D to leave the REPL.

### Path B: Cursor

1. Open a new folder in Cursor: File → Open Folder → create `hello-cursor`.
2. Press `Cmd/Ctrl + L` to open the chat sidebar.
3. Type:

```text
Create hello.py and hello.sh that both print "hello from cursor"
```

4. Cursor proposes changes. Accept.
5. Open the integrated terminal (`Ctrl + ` `): `python hello.py` and `bash hello.sh`.

### Path C: GitHub Copilot

1. Open a new folder in VS Code: `hello-copilot`.
2. Create `hello.py`. Start typing:

```python
# print hello from copilot
def 
```

3. Copilot suggests the function body. Accept with Tab.
4. Run: `python hello.py`.

For chat: `Cmd/Ctrl + I` opens inline chat, or click the Copilot Chat icon in the activity bar for the panel.

---

## Connect One MCP Server

MCP (Model Context Protocol) servers are tools your AI tool can call. We'll connect the simplest one: a filesystem server.

This step applies to Claude Code primarily; Cursor supports MCP similarly; Copilot does not natively support MCP.

### Path A: Claude Code

Edit `~/.claude.json` (or create it):

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/YOURNAME/Documents"
      ]
    }
  }
}
```

Replace the path with a directory you want the server to expose.

Restart Claude Code. In a new session:

```text
List the top 5 files in my Documents directory and tell me which is most recent.
```

The model should call the filesystem MCP server's `list_directory` tool.

### Path B: Cursor (MCP support)

Cursor 0.42+ supports MCP via Settings → MCP Servers. Same config format. Restart Cursor after editing.

### Add a more useful MCP server

Once you've verified MCP works, swap to one of these:

- **GitHub MCP** (`@modelcontextprotocol/server-github`) — read issues, PRs, repos
- **Postgres MCP** (`@modelcontextprotocol/server-postgres`) — query databases
- **Slack MCP** — read messages, post replies
- **Sequential Thinking MCP** — structured reasoning helper
- **Memory MCP** — persistent memory across sessions

See the [MCP Servers guide](mcp-servers/) for a longer list and config patterns.

---

## Write One Skill / Prompt Snippet

A "skill" is a reusable prompt template. Claude Code has a formal skill system; for other tools, the equivalent is a saved prompt or a `.cursorrules` snippet.

### Path A: Claude Code skill

Create `~/.claude/skills/git-pr-summary/SKILL.md`:

```markdown
---
name: git-pr-summary
description: Summarize the current branch's changes vs main for a PR description
---

# Git PR Summary

Run `git diff main...HEAD` and `git log main...HEAD --oneline`.

Produce a PR description in this exact format:

## Summary
- 2-4 bullet points describing what changed

## Test plan
- [ ] checklist of tests to run

Keep it under 200 words. Focus on the why, not just the what.
```

In a Claude Code session:

```text
/skill git-pr-summary
```

The skill loads and Claude follows the instructions.

### Path B: Cursor (project rules)

Create `.cursorrules` in your project root:

```text
# Project conventions

- TypeScript strict mode always
- Prefer functional components over class components
- All API calls go through src/api/ wrappers
- Tests live next to source as *.test.ts
- Use Tailwind for styling; no inline styles
```

Cursor reads this on every request. No manual loading needed.

### Path C: Copilot (instructions)

Create `.github/copilot-instructions.md`:

```markdown
# Project instructions

When suggesting code in this repo:

- Use TypeScript strict mode
- Functional React components only
- Tests live as *.test.ts adjacent to source
- API calls always go through src/api/
- No inline styles; use Tailwind utility classes
```

Copilot reads this when generating code in the repo (Enterprise + Pro Plus tiers; check current behavior).

---

## Add Project Rules

The single highest-leverage configuration: rules that tell the AI about your project conventions.

### Universal: top-level project document

Create `AGENTS.md` (recognized by Cursor, Cody, and increasingly others) or per-tool variants:

- `CLAUDE.md` — Claude Code
- `.cursorrules` (legacy) or `.cursor/rules/` (current) — Cursor
- `.github/copilot-instructions.md` — Copilot
- `AGENTS.md` — generic, broadly compatible

Template:

```markdown
# Project: [your project name]

## Stack
- Language: TypeScript 5.5 strict
- Framework: Next.js 15 App Router
- DB: Postgres via Prisma
- Auth: Clerk
- Hosting: Vercel
- Tests: Vitest + Playwright

## Conventions
- Files: kebab-case
- Components: PascalCase
- Hooks: useFoo
- API routes: src/app/api/...
- Shared types: src/types/
- No relative imports past 2 levels (use @/ alias)

## Testing
- Every new function gets a Vitest test
- New routes get a Playwright e2e
- Coverage > 80%

## Out of scope
- Don't add new dependencies without asking
- Don't change the database schema without a migration
- Don't modify CI configs

## Useful commands
- `pnpm dev` — local dev server
- `pnpm test` — run tests
- `pnpm lint` — lint check
- `pnpm build` — production build
```

Keep it under 200 lines. The AI reads this on every interaction; tokens matter.

---

## What You Have Now

After this hour, you have:

- A working AI coding tool installed and authenticated
- Verified it works on a trivial task
- Connected at least one MCP server (Claude Code / Cursor path) or set up Copilot completions
- Written one reusable skill or rule snippet
- A project rules file that guides AI suggestions

You're ready for [first-steps.md](first-steps.md) — the first week.

---

## Troubleshooting

### Claude Code

**"command not found: claude"**
- npm global bin not in PATH. Check `npm config get prefix` and add `$(npm config get prefix)/bin` to PATH.

**"Invalid API key"**
- Check `echo $ANTHROPIC_API_KEY` returns the right key.
- Verify it's active at [console.anthropic.com](https://console.anthropic.com).
- For subscription users, run `claude /login` instead.

**MCP server not loading**
- Check `~/.claude.json` is valid JSON (`jq . ~/.claude.json`).
- Restart Claude Code after editing.
- Run the server command manually: `npx -y @modelcontextprotocol/server-filesystem /path` — should print MCP framing.

**Permission prompts for everything**
- Add common safe commands to your allow list. See [security.md](../best-practices/security.md) for examples.

### Cursor

**"Cannot reach AI service"**
- Check Settings → Network. Verify no proxy / firewall blocking `*.cursor.sh`.
- Try toggling models in Settings → Models.

**Slow completions**
- Check Settings → Models — the "fast" tier might be exhausted, falling back to slow.
- Free plan limits: 50 slow / mo (or limited daily). Upgrade or wait for reset.

**Indexing taking forever**
- Add `.cursorignore` with `node_modules`, `dist`, `build`, lockfiles.
- Restart Cursor.

### Copilot

**"GitHub Copilot is not available"**
- Verify subscription at [github.com/settings/copilot](https://github.com/settings/copilot).
- Sign out and sign in again from the status bar.

**Completions don't appear**
- Check status bar — Copilot icon should be solid, not error.
- File extension may not be supported in older versions; try `.js` / `.py`.
- Tab key may be bound to indentation; try `Cmd/Ctrl + →` instead.

**Chat says "I can't help with that"**
- Some chat features need specific subscriptions (Pro Plus / Enterprise).
- Try simpler chat phrasing; explicit "explain this code" works in all tiers.

### General

**"The AI hallucinated something"**
- Provide more grounding (paste real docs, real file contents).
- Pin to a specific model version, not "latest".
- Lower temperature if you can control it.
- Try a different model.

**"It's using the wrong patterns"**
- Add a rules file (above). Tell it what to do, not just what not to do.
- Include 1-2 examples of the right pattern in the rules.

---

## Related

- [Getting Started](getting-started.md)
- [First Steps](first-steps.md)
- [Claude Code Guide](claude-code/)
- [GitHub Copilot Guide](github-copilot/)
- [MCP Servers Guide](mcp-servers/)
- [Skills Guide](skills/)
- [Context Management](../best-practices/context-management.md)
