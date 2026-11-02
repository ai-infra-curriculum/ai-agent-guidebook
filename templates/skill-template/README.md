# Skill Template

A complete starting scaffold for a Claude Skill in the open
[Agent Skills](https://agentskills.io/specification) format. Copy this
directory, rename it, customize the three files, and you have a working skill.

Last verified: 2026-10 (against agentskills.io and
[code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)).

This template is intentionally small — one helper script, one skill definition,
one README. Real skills are often this size; resist the urge to grow it before
you have a reason.

---

## What's In Here

```text
templates/skill-template/
├── README.md              ← this file (delete or rewrite when you customize)
├── SKILL.md               ← the skill definition; the runtime reads this
└── scripts/
    └── example.sh         ← the helper script SKILL.md shells out to
```

Three files. That's the entire scaffold.

---

## How A Skill Is Loaded

Claude Code discovers skills in these locations (other Agent Skills clients
use their own paths):

1. Personal:  `~/.claude/skills/<skill-name>/SKILL.md`
2. Project:   `<repo>/.claude/skills/<skill-name>/SKILL.md` (and nested
   `.claude/skills/` directories in a monorepo)
3. Plugin:    `<plugin>/skills/<skill-name>/SKILL.md`, invoked as
   `/<plugin>:<skill-name>`
4. Enterprise: the managed settings directory

Loading is progressive:

1. At startup, only each skill's `name` and `description` go into context.
2. When the user types `/<name>` — or Claude decides the description matches
   the request — the full body of `SKILL.md` is loaded and stays in the
   conversation.
3. Files in `scripts/`, `references/`, or `assets/` load only when the body
   tells the model to read or run them.

There is no `triggers` list: the `description` (plus Claude Code's optional
`when_to_use` and `paths`) is the only routing signal. The helper script in
`scripts/` is a regular file; in Claude Code, reference it as
`${CLAUDE_SKILL_DIR}/scripts/example.sh` so it resolves no matter what the
working directory is.

---

## How To Customize

### Step 1: Copy and rename

```bash
cp -r templates/skill-template ~/.claude/skills/my-skill
# (or the project-local equivalent: cp -r ... .claude/skills/my-skill)
```

Rename the directory to match the `name` field in your `SKILL.md`. The spec
requires them to match, and in Claude Code `name` is the slash command.

### Step 2: Edit SKILL.md

Open `SKILL.md` and replace, in order:

1. **Frontmatter**:
   - `name`: lowercase, hyphenated, ≤64 chars. Must match the directory name.
   - `description`: what it does **and when to use it**, with concrete trigger
     phrases and a "skip when…" clause. ≤1,024 chars. Lead with the use case —
     Claude Code truncates long descriptions in its skill listing.
   - `allowed-tools`: only narrow pre-approvals, or delete the line. It grants
     prompt-free use; it doesn't restrict anything.
   - `compatibility`: external CLIs or services the skill needs (or delete).
   - `metadata`: version, owner, tags — as **string** values.
2. **Body sections**: walk through every `> Replace this paragraph` marker.
3. **Anti-Patterns and Failure Modes**: do not skip these. They are the
   sections that save the most time for the next reader.

### Step 3: Replace the helper script (or remove it)

`scripts/example.sh` is a deliberately small Bash example. Most real skills
either:

- Shell out to a project's existing tooling (`npm run scaffold`,
  `python -m my_project.codegen`, `terraform fmt`), in which case the helper
  script becomes a thin adapter.
- Skip the helper entirely. Many skills are pure prose ("here are the steps;
  apply them with your normal file tools"). For those, delete `scripts/` and
  drop the references from `SKILL.md` and `allowed-tools`.

Whatever shape the helper takes, keep its interface stable. The skill body
documents the helper's flags and exit codes; if you change them, update the
skill body in the same commit.

### Step 4: Verify

Two quick checks before declaring done:

```bash
# 1. The skill's helper script (if any) runs and respects --dry-run.
bash scripts/example.sh --dry-run --target /tmp --name Sample

# 2. The frontmatter parses (Claude Code v2.1.233+), run on the skills dir:
claude plugin validate ~/.claude/skills    # or .claude/skills for project skills

# 3. Optional: check spec conformance with the reference validator
#    (https://github.com/agentskills/agentskills/tree/main/skills-ref)
skills-ref validate ./my-skill
```

Note: in Claude Code, a skill whose YAML doesn't parse still loads — with no
metadata, so `/name` works but auto-invocation never matches. Don't take
"it ran when I typed it" as proof the frontmatter is valid.

---

## How To Install

The location of the skills directory depends on your runtime. The common ones:

### Claude Code (default)

User-level:

```bash
mkdir -p ~/.claude/skills
cp -r my-skill ~/.claude/skills/
```

Project-level (skill is only available within this project):

```bash
mkdir -p .claude/skills
cp -r my-skill .claude/skills/
```

If the same name exists at both levels, Claude Code runs the **personal**
(user-level) one — personal beats project. Give team skills distinct names.

### Plugin-distributed

If you are shipping the skill inside a Claude Code plugin, put it under the
plugin's `skills/` directory. It is invoked as `/plugin-name:my-skill` (the bare
`/my-skill` also works when nothing else claims the name).

### claude.ai and the Skills API

You can upload the same folder to claude.ai or the Skills API, but those paths
accept only the six spec fields (`name`, `description`, `license`,
`compatibility`, `metadata`, `allowed-tools`) and fail with a hard error on
anything else. Remove the Claude Code-only keys in this template
(`disable-model-invocation`, `argument-hint`, `arguments`) before uploading.

### Verifying it loaded

Skill directories are watched, so a skill you add appears in the current
session (run `/reload-skills` if you created the top-level `skills/` folder
mid-session). Type `/skills` and look for it. If it isn't there:

1. Check the file is named `SKILL.md` and sits in its own folder.
2. Confirm the directory name matches the `name` field, and that the name has
   no invisible or direction-changing characters.
3. Run `claude --debug` and search the log at `~/.claude/debug/` for errors.

---

## Conventions Worth Knowing

These aren't enforced by the runtime; they are conventions that make skills
play well with each other.

1. **One skill, one verb.** A skill that does three unrelated things should be
   three skills.
2. **Outputs are explicit.** The skill body should describe what the user
   *gets* — a list of created files, a status report, a structured object —
   not just side effects.
3. **Declare external dependencies.** If the skill needs Slack or a CLI, say
   so in `compatibility` and in the body's Prerequisites, and fail fast when
   it's missing. A skill that secretly posts to Slack surprises everyone the
   first time someone runs it in a sandboxed CI.
4. **Composable, not chained.** Prefer letting the calling agent compose
   skills in its plan over having one skill invoke another. Skill-calls-skill
   compounds context cost and is hard to test independently.
5. **Idempotent where possible.** Running the skill twice on the same inputs
   should produce the same outputs (or refuse with a clear error). Surprising
   side effects from re-runs erode trust.
6. **Fail fast and loud.** If a required tool or input is missing, error out
   with a one-line message and stop. Don't try to recover heuristically.

---

## Anti-Patterns

Common ways skills are written badly. Avoid all of these.

- **Anti-pattern 1: Tutorial-style body.** The skill body should be
  imperative instructions to the model, not prose explaining the topic. Skip
  the history of NestJS; describe the steps.
- **Anti-pattern 2: Untriggered general advice.** "When the user asks
  anything about authentication, suggest using JWT." Too broad. The skill
  fires constantly and degrades trust.
- **Anti-pattern 3: Hidden dependencies.** Skill body says "now run the
  formatter," requiring Prettier to be installed. Note it in `compatibility`
  and check for it in the helper script.
- **Anti-pattern 4: Skill that wraps a single tool call.** If your skill is
  "call `gh_create_pr` with these defaults," that's not a skill, it's an
  alias. Add real logic — composition, validation, branching — or don't ship
  the skill.
- **Anti-pattern 5: Skipping the example block.** The `## Example` section in
  `SKILL.md` isn't parsed specially, but the model imitates examples closely.
  Without one, output format drifts between invocations.
- **Anti-pattern 6: Treating `allowed-tools` as a sandbox.** It pre-approves
  the listed tools. Listing bare `Bash` lets any shell command run unprompted
  during the invoking turn.
- **Anti-pattern 7: Inventing frontmatter keys.** `version`, `triggers`,
  `requires`, `tags` at the top level do nothing in Claude Code and break
  claude.ai uploads. Use `metadata`.

---

## Versioning

Bump `metadata.version` in the frontmatter (a quoted string) on any change that
downstream callers can observe. Use semver:

| Change | Bump |
|---|---|
| Wording, internal refactor | patch (`0.1.0` → `0.1.1`) |
| New optional input, new output file | minor (`0.1.x` → `0.2.0`) |
| Renamed input, removed output, reordered steps, changed exit codes | major (`0.x.y` → `1.0.0`) |

Skills with no callers (it's all just one team) can be looser; skills shared
across teams should be strict.

---

## Related Resources

- [`templates/AGENTS.md`](../AGENTS.md) — multi-agent configuration template.
- [`templates/CLAUDE.md`](../CLAUDE.md) — project-level configuration template.
- [`examples/code-review/AGENTS.md`](../../examples/code-review/AGENTS.md) —
  example of agents that invoke skills.
- [`skill-creator`](https://github.com/anthropics/skills) — Anthropic's
  meta-skill that scaffolds new skills and runs evals on them.
- [Agent Skills specification](https://agentskills.io/specification).
- [Claude Code skills docs](https://code.claude.com/docs/en/skills).

---

## Maintenance

This template is itself versioned. If you copy it and the upstream template
changes, you may want to merge the changes in. Tracked changes worth knowing
about:

- `0.1.0` (2026-05-24): initial template — single helper script, three sections.
- `0.2.0` (2026-10-21): frontmatter rebuilt on the Agent Skills spec; removed
  non-standard keys (`invokable`, `triggers`, `requires`, `tags`,
  `last_updated`, top-level `version`); corrected `allowed-tools` semantics;
  added `${CLAUDE_SKILL_DIR}` and argument placeholders.

---

**Template version**: 0.2.0
**Last updated**: 2026-10-21
