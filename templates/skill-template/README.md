# Skill Template

A complete starting scaffold for a Claude Skill. Copy this directory, rename
it, customize the three files, and you have a working skill.

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

When Claude Code (or another agent runtime that supports Skills) starts up, it
walks a skill search path — typically:

1. Project-level: `<repo>/.claude/skills/<skill-name>/SKILL.md`
2. User-level:    `~/.claude/skills/<skill-name>/SKILL.md`
3. Plugin-level:  installed-plugin paths (varies by plugin manager)

For each `SKILL.md` it finds, the runtime parses the YAML frontmatter for
metadata (`name`, `description`, `triggers`, `requires`, etc.) and reads the
Markdown body as the skill's instructions.

When the user types `/<name>` or the runtime auto-discovers a match via the
`triggers` list, the body of `SKILL.md` is loaded into context and the model
follows the steps inside.

The helper script in `scripts/` is just a regular file — the skill body
references it by relative path. Anything reachable via the filesystem MCP can
be invoked the same way.

---

## How To Customize

### Step 1: Copy and rename

```bash
cp -r templates/skill-template ~/.claude/skills/my-skill
# (or the project-local equivalent: cp -r ... .claude/skills/my-skill)
```

Rename the directory to match the `name` field in your `SKILL.md`. The runtime
matches them when resolving `/my-skill` invocations.

### Step 2: Edit SKILL.md

Open `SKILL.md` and replace, in order:

1. **Frontmatter**:
   - `name`: kebab-case identifier. Must match the directory name.
   - `description`: one sentence. ≤120 chars. Lead with a verb.
   - `triggers`: ≤5 phrases. Too many causes false positives.
   - `requires`: list MCP servers or external CLIs.
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
  use the filesystem MCP to apply them"). For those, delete `scripts/` and
  drop the references from `SKILL.md`.

Whatever shape the helper takes, keep its interface stable. The skill body
documents the helper's flags and exit codes; if you change them, update the
skill body in the same commit.

### Step 4: Verify

Two quick checks before declaring done:

```bash
# 1. The skill's helper script (if any) runs and respects --dry-run.
bash scripts/example.sh --dry-run --target /tmp --name Sample

# 2. The frontmatter parses as YAML.
python3 -c "import yaml,sys; print(list(yaml.safe_load_all(open('SKILL.md')))[0])"
```

If both succeed, the skill is loadable. The runtime will surface a clearer
error if anything else is wrong on first invocation.

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

Project-level takes precedence over user-level if names collide.

### Plugin-distributed

If you are shipping the skill inside a Claude Code plugin, put it under the
plugin's `skills/` directory. The plugin manager will surface it under the
plugin's namespace (`plugin-name:my-skill`).

### Verifying it loaded

After installation, start a fresh Claude Code session in the relevant project
and type `/help` (or your runtime's equivalent). Your skill should appear in
the list. If it doesn't:

1. Check the frontmatter parses (see Step 4 above).
2. Confirm the directory name matches the `name` field.
3. Look in the runtime's startup log for a parse error.

---

## Conventions Worth Knowing

These aren't enforced by the runtime; they are conventions that make skills
play well with each other.

1. **One skill, one verb.** A skill that does three unrelated things should be
   three skills.
2. **Outputs are explicit.** The skill body should describe what the user
   *gets* — a list of created files, a status report, a structured object —
   not just side effects.
3. **No I/O outside `requires`.** If the skill needs Slack, list `slack` in
   `requires`. A skill that secretly posts to Slack without declaring it
   surprises everyone the first time someone runs it in a sandboxed CI.
4. **Composable, not chained.** Don't have one skill invoke another. Let the
   calling agent compose them in its plan. Skill-calls-skill is hard to
   reason about and impossible to test independently.
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
  formatter," requiring Prettier to be installed. List it in `requires` or
  check for it in the helper script.
- **Anti-pattern 4: Skill that wraps a single tool call.** If your skill is
  "call `gh_create_pr` with these defaults," that's not a skill, it's an
  alias. Add real logic — composition, validation, branching — or don't ship
  the skill.
- **Anti-pattern 5: Skipping the example block.** The `## Example` section in
  `SKILL.md` is what the model uses to learn the skill's shape. Without it,
  the runtime invokes the skill with the wrong arguments roughly half the
  time.

---

## Versioning

Bump the `version` field in the frontmatter on any change that downstream
callers can observe. Use semver:

| Change | Bump |
|---|---|
| Wording, internal refactor | patch (`0.1.0` → `0.1.1`) |
| New optional input, new output file, new tag | minor (`0.1.x` → `0.2.0`) |
| Renamed input, removed output, reordered steps, changed exit codes | major (`0.x.y` → `1.0.0`) |

Skills with no callers (it's all just one team) can be looser; skills shared
across teams should be strict.

---

## Related Resources

- [`templates/AGENTS.md`](../AGENTS.md) — multi-agent configuration template.
- [`templates/CLAUDE.md`](../CLAUDE.md) — project-level configuration template.
- [`examples/code-review/AGENTS.md`](../../examples/code-review/AGENTS.md) —
  example of agents that invoke skills.
- [Skill creator skill](https://docs.anthropic.com/claude/skills) — meta-skill
  that scaffolds new skills for you.

---

## Maintenance

This template is itself versioned. If you copy it and the upstream template
changes, you may want to merge the changes in. Tracked changes worth knowing
about:

- `0.1.0` (2026-05-24): initial template — single helper script, three sections.

---

**Template version**: 0.1.0
**Last updated**: 2026-05-24
