# GitHub Copilot IDE Guide

Deep, IDE-by-IDE guide to running GitHub Copilot inside the editor — including completions, chat, Edits mode, and per-IDE quirks.

---

## Table of Contents

- [Overview](#overview)
- [VS Code](#vs-code)
- [JetBrains IDEs](#jetbrains-ides)
- [Visual Studio](#visual-studio)
- [Neovim and Vim](#neovim-and-vim)
- [Emacs](#emacs)
- [Jupyter Notebooks](#jupyter-notebooks)
- [Keyboard Shortcut Reference](#keyboard-shortcut-reference)
- [Per-IDE Troubleshooting](#per-ide-troubleshooting)

---

## Overview

Copilot ships three families of in-IDE features. They are largely the same across editors, but the UX, key bindings, and depth of integration differ significantly.

| Surface | What it does | Best for |
|---------|--------------|----------|
| **Ghost-text completions** | Inline suggestions as you type | Line and block completion, comment-to-code |
| **Copilot Chat** | Side-panel / inline chat with `@`-mentions and slash commands | Q&A, refactors, explaining selected code |
| **Edits mode** (VS Code) | Multi-file rewrites driven from chat | Cross-file refactors and feature scaffolding |

This guide assumes you have an active Copilot subscription and have signed in once via your IDE. See the [main README](README.md#installation) for sign-up steps.

> **As of 2026**: the "ask, edit, agent" mode triad is the default in VS Code, the JetBrains plugin has reached parity with VS Code for inline chat and slash commands, and the cloud-side analog to agent mode is the [Copilot coding agent](workspace-guide.md) (Copilot Workspace was sunset in May 2025).

---

## VS Code

VS Code is the reference implementation. Every Copilot feature lands here first and tends to lag by months — or never appear — in other IDEs.

### Extensions to Install

Two distinct extensions; install both.

```bash
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
```

- `GitHub.copilot` — ghost-text completions
- `GitHub.copilot-chat` — chat panel, inline chat, Edits mode, agent mode

### Sign-In

1. Open Command Palette: `Cmd+Shift+P` (macOS) / `Ctrl+Shift+P` (Windows/Linux).
2. Run `GitHub Copilot: Sign In`.
3. Browser opens; authorize the device code.
4. Status bar shows a Copilot icon — solid means connected, slashed means disabled for the current file type.

Click the status-bar icon to toggle Copilot on or off per file or per language.

### Inline Suggestions

Ghost text appears in gray after a short debounce.

| Action | Mac | Windows / Linux |
|--------|-----|-----------------|
| Accept entire suggestion | `Tab` | `Tab` |
| Accept next word | `Cmd+→` | `Ctrl+→` |
| Accept next line | `Cmd+Enter` | `Ctrl+Enter` (via "Accept Line" command — bind manually) |
| Next alternative | `Option+]` | `Alt+]` |
| Previous alternative | `Option+[` | `Alt+[` |
| Dismiss | `Esc` | `Esc` |
| Open suggestions panel | `Ctrl+Enter` | `Ctrl+Enter` |
| Trigger completion manually | `Option+\` | `Alt+\` |

**Settings worth changing on day one:**

```jsonc
{
  // Disable in plain text, markdown, and YAML if you find it noisy
  "github.copilot.enable": {
    "*": true,
    "plaintext": false,
    "markdown": true,
    "yaml": false,
    "scminput": false
  },

  // Show suggestions in the comment box of your VCS panel (nice for commit messages)
  "github.copilot.editor.enableAutoCompletions": true,

  // How long to wait before showing ghost text (lower = snappier, slightly more network)
  "editor.inlineSuggest.suppressSuggestions": false,

  // Use the new "Next Edit Suggestions" model (predicts your next edit, not just the next token)
  "github.copilot.nextEditSuggestions.enabled": true
}
```

### Side-Panel Chat vs Inline Chat

**Side-panel chat** (`Ctrl+Cmd+I` / `Ctrl+Alt+I`):
- Persistent thread visible in the activity bar.
- Best for explanations, planning, "how do I…" questions.
- Has access to `@workspace`, `@vscode`, `@terminal`, `@github` participants.

**Inline chat** (`Cmd+I` / `Ctrl+I`):
- Pops up directly over your selection.
- Best for "rewrite this", "add error handling here", "convert to async".
- Edits are previewed as a diff; accept with `Cmd+Enter` / `Ctrl+Enter`.

A good rule: if you can express the task by pointing at code, use inline chat. If you need to talk about code that doesn't exist yet, use the panel.

### Edits Mode (Multi-File Edits)

Edits mode is the bridge between inline chat (one file) and agent-style workflows (full task). Open it from the chat panel dropdown (or `Cmd+Shift+I` then switch mode).

**Workflow:**

1. Add files to the working set by dragging from Explorer or using `@file path/to/file.ts`.
2. Describe the change: *"Add pagination to the listUsers handler and update the test file accordingly."*
3. Copilot proposes diffs across every file in the working set.
4. Review hunk-by-hunk. Each hunk has accept / discard / regenerate.

**When Edits mode beats inline chat:**
- Cross-cutting changes (rename a type used in 8 files).
- Feature work that touches handler + model + test.
- Adopting a new library and updating call sites.

**When it doesn't:**
- The working set exceeds ~10 files or ~50k tokens — quality degrades sharply.
- The task requires running commands or reading external docs (use agent mode, or hand it to the coding agent).

### Agent Mode

The newer "Agent" mode in chat lets Copilot run tools (terminal, file system, browser) autonomously, similar to Claude Code or Cursor's composer. Toggle via the mode dropdown at the top of the chat panel.

Agent mode in VS Code as of 2026 supports:
- Running tasks defined in `tasks.json`.
- Executing arbitrary terminal commands (with confirmation).
- Reading and writing files outside the current selection.
- MCP servers configured in `.vscode/mcp.json` (workspace) or a user-level `mcp.json` — run `MCP: Add Server` or `MCP: Open User Configuration` from the command palette. MCP availability is gated by the `chat.mcp.enabled` setting (and org policy on managed accounts).

```jsonc
// .vscode/mcp.json
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp"
    }
  }
}
```

**Caveat:** agent mode is more expensive (it burns GitHub AI Credits faster than Edits mode) and slower. Use it when the task genuinely needs tool use.

### Workspace Indexing

For repos over ~2k files, Copilot uses a remote index to answer `@workspace` questions. Configure:

```jsonc
{
  "github.copilot.chat.codesearch.enabled": true,
  "github.copilot.chat.experimental.codeFeedback": true
}
```

Check index status via `GitHub Copilot: Build Local Workspace Index` in the command palette.

---

## JetBrains IDEs

Covers IntelliJ IDEA, PyCharm, WebStorm, GoLand, Rider, RubyMine, PhpStorm, CLion, and DataGrip — they all share the same Copilot plugin.

### Install

1. `Settings` → `Plugins` → Marketplace tab.
2. Search "GitHub Copilot".
3. Install both **GitHub Copilot** and **GitHub Copilot Chat** if listed separately (recent versions ship them together).
4. Restart the IDE.
5. `Tools` → `GitHub Copilot` → `Login to GitHub`.

### Inline Completions

Ghost text behaves the same as VS Code. JetBrains-specific bindings:

| Action | Mac | Windows / Linux |
|--------|-----|-----------------|
| Accept | `Tab` | `Tab` |
| Next suggestion | `Option+]` | `Alt+]` |
| Previous suggestion | `Option+[` | `Alt+[` |
| Open completions panel | `Option+\` | `Alt+\` |
| Dismiss | `Esc` | `Esc` |
| Trigger manually | `Option+\` | `Alt+\` |

Watch for keymap conflicts — JetBrains' default keymap binds `Alt+[`/`Alt+]` to navigation in some scopes. Rebind via `Settings` → `Keymap` → search "Copilot".

### Chat

`Tools` → `GitHub Copilot` → `Open Copilot Chat`, or click the Copilot icon in the right sidebar.

JetBrains chat as of 2026 supports:
- Slash commands (`/explain`, `/fix`, `/tests`, `/doc`, `/simplify`).
- `@workspace`, `@project`, `@file` mentions.
- Inline chat triggered via `Ctrl+Shift+G` (default).

**What's missing vs VS Code:**
- No first-class Edits mode (multi-file diffs land in the chat as code blocks; you apply manually).
- Agent mode is in early preview on some products only.
- MCP server config has to be done via plugin settings, not `settings.json`.

### IDE-Specific Settings

`Settings` → `Languages & Frameworks` → `GitHub Copilot`:

- **Enable/disable per language** — same idea as VS Code's `github.copilot.enable`.
- **Proxy** — JetBrains-specific; uses IDE proxy settings by default.
- **Inlay hints color** — match to your theme so ghost text is readable.

### Working with IntelliJ-Style Refactors

JetBrains refactor menus (`Refactor` → `Rename`, `Extract`, `Inline`) still beat Copilot for mechanical refactors. Use Copilot Chat for *intent-driven* refactors:

> "Extract the validation logic in `UserController#create` into a separate `UserValidator` class with a fluent API."

Then use the IDE's quick-fixes to clean up imports and formatting.

---

## Visual Studio

For Visual Studio 2022 (17.8+) on Windows.

### Install

1. `Extensions` → `Manage Extensions`.
2. Search "GitHub Copilot".
3. Install **GitHub Copilot** and **GitHub Copilot Chat**.
4. Restart Visual Studio.
5. `Tools` → `Options` → `GitHub` → `Copilot` → sign in.

### Features

Visual Studio gets most of the Copilot feature set, with a few VS-specific niceties:

- **Chat in the editor margin** — small chat icon next to method definitions for quick "explain this method".
- **Solution-aware chat** — `@workspace` understands `.sln` structure, not just files.
- **Inline rewriting** — `Alt+/` triggers inline chat on the current selection.

### Keyboard Shortcuts (default)

| Action | Keys |
|--------|------|
| Accept suggestion | `Tab` |
| Next suggestion | `Alt+.` |
| Previous suggestion | `Alt+,` |
| Open chat | `Alt+/` then `C` |
| Inline chat | `Alt+/` |
| Trigger manually | `Alt+\` |

### Caveats

- C++ support is solid for IntelliSense-level prediction but weaker for cross-translation-unit reasoning.
- XAML completions are usable but lag VS's own IntelliCode for control completions.

---

## Neovim and Vim

The Vim plugin (`github/copilot.vim`) provides ghost-text completions. Chat is provided by a separate community plugin (`CopilotChat.nvim`) and is Neovim-only.

### Install Completions

**vim-plug:**

```vim
Plug 'github/copilot.vim'
```

**lazy.nvim:**

```lua
{ "github/copilot.vim" }
```

**packer:**

```lua
use { "github/copilot.vim" }
```

After installing, run `:Copilot setup` and follow the device-code flow in a browser.

### Default Mappings

| Action | Mapping |
|--------|---------|
| Accept | `<Tab>` (overrides existing `<Tab>` map — see below) |
| Next | `<M-]>` (`Alt+]`) |
| Previous | `<M-[>` (`Alt+[`) |
| Dismiss | `<C-]>` |
| Trigger | `<M-\>` (`Alt+\`) |

**`<Tab>` conflict**: if you use a snippet engine or another completion plugin (nvim-cmp, coc.nvim), `<Tab>` will fight. Disable Copilot's mapping and bind a different key:

```lua
vim.g.copilot_no_tab_map = true
vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false,
})
```

### Filetype Filtering

```vim
let g:copilot_filetypes = {
      \ 'markdown': v:true,
      \ 'yaml': v:false,
      \ 'gitcommit': v:true,
      \ '*': v:true,
      \ }
```

### Chat (Neovim only)

[CopilotChat.nvim](https://github.com/CopilotC-Nvim/CopilotChat.nvim) provides a chat UI. Install:

```lua
{
  "CopilotC-Nvim/CopilotChat.nvim",
  dependencies = {
    { "github/copilot.vim" },
    { "nvim-lua/plenary.nvim" },
  },
  build = "make tiktoken",
  opts = {
    model = "claude-sonnet-4.5", -- or another model your Copilot plan permits (see :CopilotChatModels)
  },
}
```

Commands:
- `:CopilotChat` — open chat window
- `:CopilotChatExplain` — `/explain` on selection
- `:CopilotChatTests` — `/tests` on selection
- `:CopilotChatFix` — `/fix` on selection

### Vim (Not Neovim)

Vim 9.0+ works with `github/copilot.vim` for completions. No chat plugin exists for classic Vim — use the [Copilot CLI](cli-guide.md) (`copilot`) in a terminal for chat- and agent-style work.

---

## Emacs

`copilot.el` provides ghost-text completions. `copilot-chat.el` provides chat.

### Install Completions

With `use-package` and `straight.el`:

```elisp
(use-package copilot
  :straight (:host github :repo "copilot-emacs/copilot.el" :files ("*.el"))
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("TAB" . copilot-accept-completion)
              ("C-TAB" . copilot-accept-completion-by-word)
              ("M-n" . copilot-next-completion)
              ("M-p" . copilot-previous-completion)))
```

After install: `M-x copilot-login`.

### Chat

```elisp
(use-package copilot-chat
  :straight (:host github :repo "chep/copilot-chat.el" :files ("*.el")))
```

Open with `M-x copilot-chat-display`. Slash commands work as in VS Code.

### Caveats

- The Emacs plugins are community-maintained and lag the official VS Code/JetBrains releases.
- `company-mode` and `corfu` can conflict with ghost-text rendering — ensure Copilot's overlay is shown above the completion popup, or disable popups inside prog-modes.

---

## Jupyter Notebooks

There is **no official GitHub Copilot extension for JupyterLab**. The supported route for notebook work with Copilot is VS Code's notebook editor.

### VS Code Notebook Route

1. Install the `Jupyter` extension in VS Code.
2. Open `.ipynb` files.
3. All Copilot features (completions, chat, Edits mode, agent mode) work cell-by-cell.

Edits mode can update multiple cells together (e.g., refactor a function defined in cell 3 and its usage in cell 7), which no in-browser JupyterLab assistant matches.

If you must stay in the JupyterLab UI, the AI assistants available there are third-party/community projects, not GitHub Copilot — evaluate them separately.

---

## Keyboard Shortcut Reference

Consolidated table — verify against your current keymap, since defaults drift between releases.

### Completions

| Action | VS Code (Mac) | VS Code (Win/Linux) | JetBrains | Visual Studio | Vim |
|--------|---------------|---------------------|-----------|---------------|-----|
| Accept | `Tab` | `Tab` | `Tab` | `Tab` | `<Tab>` |
| Accept word | `Cmd+→` | `Ctrl+→` | — | — | — |
| Next | `Option+]` | `Alt+]` | `Option+]` | `Alt+.` | `<M-]>` |
| Previous | `Option+[` | `Alt+[` | `Option+[` | `Alt+,` | `<M-[>` |
| Dismiss | `Esc` | `Esc` | `Esc` | `Esc` | `<C-]>` |
| Trigger | `Option+\` | `Alt+\` | `Option+\` | `Alt+\` | `<M-\>` |
| Open panel | `Ctrl+Enter` | `Ctrl+Enter` | — | — | `:Copilot panel` |

### Chat

| Action | VS Code (Mac) | VS Code (Win/Linux) | JetBrains | Visual Studio |
|--------|---------------|---------------------|-----------|---------------|
| Open chat panel | `Ctrl+Cmd+I` | `Ctrl+Alt+I` | Sidebar icon | `Alt+/` then `C` |
| Inline chat | `Cmd+I` | `Ctrl+I` | `Ctrl+Shift+G` | `Alt+/` |
| Quick chat (popup) | `Cmd+Shift+I` | `Ctrl+Shift+I` | — | — |
| Submit | `Enter` | `Enter` | `Enter` | `Enter` |
| New line | `Shift+Enter` | `Shift+Enter` | `Shift+Enter` | `Shift+Enter` |

---

## Per-IDE Troubleshooting

### VS Code

**No ghost text appearing:**
1. Check status bar — slashed Copilot icon means disabled for this file type.
2. `Output` panel → select `GitHub Copilot` from the dropdown. Look for auth errors or 429s.
3. Run `Developer: Reload Window`.
4. `GitHub Copilot: Sign Out`, then sign in again.

**Chat replies are empty / cut off:**
- GitHub AI Credits exhausted for the month. Switch to a lighter included model (e.g., GPT-5 mini or Claude Haiku 4.5), wait for the monthly reset, or add a budget at <https://github.com/settings/billing>.

**`@workspace` returns "no relevant code found":**
- Workspace index not built. Run `GitHub Copilot: Build Local Workspace Index`.
- Repo too large — check `github.copilot.advanced.indexing.maxFiles`.

### JetBrains

**"Copilot was not able to fetch suggestions":**
- Almost always a proxy/firewall issue. `Settings` → `HTTP Proxy` → configure or set to auto.
- Confirm `api.githubcopilot.com` is reachable: `curl -I https://api.githubcopilot.com`.

**Completions never appear:**
- Confirm plugin is enabled in the right scope: `Tools` → `GitHub Copilot` → `Enable Completions in <language>`.
- Check IDE log: `Help` → `Show Log in Finder/Explorer` → grep for `copilot`.

**Tab insert vs accept conflict:**
- Live templates and tab-driven snippets fight Copilot. Rebind one of them in `Settings` → `Keymap`.

### Visual Studio

**Chat panel empty after install:**
- Sign-in not completed. `Tools` → `Options` → `GitHub` → `Copilot` → click sign-in.
- Restart VS — its extension hot-load is unreliable.

**Slow completions in large solutions:**
- Disable Copilot for generated files (`.g.cs`, `.Designer.cs`) via `.editorconfig`:

```ini
[*.g.cs]
github_copilot_enable = false
```

### Vim / Neovim

**`:Copilot setup` hangs:**
- Network blocking GitHub OAuth device flow. Use a different network or set `g:copilot_proxy`.
- Manually copy the device code and complete the flow in your browser.

**No suggestions in a buffer:**
- `:Copilot status` — should print "Online" and the active filetype.
- `let g:copilot_filetypes['<filetype>'] = v:true`.

### Emacs

**Server crashes on startup:**
- `copilot.el` requires `node >= 18`. Verify with `M-x copilot-diagnose`.
- Reinstall the Copilot agent: `M-x copilot-install-server`.

**`TAB` cycles candidates instead of accepting:**
- `company-mode` is intercepting. Bind Copilot's accept to `C-<tab>` or `M-<tab>` to avoid the conflict.

### Notebooks (VS Code)

**Completions appear in some cells but not others:**
- Check the cell language — cells using shell magics (e.g., `%%bash`) may not get language-appropriate suggestions.
- Markdown cells follow your `github.copilot.enable` setting for `markdown`.

---

## Choosing an IDE for Copilot

If Copilot is your primary AI tool and you have flexibility in editor choice:

- **VS Code** — always the most complete experience. Edits mode, agent mode, MCP integration ship here first.
- **JetBrains** — strong second choice for Java/Kotlin/Go/Python; you gain great refactor tooling but lose multi-file edits.
- **Vim / Neovim** — completions only (with community chat); fine if you live in the terminal and use the Copilot CLI (`copilot`) for chat and agent work.
- **Visual Studio** — best for .NET-heavy work; Copilot here has good solution awareness but trails VS Code by months.
- **Emacs** — works, community-maintained, expect rough edges.

---

## Related Guides

- [Copilot Chat Guide](chat-guide.md) — deeper coverage of chat features and `@`-participants
- [Copilot Coding Agent Guide](workspace-guide.md) — the cloud-side, issue-to-PR workflow
- [Copilot Best Practices](best-practices.md) — getting good output reliably
- [Copilot CLI Guide](cli-guide.md) — terminal companion
- [Main Copilot README](README.md)

---

**Last Updated**: 2026-06-11
