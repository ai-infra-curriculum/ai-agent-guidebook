# Claude Skills

The Skills system packages reusable prompts, tool configs, and workflows. Skills are how you scale tribal knowledge from "thing I copy-paste into every session" into "thing the agent loads on demand."

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
2. **A slash command.** Skills with a leading slash (`/my-skill`) are invokable explicitly. Users type `/my-skill arg` and the skill's body is injected with `arg` available as input.

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
metadata:
  category: deployment
  version: 2.1.0
  owner: platform-team
  estimated_duration_minutes: 8
  requires_tools: [Bash, Read, Write]
  requires_mcp: [kubernetes-staging, slack]
---

# Deploy to Staging

Follow these steps in order. Do not skip steps.

## 1. Preflight

Run the preflight script and verify it exits 0:

    Bash(command="./scripts/preflight.sh")

If preflight fails, STOP and report the failure to the user.

## 2. Confirm deployment target

Read `runbook.md` and confirm the deployment target with the user before
proceeding.

## 3. Deploy

[... rest of the workflow ...]
```

Frontmatter field reference:

| Field | Required | Purpose |
|-------|----------|---------|
| `name` | yes | Unique identifier. Lowercase, hyphenated. Invoked as `/<name>` |
| `description` | yes | What gates auto-loading. See [The Description Field Is the Gate](#the-description-field-is-the-gate) |
| `metadata.category` | no | Free-form taxonomy for `claude skills list` |
| `metadata.version` | no | Semver. Useful for distributed skills |
| `metadata.owner` | no | Team or person responsible |
| `metadata.requires_tools` | no | Built-in tools the skill expects. Surface a warning if missing |
| `metadata.requires_mcp` | no | MCP servers expected to be connected |
| `metadata.estimated_duration_minutes` | no | Hint for the user |

Only `name` and `description` are load-bearing. Everything else is metadata for humans.

---

## Where Skills Live

Three scopes, evaluated together at session start:

| Scope | Path | Visible to |
|-------|------|------------|
| User-global | `~/.claude/skills/` | Every session you run |
| Project-local | `<repo>/.claude/skills/` | Sessions started in this repo |
| Plugin-bundled | `<plugin>/skills/` | Sessions where the plugin is installed |

A user-global skill and a project-local skill with the same `name` will collide. Project wins. Inspect what is loaded:

```bash
claude skills list
claude skills list --json
```

Inside a session:

```
/skills              # interactive list of available skills
/skill-info my-name  # show frontmatter and body of a specific skill
```

---

## How Skills Load: Auto vs Invoked

### Explicit invocation

The user types `/<skill-name>`. The skill's body is injected as instructions for the current turn. Arguments after the slash command become available context.

```
/deploy-to-staging
/deploy-to-staging --confirm  # arguments accessible to the skill body
```

This is the explicit, deterministic path. No selection logic; the user named it, it loads.

### Auto-invocation

The orchestrator scans available skill descriptions on every turn and decides whether to load one based on what the user is asking. The skill body is injected automatically; the user does not see the load happen.

This is governed entirely by the `description` field. If the description does not clearly say *when* the skill applies, auto-invocation will be unreliable.

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
plugin:my-plugin:skill-name
```

The slash invocation respects the namespace:

```
/my-plugin:skill-name
```

This prevents collisions between identically-named skills from different plugins. User-installed skills from `~/.claude/skills/` get no namespace prefix — they are top-level.

When two plugins both ship a `commit` skill, you'd address them as `/plugin-a:commit` and `/plugin-b:commit`. If you want one of them as your default `/commit`, copy or symlink the file into `~/.claude/skills/commit/`.

---

## Bundling Resources

A skill is a directory. The body of `SKILL.md` can instruct the agent to read other files in the same directory:

```markdown
For the full deployment procedure, read `runbook.md` in this skill directory.
For the rollback script, see `scripts/rollback.sh`.
```

Path resolution is relative to the skill directory, not the working directory. The agent uses its `Read` tool to fetch them.

This pattern matters for context economy. The auto-loaded payload is just `SKILL.md`. The 2,000-line runbook is loaded only when needed. A 30-skill install might have 50KB of always-loaded skill descriptions plus megabytes of on-demand reference material — but the always-loaded payload stays small.

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
name: commit
description: |
  Use when the user asks to commit, "make a commit", "stage and commit", or
  after a logical chunk of work is done and the user wants to checkpoint.
  Produces a Conventional Commits-formatted commit using staged or unstaged
  changes. Skip when the user has explicitly asked for a different commit
  message style.
metadata:
  category: git
  version: 1.0.0
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

Test by reloading and invoking:

```bash
claude skills reload
claude
# > /commit
```

If the model doesn't pick it up on a natural-language "let's commit this," sharpen the description.

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
- **Version your skills.** Bump `metadata.version` on breaking changes so consumers can pin.
- **Keep the auto-loaded body short.** Less than 150 lines if you can. Reference longer material from `runbook.md`.
- **Lead with triggers in the description.** First sentence: when to use. Second sentence: what it does. Third: what it doesn't do.
- **Don't auto-invoke destructive skills.** Anything that writes, deploys, or rotates secrets should require explicit `/skill-name`.
- **Test the description by reading it cold.** If you can't tell from the description alone when this skill should fire, the orchestrator can't either.
- **Use `metadata.requires_mcp` honestly.** It gates a warning if the user lacks the server; nothing kills trust faster than a skill that silently fails because the user's environment didn't have what it assumed.
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

Package as a Claude Code plugin. The plugin manifest declares which skills it ships; users install the plugin and the skills appear with the `plugin:<name>:` prefix.

### Public

Publish to a registry (the community is converging on a few — check `awesome-claude-skills` for current options). Versioned, reviewed, installable with one command.

---

## Debugging Skill Loading

### "My skill exists but never auto-loads"

Almost always the description. Read it cold. If the description is "A helper for things," rewrite with explicit triggers.

Check that the orchestrator can even see the skill:

```bash
claude skills list | grep my-skill
```

If missing, it failed to parse. Run:

```bash
claude skills validate
```

Common causes: invalid YAML frontmatter (tab characters, unquoted strings with colons), missing `name`, file not named `SKILL.md`.

### "Slash command doesn't fire"

Invocation is case-sensitive. `/MySkill` and `/myskill` are different. Match the `name` field exactly.

### "Skill loads but the model ignores its instructions"

The body conflicts with the parent system prompt or with another skill's body. Lower-scope skills (project) win over user-global, but two project-local skills can still collide. Use `/skill-info` to see what is actually loaded into context.

### "Skill loaded but a tool call inside failed"

Either the tool is denied by `permissions`, or the required MCP server is not connected. Check `claude mcp status` and `permissions.allow` in `settings.json`.

### "Skill ran in the wrong scope (e.g. project skill ran in unrelated session)"

You started `claude` from a directory inside the project. Project skills load whenever the cwd is under the project root. Move to a different directory or temporarily disable the skill with `claude skills disable <name>`.

---

## Related

- [Agents](agents.md) — agent definitions share the same scoping and frontmatter shape.
- [Hooks](hooks.md) — for behavior that should run unconditionally, not just when a trigger fires.
- [Advanced](advanced.md) — context budgets and how skills consume them.
