---
name: skill-with-script-template
description: |
  TEMPLATE: replace with a sharp description. This template is for skills
  that bundle one or more helper scripts (Bash, Python, Node) and orchestrate
  them as part of a multi-step workflow. Triggers: replace these with the
  concrete phrases, file types, or commands that should cause the skill to
  load. Add "Skip when..." anti-triggers if needed to suppress false matches.
version: 0.1.0
requires:
  external-tools:
    - bash
    - python3
metadata:
  allowed-tools:
    - Read
    - Edit
    - Write
    - Bash
    - Grep
  category: example
  tags: [template, advanced, scripts, multi-step]
  author: your-team
inputs:
  - name: target_path
    description: |
      The file or directory the skill should operate on. Optional; if not
      provided, the skill prompts the user.
    required: false
    type: string
---

# Skill With Script Template

A more advanced skill scaffold demonstrating bundled scripts, multi-step
workflows, declared inputs, and explicit verification.

## When to Use

Restate and expand the frontmatter description. Be specific about what the
skill does, what it changes, and what it leaves alone. Mention any
side-effects up front so users invoke it deliberately.

## When Not to Use

List the look-alike scenarios where this skill is the wrong tool. Examples:

- The user only wants a quick check, not the full workflow.
- The target is read-only (e.g., a vendored dependency).
- The repo lacks the tooling this skill depends on.

## Prerequisites

Check at the start of the procedure:

1. The current directory is a Git repository.
2. `python3` is available on PATH (run `which python3`).
3. The repo has a clean working tree (run `git status --porcelain`); if not,
   ask the user whether to proceed.
4. If `inputs.target_path` was not provided, prompt the user for it.

If any prerequisite fails, stop and report. Do not improvise.

## Procedure

This skill executes a 6-step workflow. Steps are designed to be safe to
retry — each step records its progress so the skill can resume after an
interruption.

### Step 1: Discover

Read the target path. Identify:

- File type (extension, MIME type if useful).
- Size and rough structure (line count, top-level sections).
- Any embedded metadata the script will use.

Save a short discovery summary to a temp file at `/tmp/skill-discovery-{ts}.json`.

### Step 2: Validate

Run the bundled validation script:

```bash
python3 scripts/validate.py --input <target_path> --discovery /tmp/skill-discovery-{ts}.json
```

The script exits 0 on success, non-zero on failure. On failure, read the
script's stderr, surface the issue to the user, and stop. Do not proceed
past validation failure.

### Step 3: Plan

Read the validation output and produce a structured plan describing the
changes you intend to make. The plan must list:

- Every file to be created or modified.
- A one-sentence rationale for each change.
- Any external commands to be run.
- Any prerequisites or warnings.

Present the plan to the user. Do not proceed without confirmation.

### Step 4: Execute

After confirmation, execute the plan one item at a time:

1. For each file to create: use `Write` with the planned content.
2. For each file to modify: use `Edit` with the specific old/new strings.
3. For each command to run: invoke via `Bash`.

After each item, append a one-line status to `/tmp/skill-progress-{ts}.log`
so the workflow can be resumed if interrupted.

### Step 5: Verify

Run the bundled verification script:

```bash
bash scripts/verify.sh <target_path>
```

The script checks the post-condition. Exit 0 means the changes are in place
and correct; non-zero means something is wrong. On failure, surface the
issue and roll back the most recent changes if possible (see Rollback).

### Step 6: Report

Generate a summary using `templates/report.md.tmpl`. Fill placeholders with
values from discovery, plan, and execution. Show the report to the user.

## Verification

After the final step:

1. Confirm `git status` shows only the expected files modified.
2. Confirm the verification script exited 0.
3. Confirm the user has reviewed the generated report.

## Rollback

If Step 4 or Step 5 fails:

1. Read `/tmp/skill-progress-{ts}.log` to determine what was done.
2. For each completed item, attempt to undo:
   - Newly created files: delete.
   - Modified files: reset via `git checkout -- <file>` (only if the user
     confirms).
   - External commands: see `references/rollback-commands.md` for the
     per-command undo recipes.
3. Stop after rollback. Do not retry automatically.

## References

- `references/file-type-handlers.md` — per-file-type discovery logic.
- `references/validation-rules.md` — what the validation script enforces.
- `references/rollback-commands.md` — per-command undo recipes.

## Bundled Scripts

- `scripts/validate.py` — runs validation against the target. Inputs: target
  path, discovery JSON. Output: structured JSON on stdout; non-zero exit
  on failure with diagnostics on stderr.
- `scripts/verify.sh` — runs post-condition verification. Inputs: target
  path. Output: human-readable on stdout; exit code indicates success.

Both scripts must be invoked with the bundled Python / Bash; do not rely on
project-local virtual environments unless documented.

## Anti-Patterns

- Do not skip Step 3 (Plan) even for "obvious" changes. The plan is the
  consent surface for the user.
- Do not modify files outside the planned set, even if they look like they
  need similar changes — surface them as follow-ups in the report instead.
- Do not retry on verification failure. Roll back and stop. The user
  decides whether to re-run.
- Do not edit files in the `.git/` directory, the OS temp directory, or
  any path that resolves outside the working tree.
- Do not commit the changes. Generating commits is a separate concern; the
  user (or a dedicated commit skill) handles that.

## Examples

See `examples/` for two worked end-to-end runs:

- `examples/run-small-input/` — minimal happy-path execution.
- `examples/run-with-validation-failure/` — shows the validation-failure
  branch and how the report communicates the failure.

## Failure Modes

| Symptom | Likely Cause | Action |
|---------|--------------|--------|
| Validation exits non-zero | Input does not match expected shape | Surface stderr; stop |
| Verification exits non-zero | Changes did not achieve post-condition | Rollback; report |
| Bash unavailable | Sandbox restriction | Stop; request user adjust permissions |
| Working tree dirty | User had unrelated changes | Ask before proceeding |

---

## Notes for the Skill Author

Delete this section before shipping.

Iteration tips:

1. **Get the script shells working first** — stub scripts that always exit
   0 let you exercise the full procedure before writing real logic.
2. **Wire up the plan/confirm step early** — user trust around "here's
   what I'm about to do" makes everything else safer.
3. **Test the rollback path** — deliberately introduce a failure after a
   partial execution and confirm rollback restores a clean state.
4. **Iterate on the description** — see `creating.md`. The most common bug
   is the description, not the body.

Before shipping: delete this section, narrow `allowed-tools`, populate
`references/` and `examples/`, add to your catalog or plugin manifest, and
bump `version` to `1.0.0`.
