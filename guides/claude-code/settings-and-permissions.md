# Settings and Permissions

How `settings.json` is layered, and how to use permission rules to cut approval fatigue without handing over the keys.

Last verified: 2026-10 (against code.claude.com/docs, Claude Code v2.1.306).

---

## Table of Contents

- [Why This Matters](#why-this-matters)
- [The Settings Hierarchy](#the-settings-hierarchy)
- [Managed (Policy) Settings](#managed-policy-settings)
- [Anatomy of settings.json](#anatomy-of-settingsjson)
- [Permission Rules: allow / ask / deny](#permission-rules-allow--ask--deny)
- [Rule Syntax](#rule-syntax)
- [Permission Modes](#permission-modes)
- [Useful Keys: env and additionalDirectories](#useful-keys-env-and-additionaldirectories)
- [A Worked Example](#a-worked-example)
- [Checklist](#checklist)
- [Sources](#sources)

---

## Why This Matters

Constant permission prompting trains you to approve on autopilot, which is *less* safe. The fix is configuration: **allowlist the boring-and-safe operations, hard-deny the dangerous ones, and let the prompts that remain actually mean something.**

Note the changed baseline: since v2.1.283, interactive terminal and VS Code sessions start in **auto mode** by default, where a classifier model reviews actions instead of prompting you (see [Permission Modes](#permission-modes)). `claude -p` and the Agent SDK still start in Manual (`default`) mode. Your allow/ask/deny rules matter in every mode — deny rules apply even in `bypassPermissions`.

---

## The Settings Hierarchy

Claude Code merges settings from several files. Precedence, highest first:

1. **Managed / policy settings** (admin-pushed via `managed-settings.json`, MDM / registry policy, or server-managed settings from the claude.ai admin console) — nothing in your files or `--settings` overrides a managed key
2. **Command line** — JSON passed with `--settings <file-or-json>` for that session (other flags such as `--permission-mode` or `--model` set one thing for the session)
3. **`.claude/settings.local.json`** — your personal, per-project settings (gitignored by default)
4. **`.claude/settings.json`** — project settings (commit this to share with the team)
5. **`~/.claude/settings.json`** — your user-level defaults across all projects

List keys such as `permissions.allow` **merge** across files rather than override. Environment variables are not a level in this stack; each variable/key pair has its own rule (e.g. an exported `ANTHROPIC_MODEL` beats any file's `model`).

The practical split: put **team conventions** in `.claude/settings.json` (committed), keep **personal overrides** in `.claude/settings.local.json` (Claude Code adds it to your global git excludes when it creates the file; add it to `.gitignore` yourself if you create it by hand), and let admins enforce non-negotiables via managed settings.

You can also change settings without editing files: `/config` opens the settings UI, and `/config key=value` sets a key directly (also works with `-p`).

---

## Managed (Policy) Settings

Organizations can ship settings that users cannot override. The file lives at:

| OS | Path |
|----|------|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux and WSL | `/etc/claude-code/managed-settings.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` |

A `managed-settings.d/` drop-in directory next to the file is also read, and on Windows the same JSON can be delivered through the `HKLM\SOFTWARE\Policies\ClaudeCode` registry key. Organizations on claude.ai can push **server-managed settings** from the admin console instead of touching each machine.

This is where you'd lock down dangerous modes for a fleet — e.g. `permissions.disableBypassPermissionsMode` and `disableAutoMode` (set to `"disable"`) — so no one can opt out, or restrict models with `availableModels`.

---

## Anatomy of settings.json

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": ["Bash(npm run lint)", "Bash(npm run test *)"],
    "ask": ["Bash(git push *)"],
    "deny": ["Read(./.env)", "Read(./secrets/**)"],
    "defaultMode": "acceptEdits",
    "additionalDirectories": ["../shared-lib"]
  },
  "env": {
    "NODE_ENV": "development"
  },
  "model": "sonnet"
}
```

Adding the `$schema` line gives you editor validation and autocomplete for every key.

---

## Permission Rules: allow / ask / deny

Three lists govern what Claude can do without asking:

- **`allow`** — run without prompting
- **`ask`** — always prompt, even if another rule would allow it
- **`deny`** — never allowed, no prompt (use for secrets and destructive commands)

Two rules you must internalize:

1. **Rules merge across scopes; they don't override.** A `deny` in user settings still applies even if a project `allow` exists.
2. **Evaluation order is `deny` → `ask` → `allow`, and `deny` always wins.** If a command matches both `allow` and `deny`, it's denied.

That means `deny` is your safety net: it can't be accidentally loosened by a more permissive project file.

---

## Rule Syntax

Rules are `Tool(specifier)`:

```jsonc
"Bash(npm run build)"            // exact command
"Bash(git commit *)"             // git commit with any arguments
"Read(./.env)"                   // a specific file
"Read(./secrets/**)"             // a glob
"Edit(src/**)"                   // edits scoped to a directory
"WebFetch(domain:example.com)"   // fetches to one domain
"WebFetch"                       // a whole tool, unqualified
"mcp__github__*"                 // every tool from one MCP server
"Agent(Explore)"                 // one sub-agent type
"Agent(model:opus)"              // match a tool *parameter* (deny/ask rules, v2.1.178+)
```

The older `:*` suffix (`Bash(git commit:*)`) still works as an equivalent trailing wildcard, but the docs and the permission dialog now write the space-separated form. Bash rules are checked against each subcommand of a compound command, and commands Claude Code can't parse safely fail closed to a prompt. In deny rules, `"*"` in the tool-name position denies every tool.

Path specifiers use gitignore-style anchoring:

| Pattern | Anchored to |
|---------|-------------|
| `/path` | Project root |
| `//path` | Filesystem root |
| `~/path` | Home directory |

Common starting point: allow your lint/test/build commands and read-only git, `ask` on anything that writes to the remote (`git push`), and deny reads of `.env`, `secrets/`, and credentials. Run `/permissions` to view rules by scope, add or remove them, and (in auto mode) edit classifier rules on its **Auto mode** tab.

---

## Permission Modes

The mode sets the baseline behavior; configure it with `defaultMode` in settings or `--permission-mode` on the CLI:

| Mode | What runs without asking |
|------|--------------------------|
| `default` (shown as **Manual**; `manual` is accepted as an alias) | Reads only; prompts for edits, commands, and network |
| `acceptEdits` | Reads, file edits, and common filesystem commands (`mkdir`, `mv`, `cp`, …) |
| `plan` | Reads (plus classifier-approved commands when auto mode is available); edits wait for an approved plan |
| `auto` | Everything, with a classifier model reviewing each action in the background |
| `dontAsk` | Reads inside your working directories and pre-approved tools; anything that would prompt is **denied** — for locked-down CI |
| `bypassPermissions` | Everything (dangerous — isolated containers/VMs only) |

Cycle modes in-session with `Shift+Tab`.

**Auto mode** is the built-in starting mode for interactive terminal and VS Code sessions on v2.1.283+, on every plan and provider, when the model supports it (on the Anthropic API: Opus 4.6+, Sonnet 4.6+, Haiku 5.5, or Fable). The classifier blocks by default things like `curl | bash`, sending sensitive data to external endpoints, production deploys, force pushes, `git reset --hard` / `git clean -fd` on work you didn't ask to discard, `terraform destroy`, and merging un-approved PRs. Explicit `ask` rules still prompt, and `/auto-mode-setup` drafts `autoMode.environment` entries describing your trusted infrastructure. Auto mode reduces prompts; it is **not** a sandbox.

Where a mode can be set:

- `defaultMode: "auto"` and `"bypassPermissions"` **don't take effect from project files** (`.claude/settings.json`, `.claude/settings.local.json`) — a cloned repo can't put you into them. Set those in `~/.claude/settings.json`, managed settings, or with `--permission-mode`. Other modes apply from any file.
- `claude -p` and the Agent SDK start in `default` unless you pass `--permission-mode`.

For unattended/fleet use, admins can disable the riskiest modes via managed settings (`permissions.disableBypassPermissionsMode`, `disableAutoMode: "disable"`).

---

## Useful Keys: env and additionalDirectories

- **`env`** applies environment variables to every session, so you stop wrapping `claude` in shell scripts just to set `NODE_ENV` or a region.
- **`additionalDirectories`** grants Claude file access to directories outside the project root — handy for monorepos or a shared library that lives a level up. (The `/add-dir` command and `--add-dir` flag do the same per session; most `.claude/` configuration in an added directory is *not* loaded — it grants file access, not config.)
- **`sandbox`** settings (`sandbox.enabled`, plus network and credential controls such as `sandbox.credentials`) run Bash inside an OS-level sandbox on macOS, Linux, and WSL2. Sandboxing and permission modes are independent and combine.

---

## A Worked Example

A pragmatic project `.claude/settings.json` for a Node service:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(pnpm install)",
      "Bash(pnpm lint)",
      "Bash(pnpm typecheck)",
      "Bash(pnpm test *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Edit(src/**)",
      "Edit(tests/**)"
    ],
    "ask": ["Bash(git push *)"],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Bash(rm -rf *)"
    ],
    "defaultMode": "acceptEdits"
  },
  "env": { "NODE_ENV": "development" }
}
```

The result: Claude lints, type-checks, tests, and commits without nagging; pushing to the remote still asks; reading secrets or `rm -rf` is denied regardless of any other file or mode. (`acceptEdits` is fine in a committed file; if you want auto mode, each developer sets it in their own user settings.) Treat a pattern-based `rm -rf` deny as a speed bump, not a guarantee — determined shell tricks can route around string matching, which is why sandboxing and auto mode's classifier exist.

---

## Checklist

- [ ] Team conventions in committed `.claude/settings.json`; personal tweaks in gitignored `.claude/settings.local.json`
- [ ] `$schema` line added for validation
- [ ] Safe lint/test/build/git commands allowlisted to cut prompt fatigue
- [ ] Secrets and destructive commands in `deny` (remember: `deny` always wins)
- [ ] Remote-affecting actions (`git push`) left on `ask`
- [ ] For fleets: dangerous modes locked off via managed settings
- [ ] Decided deliberately between Manual, `acceptEdits`, and auto mode (now the interactive default)

---

## Sources

- [Claude Code settings](https://code.claude.com/docs/en/settings) — the settings hierarchy, managed-file paths, `env`, `additionalDirectories`, modes
- [Identity and access management / permissions](https://code.claude.com/docs/en/permissions) — rule syntax, path anchors, `deny` → `ask` → `allow` evaluation, parameter matching
- [Choose a permission mode](https://code.claude.com/docs/en/permission-modes) — modes, auto mode, starting-mode rules
- [Managed settings](https://code.claude.com/docs/en/managed-settings) — file paths, drop-in directory, registry, server-managed settings
- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) — allowlisting strategy

> Anthropic's official docs moved to `code.claude.com`; older `anthropic.com/engineering` and `docs.anthropic.com` URLs now redirect there.
