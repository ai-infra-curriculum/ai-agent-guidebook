---
# ─────────────────────────────────────────────────────────────────────────────
# Skill metadata. Every field below is meaningful — read the comments before
# changing anything. Anything marked REQUIRED breaks loading if missing.
# ─────────────────────────────────────────────────────────────────────────────

# REQUIRED. Kebab-case, globally unique within the skills directory it lives in.
# Convention: <verb>-<noun> or <noun>-<modifier>, e.g. "audit-dependencies",
# "postgres-backup", "react-component-scaffold".
name: example-skill

# REQUIRED. One sentence. Shown in skill pickers. Aim for ≤120 characters.
# Lead with the verb. Avoid "this skill helps you" — say what it does.
description: Example skill template — replace this description with your skill's one-sentence purpose.

# REQUIRED for /skill-name slash invocation. Set to false for skills that
# should only be auto-discovered (not user-invokable by name).
invokable: true

# OPTIONAL. Semver. Bump on breaking change to the skill's interface or output
# shape so dependents can pin.
version: 0.1.0

# OPTIONAL. The agent runtime will route to this skill more eagerly when a user
# message matches one of these triggers. Use sparingly — too many triggers and
# the skill will fire when it shouldn't.
triggers:
  - "when the user asks to <verb> a <noun>"
  - "when a file matching <glob> is opened"
  - "/example-skill"

# OPTIONAL. List the tools/MCP servers the skill expects to be available.
# The runtime won't enforce this, but the body of the skill should fail fast
# with a clear error if a required tool is missing.
requires:
  - filesystem
  - github      # only if you actually need it
  # - postgres
  # - slack

# OPTIONAL. Tags for searchability and grouping in the skill catalog.
tags:
  - example
  - template
  - scaffold

# OPTIONAL. The skill's author. Useful for ownership and contact when something
# breaks. Email or GitHub handle, not "the AI team".
author: your-name@example.com

# OPTIONAL. Last-updated date. Set to today when you copy this template.
last_updated: 2026-05-24

# OPTIONAL. License the skill's helper scripts ship under. Defaults to the
# parent repo's license if omitted.
license: MIT
---

# Example Skill

> Replace this paragraph with a 2–4 sentence description of what your skill
> does, when it activates, and what the user can expect from it. Be concrete:
> "Generates a NestJS controller-service-DTO scaffold for a named resource"
> is far better than "Helps with NestJS scaffolding."

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
| `target_path` | string (path) | yes | Where to write output. Must exist. |
| `resource_name` | string | yes | PascalCase. The "thing" being scaffolded. |
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
   - Read `scripts/example.sh` (the helper script).
   - Compose the command line from inputs.

3. **Dry-run preview.**
   - Run `scripts/example.sh --dry-run …` and capture stdout.
   - Show the user a summary of files that *would* be created.

4. **Confirm with user.**
   - If running non-interactively (e.g., from another agent), skip this step
     iff the caller passed `--auto-confirm`.

5. **Execute.**
   - Run `scripts/example.sh …`.
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
This block is load-bearing — it is what the runtime uses to learn the skill's
*shape*. Make it realistic.

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

Notes for future maintainers — not for the runtime. The runtime stops reading
at `## See Also`; everything below is for humans.

### How to test this skill

```bash
# Run the helper in dry-run mode against a scratch directory.
mkdir -p /tmp/skill-test
bash scripts/example.sh --dry-run --target /tmp/skill-test --name Sample
```

### When to bump version

- Patch (`0.x.y`): wording changes, internal refactor of the helper script.
- Minor (`0.y.0`): new optional inputs, new output files, new tags.
- Major (`y.0.0`): renamed inputs, removed outputs, changed step order in a
  way that downstream callers can observe.

### Known limitations

- Hardcodes NestJS conventions — would need a fork for other frameworks.
- Helper script assumes Bash 4+. Will fail loudly on macOS's stock Bash 3.2.
