# Settings and Permissions

How `settings.json` is layered, and how to use permission rules to cut approval fatigue without handing over the keys.

Last updated 2026-06-22.

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

Out of the box, Claude Code asks for confirmation before most actions. That's safe but slow — and constant prompting trains you to approve on autopilot, which is *less* safe. The fix is configuration: **allowlist the boring-and-safe operations, hard-deny the dangerous ones, and let the prompts that remain actually mean something.**

---

## The Settings Hierarchy

Claude Code merges settings from several files. Precedence, highest first:

1. **Managed / policy settings** (admin-pushed) — cannot be overridden, *even by CLI flags*
2. **Command-line arguments** (e.g. `--permission-mode`)
3. **`.claude/settings.local.json`** — your personal, per-project settings (gitignored by default)
4. **`.claude/settings.json`** — project settings (commit this to share with the team)
5. **`~/.claude/settings.json`** — your user-level defaults across all projects

The practical split: put **team conventions** in `.claude/settings.json` (committed), keep **personal overrides** in `.claude/settings.local.json` (gitignored), and let admins enforce non-negotiables via managed settings.

---

## Managed (Policy) Settings

Organizations can ship settings that users cannot override. The file lives at:

| OS | Path |
|----|------|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux | `/etc/claude-code/managed-settings.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` |

This is where you'd lock down dangerous modes for a fleet — e.g. `disableBypassPermissionsMode` and `disableAutoMode` — so no one can opt out.

---

## Anatomy of settings.json

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": ["Bash(npm run lint)", "Bash(npm run test:*)"],
    "ask": ["Bash(git push:*)"],
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
"Bash(npm run build)"      // exact command
"Bash(git commit:*)"       // git commit with any arguments
"Read(./.env)"             // a specific file
"Read(./secrets/**)"       // a glob
"Edit(src/**)"             // edits scoped to a directory
"WebFetch"                 // a whole tool, unqualified
```

Path specifiers use gitignore-style anchoring:

| Pattern | Anchored to |
|---------|-------------|
| `/path` | Project root |
| `//path` | Filesystem root |
| `~/path` | Home directory |

Common starting point: allow your lint/test/build commands and read-only git, `ask` on anything that writes to the remote (`git push`), and deny reads of `.env`, `secrets/`, and credentials.

---

## Permission Modes

The mode sets the baseline behavior; configure it with `defaultMode` in settings or `--permission-mode` on the CLI:

| Mode | Behavior |
|------|----------|
| `default` | Prompt on first use of each tool |
| `acceptEdits` | Auto-accept file edits; still prompt for other actions |
| `plan` | Read-only — Claude can investigate and plan but not modify |
| `auto` | Autonomous, gated by a safety classifier |
| `dontAsk` | Suppress prompts for already-allowed tools |
| `bypassPermissions` | Skip all permission checks (dangerous — sandbox only) |

For unattended/fleet use, admins can disable the riskiest modes via managed settings (`disableBypassPermissionsMode`, `disableAutoMode`).

---

## Useful Keys: env and additionalDirectories

- **`env`** applies environment variables to every session, so you stop wrapping `claude` in shell scripts just to set `NODE_ENV` or a region.
- **`additionalDirectories`** grants Claude file access to directories outside the project root — handy for monorepos or a shared library that lives a level up.

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
      "Bash(pnpm test:*)",
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Edit(src/**)",
      "Edit(tests/**)"
    ],
    "ask": ["Bash(git push:*)"],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Bash(rm -rf:*)"
    ],
    "defaultMode": "acceptEdits"
  },
  "env": { "NODE_ENV": "development" }
}
```

The result: Claude lints, type-checks, tests, and commits without nagging; pushing to the remote still asks; reading secrets or `rm -rf` is impossible regardless of any other file.

---

## Checklist

- [ ] Team conventions in committed `.claude/settings.json`; personal tweaks in gitignored `.claude/settings.local.json`
- [ ] `$schema` line added for validation
- [ ] Safe lint/test/build/git commands allowlisted to cut prompt fatigue
- [ ] Secrets and destructive commands in `deny` (remember: `deny` always wins)
- [ ] Remote-affecting actions (`git push`) left on `ask`
- [ ] For fleets: dangerous modes locked off via managed settings

---

## Sources

- [Claude Code settings](https://code.claude.com/docs/en/settings) — the settings hierarchy, managed-file paths, `env`, `additionalDirectories`, modes
- [Identity and access management / permissions](https://code.claude.com/docs/en/permissions) — rule syntax, path anchors, `deny` → `ask` → `allow` evaluation
- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) — allowlisting strategy

> Anthropic's official docs moved to `code.claude.com`; older `anthropic.com/engineering` and `docs.anthropic.com` URLs now redirect there.
