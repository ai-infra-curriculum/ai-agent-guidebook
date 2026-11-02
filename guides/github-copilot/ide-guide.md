# GitHub Copilot IDE Guide

Deep, IDE-by-IDE guide to running GitHub Copilot inside the editor — including completions, chat, agent mode, and per-IDE quirks.

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
| **Agent mode** | Multi-file edits, terminal commands, and MCP tools driven from chat | Cross-file refactors, feature work, fix-until-green loops |

This guide assumes you have an active Copilot subscription and have signed in once via your IDE. See the [main README](README.md#installation) for sign-up steps.

> **As of October 2026**: agent mode is the center of gravity in every major Copilot IDE; the cloud-side analog is [Copilot cloud agent](workspace-guide.md) (formerly "coding agent"; Copilot Workspace was sunset in May 2025), and the terminal/desktop analogs are the [Copilot CLI](cli-guide.md) and the GitHub Copilot app.

---

## VS Code

VS Code is the reference implementation. New Copilot features usually land here (and in the Copilot CLI and desktop app) first, and can lag by months in other IDEs. This section covers Copilot specifics; the [VS Code guide](../vscode/README.md) goes deep on agent mode, harnesses, MCP, and customization.

### Setup

AI features are built into VS Code, and Microsoft has consolidated Copilot — including inline suggestions — into the single **GitHub Copilot Chat** extension (`GitHub.copilot-chat`); the older standalone `GitHub.copilot` completions extension was slated for deprecation. You don't need to install anything by hand:

1. Hover over the Copilot icon in the Status Bar and select **Use AI Features** — or run `GitHub Copilot: Sign in` from the Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`).
2. Sign in with GitHub (GitHub Enterprise users choose **Continue with GHE.com**). Your existing plan is used; otherwise you're enrolled in Copilot Free.
3. The Status Bar Copilot dashboard shows how much of your monthly allowance you've used.

To turn every AI feature off, set `chat.disableAIFeatures` to `true`.

### Inline Suggestions

Ghost text appears in gray as you type; **next edit suggestions (NES)** go further and predict the next edit you're likely to make elsewhere in the file.

| Action | Mac | Windows / Linux |
|--------|-----|-----------------|
| Accept entire suggestion | `Tab` | `Tab` |
| Accept next word | `Cmd+→` | `Ctrl+→` |
| Next alternative | `Option+]` | `Alt+]` |
| Previous alternative | `Option+[` | `Alt+[` |
| Dismiss | `Esc` | `Esc` |
| Trigger completion manually | `Option+\` | `Alt+\` |

Defaults drift between releases — confirm in **Keyboard Shortcuts** (search "inline suggest").

**Settings worth knowing on day one:**

```jsonc
{
  // Per-language enablement (these are the defaults)
  "github.copilot.enable": {
    "*": true,
    "plaintext": false,
    "markdown": false,
    "scminput": false
  },

  // Next edit suggestions (on by default)
  "github.copilot.nextEditSuggestions.enabled": true
}
```

### Chat Surfaces

| Surface | Mac | Windows / Linux | Best for |
|---------|-----|-----------------|----------|
| **Chat view** | `Ctrl+Cmd+I` | `Ctrl+Alt+I` | Planning, explanations, multi-step agent work |
| **Inline chat** (editor and terminal) | `Cmd+I` | `Ctrl+I` | "Rewrite this", "add error handling here" — previewed as a diff |
| **Quick Chat** | `Shift+Option+Cmd+L` | `Ctrl+Shift+Alt+L` | One-shot questions without leaving the editor |
| New chat session | `Cmd+N` (in chat) | `Ctrl+N` (in chat) | Clean context |

A good rule: if you can express the task by pointing at code, use inline chat. If you need to talk about code that doesn't exist yet, use the Chat view.

### Built-In Agents: Ask, Plan, Agent

The agent picker in the Chat view offers three built-in agents (plus any [custom agents](../vscode/customization.md) you define):

- **Ask** — answers questions about your code; no edits.
- **Plan** (`/plan`) — researches the task and produces an implementation plan for you to approve before anything changes.
- **Agent** — autonomously edits files across the workspace, runs terminal commands and tasks (subject to your permission level), uses MCP tools, and iterates until done. **Autopilot** is a permission mode for agent sessions that keeps going without check-ins.

> **Edit mode is gone.** The old "Edits" multi-file mode was deprecated in VS Code 1.110 and removed in 1.126. Use **Agent** for multi-file changes (review its diffs before keeping them) or **Plan** when you want to approve the approach first.

**Harnesses:** since VS Code 1.143 (October 19, 2026), new agent sessions run on the **Copilot harness** — the same runtime as the Copilot CLI and the Copilot app — by default. You can also pick the older in-editor **Local** harness, the **Claude** or **Codex** harnesses, or a **Cloud** target that hands the session to [Copilot cloud agent](workspace-guide.md) (`/delegate` does the same from chat). Some features (prompt files, tool sets, chat participants) only work in the Local harness. See [VS Code agent mode](../vscode/agent-mode.md).

### MCP Servers

Agent sessions can call tools from MCP servers. Where VS Code reads configuration depends on the harness:

- **Copilot harness (default):** `~/.copilot/mcp-config.json` (shared with the Copilot CLI) and a workspace-root `.mcp.json`, both using a top-level `mcpServers` key.
- **Local harness:** `.vscode/mcp.json` or your profile's `mcp.json`, using a top-level `servers` key (plus `inputs` and `sandbox`). The add flow now labels `.vscode/mcp.json` as deprecated.

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp"
    }
  }
}
```

Run **MCP: Add Server** from the Command Palette, or browse the MCP gallery with `@mcp` in the Extensions view (preview). On Business/Enterprise, MCP access is controlled by organization policy. Details in the [VS Code MCP guide](../vscode/mcp-servers.md).

**Caveat:** agent sessions burn GitHub AI Credits faster than ask-style chat (they make many model calls) and are slower. Use them when the task genuinely needs tool use.

### Workspace Context

You no longer need `@workspace` to ask about the repo — in the Copilot harness, chat participants such as `@workspace` are deprecated and unsupported; just ask the agent, which searches the codebase itself. Semantic code search relies on the Copilot service (it isn't available with bring-your-own-key models alone). Use `#`-mentions (for example `#file`) to pin specific files into context.

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

JetBrains chat supports slash commands for common tasks (type `/` to see the current list), file and project context references, inline chat, grouped chat turns with turn navigation, and copy/edit actions on your earlier messages. Shortcuts vary by keymap — search "Copilot" in `Settings` → `Keymap`.

**Agent mode, MCP, and customization in JetBrains:**
- Copilot chat in JetBrains has an agent mode alongside ask mode (diagnostic **Fix** actions use agent mode when it's available).
- MCP servers are configured in an `mcp.json` file opened from the Copilot MCP settings (or from agent mode's tools menu → add more tools); a setting lets you turn off automatic MCP server startup.
- Chat reads personal, repository-wide (`.github/copilot-instructions.md`), and path-specific instructions; custom agents are in public preview.
- Enterprise admins can set a managed default model for new conversations.

**What still lags VS Code:** new agent features (Agents window, third-party agent hand-off, canvases, sandboxing) typically land in VS Code, the CLI, and the Copilot app first.

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

For Visual Studio on Windows (2022 version 17.8 or later).

### Install

- **Visual Studio 2022 17.10 and later**: Copilot is included by default as a built-in component — just sign in with your GitHub account.
- **17.8 / 17.9**: install the unified GitHub Copilot extension from `Extensions` → `Manage Extensions`, restart, then sign in.

Visual Studio can also start Copilot cloud agent sessions directly.

### Features

Visual Studio gets most of the Copilot feature set, with a few VS-specific niceties:

- **Chat in the editor margin** — small chat icon next to method definitions for quick "explain this method".
- **Solution-aware chat** — chat understands `.sln` structure, not just files.
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
  opts = {},
}
```

Pick a model your plan permits with `:CopilotChatModels` (or set `opts.model` to one of the IDs it lists) — Copilot's lineup changes monthly, so avoid hard-coding a model that may be retired.

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
3. Copilot completions, chat, and agent mode work with notebook cells.

Agent mode can update multiple cells together (e.g., refactor a function defined in cell 3 and its usage in cell 7).

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
| Open panel | — | — | — | — | `:Copilot panel` |

### Chat

| Action | VS Code (Mac) | VS Code (Win/Linux) | JetBrains | Visual Studio |
|--------|---------------|---------------------|-----------|---------------|
| Open chat panel | `Ctrl+Cmd+I` | `Ctrl+Alt+I` | Sidebar icon | `Alt+/` then `C` |
| Inline chat | `Cmd+I` | `Ctrl+I` | See Keymap | `Alt+/` |
| Quick chat (popup) | `Shift+Option+Cmd+L` | `Ctrl+Shift+Alt+L` | — | — |
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
- GitHub AI Credits exhausted for the month. Switch to Auto (discounted) or a lighter model such as Claude Haiku 5.5, wait for the monthly reset (00:00 UTC on the 1st), or add a budget at <https://github.com/settings/billing>.

**Agent can't find relevant code / ignores your MCP servers:**
- Check which harness the session uses. The default Copilot harness doesn't support `@workspace`-style participants (just ask directly) and reads MCP servers from `~/.copilot/mcp-config.json` and `.mcp.json`, not `.vscode/mcp.json`.
- Semantic code search requires the Copilot service; with BYOK-only setups it isn't available.

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

- **VS Code** — always the most complete experience. Agent harnesses, the Agents window, MCP, and third-party agents ship here first.
- **JetBrains** — strong second choice for Java/Kotlin/Go/Python; you gain great refactor tooling, with agent features arriving somewhat later than in VS Code.
- **Vim / Neovim** — completions only (with community chat); fine if you live in the terminal and use the Copilot CLI (`copilot`) for chat and agent work.
- **Visual Studio** — best for .NET-heavy work; Copilot here has good solution awareness but trails VS Code by months.
- **Emacs** — works, community-maintained, expect rough edges.

---

## Related Guides

- [Copilot Chat Guide](chat-guide.md) — deeper coverage of chat features and `@`-participants
- [Copilot Cloud Agent Guide](workspace-guide.md) — the cloud-side, issue-to-PR workflow
- [VS Code Guide](../vscode/README.md) — agent mode, harnesses, MCP, and customization in depth
- [Copilot Best Practices](best-practices.md) — getting good output reliably
- [Copilot CLI Guide](cli-guide.md) — terminal companion
- [Main Copilot README](README.md)

---

**Last Updated**: 2026-10-21
