# Claude Skills

The Skills system packages reusable prompts, tool configs, and workflows. Skills are how you scale tribal knowledge from "thing I copy-paste into every session" into "thing the agent loads on demand."

Claude Code skills follow the open [Agent Skills](https://agentskills.io) standard and extend it with Claude Code-only features (invocation control, sub-agent execution, dynamic context injection). Custom commands in `.claude/commands/*.md` have been merged into skills — they still work and create the same `/name` commands.

Last verified: 2026-10 (against [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills), Claude Code v2.1.306).

---

## Table of Contents

- [What a Skill Is](#what-a-skill-is)
- [Skill Anatomy](#skill-anatomy)
- [SKILL.md and Frontmatter](#skillmd-and-frontmatter)
- [Where Skills Live](#where-skills-live)
- [How Skills Load: Auto vs Invoked](#how-skills-load-auto-vs-invoked)
- [The Description Field Is the Gate](#the-description-field-is-the-gate)
- [Plugin Namespacing](#plugin-namespacing)
- [Bundling Resources](#bundling-resources)
- [Writing a Skill from Scratch](#writing-a-skill-from-scratch)
- [Effective vs Ineffective Skills](#effective-vs-ineffective-skills)
- [Best Practices](#best-practices)
- [Distributing Skills](#distributing-skills)
- [Debugging Skill Loading](#debugging-skill-loading)

---

## What a Skill Is

A Skill is a directory containing a `SKILL.md` file plus any supporting assets (templates, scripts, prompts, examples). The `SKILL.md` has YAML frontmatter declaring the skill's name, description, and metadata, followed by markdown instructions that the model loads when the skill is invoked.

Two ways to think about a skill:

1. **A scoped system prompt.** When a skill is loaded, its body content joins the conversation as authoritative instructions for that turn and (usually) subsequent ones. It is the same shape as the system prompt — it just appears later, conditionally.
2. **A slash command.** Every user-invocable skill is a slash command. Users type `/my-skill arg` and the skill's body is injected with `arg` available as `$ARGUMENTS` (or `$0`, `$1`, or named `$arg` placeholders).

The Skills system was designed for two problems:

- **Stop pasting the same setup prose into every session.** ("Always run `pnpm typecheck` after edits. Always commit with Conventional Commits. Always...") Put it in a skill, register the trigger, forget about it.
- **Distribute repeatable workflows.** A team can ship a `deploy-to-staging` skill that encodes the exact 12 steps with the exact tool calls. New hires invoke `/deploy-to-staging` and get a known-good procedure.

---

## Skill Anatomy

A minimal skill is one file:

```
my-skill/
└── SKILL.md
```

A real skill usually has more:

```
deploy-to-staging/
├── SKILL.md              # Metadata + main instructions
├── runbook.md            # Detailed step-by-step (referenced from SKILL.md)
├── scripts/
│   ├── preflight.sh
│   └── rollback.sh
├── templates/
│   └── release-notes.md
└── examples/
    └── successful-deploy.log
```

The model reads `SKILL.md` first. The body can instruct the agent to `Read` other files in the skill directory on demand. This pattern keeps the auto-loaded payload small.

---

## SKILL.md and Frontmatter

```markdown
---
name: deploy-to-staging
description: |
  Deploy the current branch to the staging environment. Use when the user
  asks to "deploy to staging", "push to staging", "stage this", or after a
  feature is verified locally and the user wants to validate in staging.
  Handles preflight checks, deployment, smoke tests, and rollback on failure.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/preflight.sh *) Bash(kubectl rollout status *) Read
---

# Deploy to Staging

Follow these steps in order. Do not skip steps.

## 1. Preflight

Run the preflight script and verify it exits 0:

    ${CLAUDE_SKILL_DIR}/scripts/preflight.sh

If preflight fails, STOP and report the failure to the user.

## 2. Confirm deployment target

Read `runbook.md` and confirm the deployment target with the user before
proceeding.

## 3. Deploy

[... rest of the workflow ...]
```

`${CLAUDE_SKILL_DIR}` expands to the skill's own directory in both the body and Bash rules in `allowed-tools`, so the bundled script runs without a prompt no matter where the skill is installed or what the working directory is.

Frontmatter field reference (all fields are optional; names must match exactly — unknown fields are silently ignored):

| Field | Purpose |
|-------|---------|
| `name` | Command name shown in the `/` menu and typed to invoke it. Defaults to the directory name; the directory name also still invokes it |
| `description` | **Recommended.** What gates auto-loading. If omitted, the first non-empty line of the body is used. See [The Description Field Is the Gate](#the-description-field-is-the-gate) |
| `when_to_use` | Extra trigger context (phrases, example requests). Appended to `description` in the skill listing; the combined text is truncated at 1,536 characters |
| `argument-hint` | Autocomplete hint, e.g. `[issue-number]` |
| `arguments` | Named positional arguments for `$name` placeholders in the body |
| `disable-model-invocation` | `true` = only you can invoke it (via `/name`); Claude never auto-loads it, it can't be preloaded into sub-agents, and scheduled loops won't run it. Use for deploys, commits, anything with side effects |
| `user-invocable` | `false` = hidden from the `/` menu and not runnable by typing `/name`; only Claude can load it |
| `allowed-tools` | Tools Claude may use **without a permission prompt during the turn that invokes the skill** (space- or comma-separated, or a YAML list). It does *not* restrict other tools |
| `disallowed-tools` | Tools removed from Claude's pool while the skill is active — the field that actually *restricts* |
| `model` / `effort` | Model and effort level for the rest of the invoking turn |
| `context` / `agent` | `context: fork` runs the skill in a sub-agent (of the type in `agent`) instead of the main conversation |
| `background` | With `context: fork`, set `false` to wait for the result in the same turn (default `true`, v2.1.218+) |
| `paths` | Glob patterns; Claude auto-loads the skill only when working with matching files |
| `hooks` | Hooks registered when the skill is invoked, for the rest of the session |
| `shell` | `bash` (default) or `powershell` for inline `` !`command` `` blocks |
| `license`, `compatibility`, `metadata` | Agent Skills spec fields; Claude Code accepts but doesn't act on them. Put your own data (version, owner, tags) under `metadata` |

Only `description` (plus `when_to_use` and `paths`) is load-bearing for auto-invocation. The invocation-control and tool fields change behavior; everything else is presentation.

**Portability warning:** claude.ai skill uploads, the Skills API, and `package_skill.py` accept only the six spec fields (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`) and **fail with a hard error** on anything else. If a skill must work outside Claude Code, stick to those six.

---

## Where Skills Live

| Scope | Path | Visible to |
|-------|------|------------|
| Enterprise | `.claude/skills/` in the managed settings directory | Every user on machines your org deploys it to |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects on this machine |
| Project | `<repo>/.claude/skills/<name>/SKILL.md` | Sessions in this repo (commit it to share) |
| Nested | `<subdir>/.claude/skills/<name>/SKILL.md` | Loads once Claude works on files under `<subdir>` (monorepos) |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Wherever the plugin is enabled, as `/plugin-name:skill-name` |
| claude.ai account | Skills enabled on your claude.ai account | Cowork, cloud sessions, and terminal sessions signed in with that account |

When names collide: **enterprise beats personal, and personal beats project** — with `deploy` in both `~/.claude/skills/` and the project's `.claude/skills/`, `/deploy` runs the personal one. Your skill also replaces a bundled skill or built-in command of the same name (but not its aliases). Plugin skills are namespaced, so they never collide. Inspect what is loaded inside a session:

```
/skills              # interactive list; t sorts by token count, Space cycles visibility
/context             # see what the skill listing is costing
/skill-doctor        # context cost and usage per skill — find ones to turn off
```

Skill directories are watched live: adding, editing, or removing a skill under `~/.claude/skills/` or the project's `.claude/skills/` takes effect within the current session, no restart needed. If you create a top-level skills directory that didn't exist at session start, run `/reload-skills`.

Claude Code also ships **bundled skills** — `/doctor`, `/code-review`, `/simplify`, `/batch`, `/debug`, `/loop`, `/verify`, `/run`, `/claude-api`, `/fewer-permission-prompts`, `/update-config`, `/dataviz`, and more. Check `/skills` before writing one that already exists; `disableBundledSkills` hides them.

---

## How Skills Load: Auto vs Invoked

### Explicit invocation

The user types `/<skill-name>`. The skill's body is injected as a message and **stays in the conversation** for later turns (Claude Code doesn't re-read the file). Arguments after the slash command fill `$ARGUMENTS`; if the body has no placeholder, they're appended as `ARGUMENTS: ...`. You can stack up to five leading skills in one message (`/skill-a /skill-b do XYZ`).

```
/deploy-to-staging
/deploy-to-staging --confirm  # available as $ARGUMENTS
```

This is the explicit, deterministic path. No selection logic; the user named it, it loads.

### Auto-invocation

A listing of skill names and descriptions sits in context every turn, and Claude decides whether to load one based on what the user is asking (via the `Skill` tool). The listing has a budget of about 1% of the context window; when it overflows, the descriptions of your least-used skills are dropped first — another reason to keep descriptions tight and prune unused skills.

This is governed almost entirely by the `description` (and `when_to_use`) text. If it does not clearly say *when* the skill applies, auto-invocation will be unreliable. `paths:` adds a file-based condition on top.

### Hybrid

Many shipped skills have both behaviors:

- "Use when the user types `/test-driven-development` or asks how to TDD."
- "Use PROACTIVELY after the user writes new code." → loads automatically without slash.

The two paths are not mutually exclusive.

---

## The Description Field Is the Gate

This is the single most important thing to understand about Skills.

The orchestrator decides whether to load a skill by looking at its `description`. The body text — no matter how good — is invisible until the load fires. A perfect skill with a vague description never runs. A mediocre skill with a sharp description runs at the right moments.

Treat the description like the trigger condition in a state machine.

### Ineffective

> A helpful skill for working with the database.

This will never load reliably. "Helpful" and "working with" carry no signal.

> Database operations skill.

Same problem. The model has no idea when to pick this versus the 200 other skills also nominally about "operations."

### Effective

> Use when the user asks to query, migrate, seed, or back up a PostgreSQL database. Handles connection string discovery, transaction wrapping, and dry-run mode. Use PROACTIVELY after any schema change is committed to verify the migration applies cleanly on a fresh database.

Three things working here:

1. **Enumerated triggers.** "query, migrate, seed, or back up." No ambiguity.
2. **Bounded scope.** "PostgreSQL." Not "any database."
3. **Proactive cue.** "Use PROACTIVELY after..." tells the orchestrator to consider auto-loading.

### Patterns that work

- **"Use when the user asks to X, Y, or Z."** Enumerate the trigger phrases.
- **"Use PROACTIVELY after [event]."** Auto-load cue.
- **"Skip when [condition]."** Prevent over-firing.
- **"Handles A, B, C. Does NOT handle D."** Disambiguates from sibling skills.

### Anti-patterns

- Single-sentence vague descriptions.
- "Best practices for X." (Triggers nothing.)
- Descriptions that describe the skill author rather than the skill's behavior.
- Marketing-style copy. ("Powerful, easy-to-use database skill.")

---

## Plugin Namespacing

Skills shipped as part of a plugin (a Claude Code plugin, not an MCP server) are namespaced with the plugin name:

```
/my-plugin:skill-name
```

This prevents collisions between identically-named skills from different plugins. The bare `/skill-name` also invokes a plugin skill as long as no other command claims that name. User-installed skills from `~/.claude/skills/` get no namespace prefix — they are top-level.

When two plugins both ship a `commit` skill, you'd address them as `/plugin-a:commit` and `/plugin-b:commit`. If you want one of them as your default `/commit`, copy or symlink the folder into `~/.claude/skills/commit/`. Plugin skills aren't affected by `skillOverrides`; manage them through `/plugin`.

---

## Bundling Resources

A skill is a directory. The body of `SKILL.md` can instruct the agent to read other files in the same directory:

```markdown
For the full deployment procedure, read `runbook.md` in this skill directory.
For the rollback script, see `scripts/rollback.sh`.
```

The agent uses its `Read` tool to fetch them. For anything you *run*, reference it as `${CLAUDE_SKILL_DIR}/scripts/...` so the path resolves to the skill's directory regardless of the working directory.

This pattern matters for context economy. Only names and descriptions are always loaded; `SKILL.md` loads on invocation; the 2,000-line runbook loads only when needed.

Common supporting files:

- `runbook.md` — long-form step-by-step instructions.
- `templates/` — file templates to copy.
- `scripts/` — shell scripts to execute.
- `examples/` — concrete examples for the model to imitate.
- `schemas/` — JSON schemas or OpenAPI specs.

---

## Writing a Skill from Scratch

A worked example: a skill that creates a Conventional Commit.

```bash
mkdir -p ~/.claude/skills/commit
$EDITOR ~/.claude/skills/commit/SKILL.md
```

```markdown
---
description: |
  Use when the user asks to commit, "make a commit", "stage and commit", or
  after a logical chunk of work is done and the user wants to checkpoint.
  Produces a Conventional Commits-formatted commit using staged or unstaged
  changes. Skip when the user has explicitly asked for a different commit
  message style.
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *)
---

# Commit

Steps:

1. Run `git status` to see what is staged and unstaged.
2. Run `git diff --staged` to see the staged diff. If empty, also run
   `git diff` for unstaged changes.
3. Run `git log --oneline -10` to read the recent commit message style.
4. Decide the commit type from {feat, fix, refactor, docs, test, chore,
   perf, ci}. Choose by looking at what changed, not what the user said.
5. Draft a subject line: `<type>: <imperative summary>`. Maximum 72 chars.
   Imperative mood ("add X", not "added X" or "adds X").
6. If the change is non-trivial, draft a body: 1-3 sentences focused on
   "why", not "what". Wrap at 80 chars.
7. Show the proposed message to the user and wait for confirmation.
8. On confirmation, run:

       Bash(command="git commit -m '<subject>' -m '<body>'")

9. Report the resulting commit hash.

Do NOT include "Generated with Claude Code" or Co-Authored-By trailers
unless the user explicitly asks. Do NOT use `git add -A` — only commit
what is already staged unless the user says otherwise.
```

Test by invoking — skill directories are watched, so no reload step is needed:

```bash
claude
# > /commit
```

This example sets `disable-model-invocation: true` because it writes to git — so it runs only when you type `/commit`. For a read-only skill you *want* auto-loaded, drop that line; if the model doesn't pick it up on a natural-language request, sharpen the description. Note that `git commit` itself isn't in `allowed-tools`, so the final commit still goes through your normal permission check.

---

## Effective vs Ineffective Skills

### Effective

**Concrete steps.** Numbered, ordered, specific.

**Explicit guardrails.** "Do NOT do X" is as important as "Do Y."

**Bounded scope.** One skill per workflow, not one skill per domain.

**Output format prescribed.** "Report the commit hash" is better than "Inform the user."

**Tool calls illustrated.** Show the exact tool invocation; the model will imitate.

### Ineffective

**Open-ended advice.** "Try to make a good commit message." Useless.

**Multi-purpose skills.** A `git` skill that handles commits, branches, rebases, and merges. Each path is under-specified.

**Conflicting with sibling skills.** Two `deploy` skills that don't disambiguate when each applies. The orchestrator picks one at random.

**Reliance on tools the skill never lists.** Skill assumes `mcp__github__create_pr` is available; it isn't. Skill body crashes mid-execution.

---

## Best Practices

- **One skill, one job.** Split before you grow past two pages of body content.
- **Keep the auto-loaded body short.** Less than 150 lines if you can. Reference longer material from `runbook.md`.
- **Lead with triggers in the description.** First sentence: when to use. Second sentence: what it does. Third: what it doesn't do.
- **Don't auto-invoke destructive skills.** Anything that writes, deploys, or rotates secrets should set `disable-model-invocation: true` and require explicit `/skill-name`.
- **Test the description by reading it cold.** If you can't tell from the description alone when this skill should fire, the orchestrator can't either.
- **Scope `allowed-tools` honestly.** It *grants* permission without prompting for the invoking turn, so list only narrow patterns the workflow genuinely needs (`Bash(npm test *)`, never bare `Bash`). It is **not** gated by workspace trust: a repository's skills can pre-approve tools even in a `-p` run in a folder you've never trusted, so review checked-in skills before running Claude Code in an unfamiliar repo. (Orgs can ignore skill grants with the managed `allowManagedPermissionRulesOnly` setting.) Use `disallowed-tools` or deny rules to *restrict*.
- **Review your own skills quarterly.** Triggers drift; what was important six months ago may not be now.

---

## Distributing Skills

### Within a team

Commit `<repo>/.claude/skills/` to the repository. Every developer who clones gets the skill set on next `claude` invocation.

```bash
# Skill scoped to this project
mkdir -p .claude/skills/team-conventions
$EDITOR .claude/skills/team-conventions/SKILL.md
git add .claude/skills
git commit -m "chore: add team-conventions skill"
```

### Across teams

Package as a Claude Code plugin: put skills under the plugin's `skills/` directory (they're auto-discovered; the `.claude-plugin/plugin.json` manifest is optional metadata) and distribute through a marketplace. Users install with `/plugin install <plugin>@<marketplace>` and the skills appear as `/<plugin>:<skill>`. Measure triggering with `claude plugin eval` (v2.1.269+), which runs your plugin against test cases and, by default, again without it.

### Public

Publish a plugin to a public marketplace (Anthropic's official one is `claude-plugins-official`), or share the skill folder itself — the format is the open Agent Skills standard, which other agent tools also read. Anthropic's example skills live at [github.com/anthropics/skills](https://github.com/anthropics/skills).

---

## Debugging Skill Loading

### "My skill exists but never auto-loads"

Almost always the description. Read it cold. If the description is "A helper for things," rewrite with explicit triggers.

Check that the orchestrator can even see the skill: run `/skills` and look for it in the list. If missing, check the file is named `SKILL.md` in its own folder. If the frontmatter YAML doesn't parse, the skill still loads with *no* metadata — `/name` works but there's no description to match — so run `claude plugin validate .claude/skills` (or `--debug`) to find the parse error.

Also check: the skill doesn't set `disable-model-invocation: true` (that removes it from Claude's listing); `skillOverrides` hasn't set it to `off` or `name-only`; and its description wasn't dropped from an over-budget listing (`/doctor` and `/skill-doctor` show listing cost).

### "Slash command doesn't fire"

The command comes from the frontmatter `name` if set, otherwise the directory name (the directory name also still works). Check for a same-named personal skill shadowing your project one, a name containing invisible or direction-changing characters (refused at load — look for `[names]` in the debug log), and `user-invocable: false`.

### "Skill loads but the model ignores its instructions"

The body conflicts with the system prompt or with another skill's body. Run `/context` to see what is actually loaded. Write guidance as standing instructions ("run the tests after every edit") since the file isn't re-read on later turns, and move rules that must hold every time into a hook (skills can declare `hooks` in frontmatter). After compaction, re-invoke the skill — only the first 5,000 tokens of each invoked skill are carried forward (25,000 tokens total, oldest dropped first).

### "Skill loaded but a tool call inside failed"

Either the tool is denied by `permissions` (deny rules beat `allowed-tools`), the skill's `allowed-tools` grant already cleared (it lasts only for the invoking turn), the required MCP server is not connected, or your org set `allowManagedPermissionRulesOnly` (run `/status` to see skills whose grants were ignored). Check `/mcp` and `permissions` in `settings.json`.

### "Skill ran in the wrong scope (e.g. project skill ran in unrelated session)"

Project skills load from `.claude/skills/` in the starting directory and every parent up to the repository root, and nested `.claude/skills/` directories load once Claude works on files beneath them. To scope a skill to certain files, give it `paths:` frontmatter. To hide one without editing it, use the `/skills` menu (highlight it and press `Space` to cycle `on` / `name-only` / `user-only` / `off`, which writes a `skillOverrides` entry to `.claude/settings.local.json`).

---

## Related

- [Agents](agents.md) — agent definitions use a similar frontmatter shape (note: for agents, project beats user).
- [Skills guide](../skills/guide.md) and [Creating skills](../skills/creating.md) — tool-agnostic authoring guidance.
- [Hooks](hooks.md) — for behavior that should run unconditionally, not just when a trigger fires.
- [Advanced](advanced.md) — context budgets and how skills consume them.
