---
name: basic-skill-template
description: |
  TEMPLATE: replace this with a sharp description. State what the skill does
  and the concrete triggers that should cause it to load. Example triggers:
  user mentions a specific command, file type, or workflow phrase. Add
  anti-triggers (skip-when) if the description risks over-matching.
version: 0.1.0
metadata:
  allowed-tools:
    - Read
    - Edit
  category: example
  tags: [template, starter]
---

# Basic Skill Template

A minimal skill scaffold. Copy this folder, rename, and adapt the body.

## When to Use

Restate and expand the frontmatter description here so a reader of the body
alone knows when this skill is appropriate. The model will read this part
when the skill loads.

## Prerequisites

List anything that must be true before this skill runs. Examples:

- The working directory is a git repository.
- The user has `node` installed.
- A specific file exists (e.g., `package.json`).

If a prerequisite fails, stop and report; do not improvise around it.

## Procedure

Write the steps as if you are dictating a precise checklist to a careful
contractor. Numbered. Concrete. Actionable.

1. Read the target file the user named (or the most recently modified file
   in the current directory if the user did not name one).
2. Identify the section of interest. If multiple candidates exist, ask the
   user to confirm before continuing.
3. Apply the transformation. Show the proposed change before writing.
4. After confirmation, write the change.
5. Run the verification step (see Verification section).

## Verification

After the procedure completes:

1. State what was changed in plain language.
2. Identify how the user can confirm the change is correct (e.g., "open the
   file and confirm the new section exists", "run `npm test`").

## References

- `references/notes.md` — deeper background material the model can read on
  demand if a step requires more detail.

## Anti-Patterns

- Do not silently overwrite the user's work. Always show the proposed
  change first.
- Do not run destructive commands without explicit confirmation.
- Do not assume the project structure; check before acting.

## Examples

See `examples/` for a worked input/output pair. Mimic the output structure
when generating new outputs.

---

## Notes for the Skill Author

Delete this section before shipping.

To turn this template into a working skill:

1. **Rename the folder** from `basic-skill/` to your skill's actual name
   (verb-noun, lowercase, hyphenated).
2. **Edit the frontmatter** — particularly the `name` and `description`.
   The description is the most important field; iterate on it. See the
   description-writing section of `creating.md`.
3. **Tighten `allowed-tools`** — list only the tools this skill genuinely
   needs.
4. **Rewrite the Procedure** with the actual steps of your workflow.
5. **Fill or remove the References, Examples, Anti-Patterns sections**
   based on what your skill needs.
6. **Test the skill** — invoke explicitly, test auto-loading triggers, test
   negative cases (it should not load on unrelated requests).
7. **Delete this "Notes for the Skill Author" section** before shipping.
