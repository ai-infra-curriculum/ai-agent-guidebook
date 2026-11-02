---
# ─────────────────────────────────────────────────────────────────────────────
# Skill metadata. Follows the open Agent Skills spec (agentskills.io) plus a few
# Claude Code extensions, marked below. Claude Code silently ignores unknown
# keys; claude.ai uploads and the Skills API REJECT them. Don't invent keys —
# put your own data under `metadata`.
# Last verified: 2026-10.
# ─────────────────────────────────────────────────────────────────────────────

# REQUIRED (spec). 1-64 chars: lowercase letters, digits, single hyphens; no
# leading/trailing hyphen. MUST match this folder's name. In Claude Code it is
# also the slash command (/example-skill).
# Convention: <verb>-<noun>, e.g. "audit-dependencies", "scaffold-nest-resource".
name: example-skill

# REQUIRED (spec). Max 1,024 chars. Say what the skill does AND when to use it,
# with concrete trigger phrases. This is the only text Claude sees before the
# skill loads, so it decides whether the skill is ever auto-invoked.
description: >-
  Scaffolds a NestJS controller, service, module, DTOs, and spec for a named
  resource. Use when the user asks to scaffold, generate, or add a NestJS
  resource or CRUD module. Skip for renames and for non-NestJS frameworks.

# OPTIONAL (spec). Environment requirements, max 500 chars. Most skills omit it.
compatibility: Requires Bash 4+ and a NestJS project

# OPTIONAL (spec, experimental). PRE-APPROVES these tools so they run without
# a permission prompt during the invoking turn. It does NOT restrict other
# tools. Keep patterns narrow; never list bare `Bash` or `Write`.
# ${CLAUDE_SKILL_DIR} expands to this folder in Claude Code.
allowed-tools: Read Bash(bash ${CLAUDE_SKILL_DIR}/scripts/example.sh --dry-run *)

# OPTIONAL (Claude Code). true = only a human can invoke it via /example-skill;
# Claude never auto-loads it. Recommended for anything that writes files.
disable-model-invocation: true

# OPTIONAL (Claude Code). Shown in autocomplete after the slash command.
argument-hint: "[ResourceName] [target-path]"

# OPTIONAL (Claude Code). Names for positional arguments: $resource and
# $target in the body below map to the first and second argument.
arguments: [resource, target]

# OPTIONAL (spec). License for the skill's bundled files.
license: MIT

# OPTIONAL (spec). Free-form map of string keys to STRING values. Your own
# version, owner, and catalog data live here — not as top-level keys.
metadata:
  version: "0.2.0"
  owner: your-name@example.com
  tags: "example, template, scaffold"
  last-updated: "2026-10-21"
---

# Example Skill

> Replace this paragraph with a 2–4 sentence description of what your skill
> does, when it activates, and what the user can expect from it. Be concrete:
> "Generates a NestJS controller-service-DTO scaffold for a named resource"
> is far better than "Helps with NestJS scaffolding."
>
> Invocation: `/example-skill Payment src/payments`. In the body, `$resource`
> and `$target` expand to those arguments, and `$ARGUMENTS` to the whole string.

---

## When To Use

Bullet list of *concrete* situations where this skill is the right tool. The
goal: a model reading this list can decide in one pass whether to invoke.

- When the user asks for X by name.
- When the user describes the problem X solves without naming it.
- When a particular file pattern is being edited and X is the canonical move.

### When NOT To Use

Just as important. List the look-alike situations where this skill is the
*wrong* answer.

- For Y, use the `other-skill` instead.
- For Z, prefer a manual approach because <reason>.

---

## Required Inputs

What the user (or the calling agent) must supply for the skill to do its job.
If anything below is missing, the skill should ask one clarifying question,
not guess.

| Input | Type | Required | Notes |
|---|---|---|---|
| `target_path` (`$target`) | string (path) | yes | Where to write output. Must exist. |
| `resource_name` (`$resource`) | string | yes | PascalCase. The "thing" being scaffolded. |
| `template_variant` | enum (`minimal` \| `full`) | no (default `minimal`) | Controls scaffold depth. |

---

## Steps

Numbered, deterministic, and brief. Each step should be one verb + one object.
If a step needs branching, name the branches inline rather than nesting.

1. **Validate inputs.**
   - Check `target_path` exists and is writable.
   - Check `resource_name` matches `^[A-Z][A-Za-z0-9]+$`.
   - On failure, return a one-line error naming the invalid field.

2. **Resolve template.**
   - Read `${CLAUDE_SKILL_DIR}/scripts/example.sh` (the helper script).
   - Compose the command line from inputs.

3. **Dry-run preview.**
   - Run `bash ${CLAUDE_SKILL_DIR}/scripts/example.sh --dry-run --target $target --name $resource`
     and capture stdout. (This exact form is pre-approved in `allowed-tools`.)
   - Show the user a summary of files that *would* be created.

4. **Confirm with user.**
   - Show the preview and wait for an explicit yes. If the caller is another
     agent and passed `--auto-confirm` in the arguments, skip this step.

5. **Execute.**
   - Run `bash ${CLAUDE_SKILL_DIR}/scripts/example.sh --target $target --name $resource`.
     This is not pre-approved, so it goes through the normal permission check.
   - On non-zero exit, surface stderr and stop.

6. **Verify.**
   - List the created files.
   - Run any project-level lint/format step that applies to the new files.

7. **Report.**
   - Return a structured result: created files, any warnings, next-step
     suggestion (e.g., "now wire the new module into `app.module.ts`").

---

## Example

A complete invocation, including the user message and the skill's response.
There's no special runtime parsing of this section — but the model reads the
whole body when the skill loads and imitates examples closely, so a realistic
example is the cheapest way to get consistent output.

````text
User:
  Scaffold a Payment resource under src/payments.

Skill (example-skill):
  Inputs resolved:
    target_path:     src/payments
    resource_name:   Payment
    template_variant: minimal

  Dry-run preview:
    + src/payments/payment.controller.ts
    + src/payments/payment.service.ts
    + src/payments/payment.module.ts
    + src/payments/dto/create-payment.dto.ts
    + src/payments/dto/update-payment.dto.ts
    + tests/payments/payment.service.spec.ts

  Confirm? [y/N]

User: y

Skill:
  Created 6 files.
  Lint pass: clean.
  Next step: import PaymentModule into src/app.module.ts.
````

---

## Anti-Patterns

What this skill is NOT for. List the misuse cases you have seen or expect.
This section saves the most time of any in the file.

- **Don't use this skill to rename an existing resource.** Use `refactor-rename`.
- **Don't use this skill for non-NestJS frameworks.** It assumes NestJS
  conventions; the output is wrong shape for Express/Fastify/etc.
- **Don't pipe the output through another scaffold skill in the same turn.**
  Compose them in the calling agent's plan, not implicitly here.

---

## Failure Modes And How To Recover

The realistic ways this skill goes wrong, with recovery steps the calling
agent can follow.

| Failure | Symptom | Recovery |
|---|---|---|
| Target path does not exist | Step 1 errors with `ENOENT` | Ask the user to create the directory or pick a different path. |
| Resource name collision | Step 3 dry-run lists a file that already exists | Stop. Ask the user whether to overwrite, suffix, or abort. |
| Lint fails after scaffold | Step 6 reports lint errors | Surface the errors. Do not auto-fix — the user should see what the scaffold produced. |
| Helper script missing | Step 2 cannot read `scripts/example.sh` | Tell the user the skill is broken-on-disk and stop. |

---

## See Also

Cross-link to neighboring skills, related rules, and external docs. Keep this
short — link only to things a reader will plausibly want.

- `refactor-rename` skill — for renaming, not creating.
- `add-tests` skill — to expand the scaffolded `*.spec.ts` files.
- `templates/AGENTS.md` — for the larger agent-orchestration context.
- Project conventions: `rules/typescript/coding-style.md`.

---

## Maintenance

Notes for future maintainers. The runtime does NOT stop reading at a heading —
the whole file loads into context when the skill is invoked, and in Claude Code
the first 5,000 tokens are what survive compaction. Keep this section short,
or move it to the README so it doesn't cost context on every invocation.

### How to test this skill

```bash
# Run the helper in dry-run mode against a scratch directory.
mkdir -p /tmp/skill-test
bash scripts/example.sh --dry-run --target /tmp/skill-test --name Sample
```

### When to bump `metadata.version`

- Patch (`0.x.y`): wording changes, internal refactor of the helper script.
- Minor (`0.y.0`): new optional inputs, new output files.
- Major (`y.0.0`): renamed inputs, removed outputs, changed step order in a
  way that downstream callers can observe.

### Known limitations

- Hardcodes NestJS conventions — would need a fork for other frameworks.
- Helper script assumes Bash 4+. Will fail loudly on macOS's stock Bash 3.2.
