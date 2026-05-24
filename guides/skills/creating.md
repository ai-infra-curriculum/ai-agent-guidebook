# Creating Skills: Step by Step

A practical guide to writing skills that actually work. Covers layout, frontmatter, body structure, bundled assets, testing, iteration, publishing, and versioning.

This document is operational. By the end, you'll have shipped a working skill or have a clear understanding of why your draft isn't working.

---

## 1. Before You Write

Three questions to answer before opening a text editor.

### 1.1 Does this need to be a skill?

Re-read [guide.md](guide.md) Section 7 if needed. If the task is one-shot, just do it. If it's a substantial workload deserving its own context, build a sub-agent. If it's "I want to invoke this exact workflow by name," yes, write a skill.

### 1.2 What's the smallest useful version?

Resist the temptation to design the full feature-rich skill. Write the smallest version that does one thing well. Add affordances later when you've used the skill enough to know what's missing.

### 1.3 Who's the intended user?

- Yourself? Personal scope; minimal documentation; loose anti-pattern callouts.
- Your team? Project scope; documented in the team's skill catalog; review required.
- The public? Plugin scope; versioned; full edge-case handling; published changelog.

The audience determines the level of polish required.

---

## 2. Anatomy of the Skill Folder

Minimal layout:

```
my-skill/
└── SKILL.md
```

Real layout for anything non-trivial:

```
my-skill/
├── SKILL.md
├── references/
│   ├── concepts.md
│   ├── common-failures.md
│   └── checklist.md
├── templates/
│   ├── default.tmpl
│   └── variant-a.tmpl
├── scripts/
│   ├── verify.sh
│   └── helper.py
└── examples/
    ├── input-1.md
    └── output-1.md
```

Conventions:

- **`SKILL.md`** is the entry point. Required.
- **`references/`** holds Markdown the body refers to. Loaded on demand.
- **`templates/`** holds file templates the skill copies and customizes.
- **`scripts/`** holds runnable helpers. The skill body invokes them.
- **`examples/`** holds worked input/output pairs. Optional but valuable.

There's no enforcement of these names. They're just conventions that make skill folders easier to navigate.

---

## 3. Writing the SKILL.md

Three parts: frontmatter, description, body. Each has its own discipline.

### 3.1 Frontmatter

YAML at the top, between `---` markers.

```yaml
---
name: audit-dependencies
description: |
  Use this skill when the user wants to audit dependencies for a Node.js,
  Python, or Go project. Triggers: user mentions `npm audit`, `pip-audit`,
  `govulncheck`, "check vulnerabilities", or modifies a dependency lockfile.
  Skip for projects that don't have a lockfile.
version: 1.0.0
metadata:
  allowed-tools:
    - Read
    - Bash
    - Grep
    - Edit
  category: security
  tags: [audit, security, dependencies, npm, pip, go]
  author: platform-team
---
```

**Required:**

- `name` — verb-noun, lowercase, hyphenated.
- `description` — what + when, as discussed in the guide.

**Strongly recommended:**

- `metadata.allowed-tools` — narrow as possible.
- `version` — semver; bump on behavior changes.
- `category` and `tags` — for discoverability.

**Optional:**

- `author`, `requires`, `inputs`, custom fields the client supports.

### 3.2 Writing the description

The description is the routing logic. Spend disproportionate effort here.

**Structure that works:**

1. **What.** "Use this skill when..."
2. **Triggers.** Specific phrases, file types, commands, code patterns that should trigger the skill.
3. **Anti-triggers.** "Skip when..." — situations that look similar but aren't.

**Example evolution.**

Draft 1 (bad):

> Helps with vulnerability scanning.

Draft 2 (better):

> Use this skill to scan project dependencies for known vulnerabilities.

Draft 3 (production-quality):

> Use this skill when the user wants to audit dependencies for a Node.js, Python, or Go project. Triggers: user mentions `npm audit`, `pip-audit`, `govulncheck`, "check vulnerabilities", or modifies a dependency lockfile. Skip for projects that don't have a lockfile, and skip if the user is doing greenfield setup before any dependencies exist.

The third draft is the difference between a skill that auto-loads correctly and one that doesn't.

### 3.3 Body structure

A body that works has these sections, roughly in this order:

```markdown
# Skill Name

One-line restatement of purpose for the model reading this.

## When to Use

A paragraph that mirrors and expands the frontmatter description.

## Prerequisites

What must be true before this skill runs. Check at start.

## Procedure

Numbered steps. Concrete. Actionable.

## Verification

How to confirm the work succeeded.

## References

Pointers to bundled files for deeper material.

## Anti-Patterns

What not to do. Common failure modes to avoid.
```

Not every skill needs every section. Recipe skills lean heavily on Procedure. Reference skills lean on References. Onboarding skills lean on Prerequisites. But the shape is consistent enough that following it produces predictable skills.

---

## 4. Writing the Procedure

The procedure is the skill's executable logic. Write it as if someone (the model) is going to execute it literally.

### 4.1 Numbered steps

Not bullets. Numbered. Order matters.

```markdown
1. Read the project's package manifest (`package.json`, `pyproject.toml`, `go.mod`).
2. Identify the package manager in use.
3. Run the appropriate audit command (see References for command-per-manager).
4. Parse the output into the structured format described in `references/output-schema.md`.
5. Group findings by severity.
6. For each `critical` or `high` finding, propose a remediation:
   a. Read the offending dependency's release notes.
   b. Identify the minimum-version that fixes the issue.
   c. Check the project for incompatibilities (breaking changes).
   d. Draft an upgrade command.
7. Generate a summary report.
```

### 4.2 Branching

When the procedure branches, make the branch explicit:

```markdown
3. Identify the package manager:
   - If `package-lock.json` exists, use npm.
   - If `yarn.lock` exists, use yarn.
   - If `pnpm-lock.yaml` exists, use pnpm.
   - If none of the above, ask the user; do not guess.
```

### 4.3 Tool calls

When a step requires a specific tool call, be specific:

```markdown
4. Run `npm audit --json` and capture the output.
```

Not:

```markdown
4. Audit dependencies.
```

The first version tells the model exactly what to do. The second invites improvisation.

### 4.4 Stopping conditions

If a step might require stopping (insufficient info, conflicting signals, user input needed), say so:

```markdown
6. If the upgrade requires a major version bump for more than 3 dependencies,
   stop and present the upgrade plan to the user for confirmation before
   proceeding. Do not auto-upgrade across major versions silently.
```

### 4.5 Use the model's strengths

The procedure should call on the model for what it's good at: reading, summarizing, identifying patterns, generating structured output. Don't write a procedure that asks the model to count things precisely or perform arithmetic at scale — write one that asks the model to invoke a script that does those things.

---

## 5. Bundling Supporting Files

The body shouldn't contain everything. Push detail to bundled files.

### 5.1 References

Markdown files the body points to. Loaded on demand.

```
my-skill/
└── references/
    ├── npm-vulnerability-categories.md
    ├── python-cve-formats.md
    └── upgrade-strategy.md
```

In the body:

```markdown
4. For each finding, classify using the categories in `references/npm-vulnerability-categories.md`.
```

This keeps the body small while making detailed reference material available.

### 5.2 Templates

Files the skill copies and customizes. Useful when generating boilerplate.

```
my-skill/
└── templates/
    ├── audit-report.md.tmpl
    └── pr-description.md.tmpl
```

In the body:

```markdown
7. Generate a summary report by copying `templates/audit-report.md.tmpl`
   and filling in the placeholders (`{{ project_name }}`, `{{ findings }}`).
```

### 5.3 Scripts

Helper programs. Run by the model via Bash.

```
my-skill/
└── scripts/
    ├── parse_npm_audit.py
    ├── parse_pip_audit.py
    └── verify_no_high_severity.sh
```

In the body:

```markdown
4. Parse the audit output using `scripts/parse_npm_audit.py` and store the result.
```

Scripts should be:

- **Standalone.** No assumed environment beyond what the host has.
- **Documented.** Header comment with usage.
- **Idempotent.** Safe to re-run.
- **Exit-coded.** 0 for success, non-zero for failure, with stderr explaining.

### 5.4 Examples

Worked input/output pairs. The model learns from them.

```
my-skill/
└── examples/
    ├── input-1-small-npm-project.md
    ├── output-1-small-npm-project.md
    ├── input-2-large-monorepo.md
    └── output-2-large-monorepo.md
```

In the body:

```markdown
See `examples/` for worked input/output pairs. Mimic the structure of the
example output when generating yours.
```

Examples are particularly powerful for output formatting consistency.

---

## 6. The `allowed-tools` Decision

Every skill should set `metadata.allowed-tools`. This is defense-in-depth, not red tape.

### 6.1 Start narrow

Begin with the absolute minimum:

```yaml
allowed-tools:
  - Read
```

Add tools only when the procedure provably needs them.

### 6.2 Why each tool is a risk

| Tool | Risk |
|------|------|
| `Read` | Information disclosure (if combined with WebFetch / Bash) |
| `Write`, `Edit` | Data destruction |
| `Bash` | Code execution; broadest blast radius |
| `WebFetch`, `WebSearch` | Exfiltration channel; supply chain |
| MCP server tools | Whatever that server can do |

For each tool you add to `allowed-tools`, ask: "If this skill were prompt-injected, what's the worst it could do?" If the answer is "anything," scope the tool more narrowly or push the dangerous step out of this skill into a more careful one.

### 6.3 Composing with hooks

Some clients support hooks that gate tool calls regardless of skill metadata. A PreToolUse hook that blocks `Write` to certain paths catches mistakes the skill author didn't anticipate. Hooks and `allowed-tools` are complementary layers.

---

## 7. Testing a Skill

A skill that hasn't been tested isn't a skill, it's a wish.

### 7.1 Functional test: does it work?

Invoke the skill explicitly on a representative task. Walk through the output.

- Does it complete?
- Is the output correct?
- Did it follow the procedure or wander?

If the model wanders, the procedure isn't specific enough. If it follows the procedure but produces wrong output, the procedure or references are wrong.

### 7.2 Loading test: does it auto-load when it should?

Open a fresh conversation. Use phrases the description claims should trigger the skill. Verify the skill loads.

If it doesn't, the description isn't specific enough.

### 7.3 Negative test: does it stay quiet when it shouldn't?

Open a fresh conversation. Use phrases that are tangentially related but shouldn't trigger the skill. Verify the skill stays quiet.

If it loads when it shouldn't, the description is too broad. Add anti-triggers.

### 7.4 Cross-environment test

If the skill is project- or plugin-scoped, test it in someone else's environment. The most common breakage: assumed file paths, assumed tools, assumed shell.

### 7.5 Regression test

When you iterate, keep a small set of "this should work" cases and re-test on every change. Manual is fine for small skill libraries; automate when the count exceeds ~10.

---

## 8. Iterating on the Description

The description is where most skills die. A typical iteration cycle:

1. Write a description.
2. Test loading on 5 representative requests that *should* trigger.
3. Test loading on 5 requests that *shouldn't*.
4. Count false positives and false negatives.
5. Adjust the description (add triggers for FNs; add anti-triggers for FPs).
6. Repeat until both rates are acceptable.

This is the "most common bug" in new skills. Treat description iteration as a real engineering activity, not an afterthought.

### 8.1 Concrete triggers

Triggers in the description should be specific phrases or signals, not abstract concepts.

Weak: "Use when working with databases."
Strong: "Use when the user runs migrations (`alembic upgrade`, `prisma migrate deploy`, `bin/rails db:migrate`), creates a new migration file, or modifies a `schema.sql`/`schema.prisma`/`models.py` file."

### 8.2 Concrete anti-triggers

Anti-triggers prevent over-loading.

Weak: "Don't use for non-database tasks."
Strong: "Skip for read-only database work (selects, queries, reports). Skip for ORM model usage that doesn't change schema. Skip for documentation about database design."

---

## 9. Publishing as Part of a Plugin

When a skill outgrows its initial scope.

### 9.1 Plugin layout

```
my-plugin/
├── plugin.json                  # plugin manifest
├── README.md                    # docs for installers
├── skills/
│   ├── audit-dependencies/
│   │   └── SKILL.md
│   ├── generate-typeguards/
│   │   └── SKILL.md
│   └── ...
├── agents/                      # optional bundled agents
├── hooks/                       # optional bundled hooks
└── mcp/                         # optional MCP server configs
```

The plugin manifest declares what the plugin contains; the client loader registers everything in it.

### 9.2 Manifest

```json
{
  "name": "platform-team-toolkit",
  "version": "2.4.1",
  "description": "Internal platform team's standard set of skills.",
  "author": "platform-team@company.com",
  "license": "MIT",
  "skills": [
    "skills/audit-dependencies",
    "skills/generate-typeguards"
  ],
  "compatibility": {
    "min-client-version": "1.4.0"
  }
}
```

### 9.3 Distribution

Options, from simplest to most controlled:

- **Direct install from Git.** Users `claude plugin install git@github.com:org/plugin.git`. Cheapest.
- **Public plugin registry.** Anthropic's or community-run. Discoverable; users can search.
- **Private registry.** For internal teams. Controlled access, internal versioning.

### 9.4 Documentation for installers

A plugin README should cover:

- What the plugin does at a glance.
- Required client version.
- Required external tools (the skills assume `npm` exists, etc.).
- Skill inventory with one-line descriptions.
- Configuration knobs.
- Support / issue tracker.

---

## 10. Versioning

Semantic versioning works:

- **Patch.** Bug fixes; no behavior change; no description change.
- **Minor.** Additive features; new optional behaviors; backward-compatible.
- **Major.** Breaking changes; behavior different in ways users will notice.

### 10.1 What's "breaking" for a skill?

- Description triggers change such that auto-load behavior shifts.
- Procedure changes such that output format differs.
- `allowed-tools` widens (a risk users opted out of before).
- Required external tools or files change.

### 10.2 Changelog

Maintain `CHANGELOG.md` in the skill or plugin. Don't make users diff the body to figure out what changed.

```markdown
# Changelog

## 2.0.0 — 2026-05-23

### Breaking
- Output format changed from Markdown table to structured JSON. Update consumers.

### Added
- Support for `pnpm-lock.yaml`.

## 1.3.0 — 2026-04-12
...
```

### 10.3 Deprecation

If you must remove a skill or change a name:

1. Add a deprecation notice to the description and body.
2. Keep the deprecated version available for at least one minor release cycle.
3. Document the migration path.
4. Then remove.

Skipping the deprecation step breaks workflows for users you didn't know existed.

---

## 11. Common First-Skill Mistakes

A list to scan against your draft.

- **Description is vague.** Already covered, still worth repeating.
- **Body is exposition, not procedure.** Reads like a wiki, doesn't execute.
- **No verification step.** Skill might have succeeded; might not have.
- **`allowed-tools` is missing or set to "all".** Audit failure.
- **Skill assumes the wrong environment.** Hardcoded paths, missing tools.
- **Skill tries to be general-purpose.** Loaded too often, gives bad answers.
- **No examples.** Model doesn't know what good output looks like.
- **Body is too long.** Push detail to `references/`.
- **No tests.** "It worked when I tried it once" is not a test plan.

---

## 12. A Worked Example: Building `/audit-dependencies` From Scratch

A 30-minute build, documented end to end.

### Step 1: One-line purpose

> Audit a project's dependencies for known vulnerabilities and propose remediations.

### Step 2: Identify the procedure

What would a careful engineer do?

1. Detect package manager.
2. Run audit.
3. Parse output.
4. Classify findings.
5. Propose fixes.
6. Report.

### Step 3: Draft the body

```markdown
# Audit Dependencies

## When to Use
... (see description)

## Procedure
1. Detect package manager by checking for lockfiles: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Pipfile.lock`, `poetry.lock`, `requirements.txt`, `go.sum`.
2. Run the matching audit tool:
   - npm: `npm audit --json`
   - yarn: `yarn npm audit --json` (Yarn 3+) or `yarn audit --json` (Yarn 1)
   - pnpm: `pnpm audit --json`
   - pipenv: `pipenv check --output json`
   - poetry: `poetry export -f requirements.txt | pip-audit -r /dev/stdin --format json`
   - go: `govulncheck -json ./...`
3. Parse the output into a structured findings list (see `references/output-schema.md`).
4. For each `critical` or `high` finding:
   a. Identify the affected package and version.
   b. Check the package's release notes for the fix version.
   c. Determine if the fix is a patch, minor, or major bump.
5. Generate a remediation plan, grouped by required risk:
   - Patch upgrades (safe): can be applied immediately.
   - Minor upgrades (low risk): apply unless config indicates concern.
   - Major upgrades (review): require user confirmation.
6. Output a Markdown report following `templates/audit-report.md.tmpl`.

## Verification
After completing the report:
1. Verify each `critical` and `high` finding appears in the report.
2. Verify each remediation suggestion includes the target version and rationale.

## References
- `references/output-schema.md`
- `references/cve-severity-guide.md`

## Anti-Patterns
- Do not auto-apply major-version upgrades without explicit user approval.
- Do not silently dismiss `low` or `moderate` findings — list them, even if not flagged for action.
- Do not run `npm audit fix --force` automatically.
```

### Step 4: Bundle assets

Create `references/output-schema.md` with the expected structured format. Create `templates/audit-report.md.tmpl` with the report shape.

### Step 5: Write frontmatter

```yaml
---
name: audit-dependencies
description: |
  Use this skill when the user wants to audit project dependencies for known
  vulnerabilities. Triggers: user mentions `npm audit`, `pip-audit`,
  `govulncheck`, "check vulnerabilities", "security scan dependencies", or
  modifies a dependency lockfile in a way that needs validation. Skip for
  greenfield projects without dependencies installed yet.
version: 1.0.0
metadata:
  allowed-tools:
    - Read
    - Bash
    - Grep
  category: security
  tags: [audit, security, dependencies, npm, pip, go, yarn, pnpm]
---
```

Note `Edit` is *not* in `allowed-tools` — this skill reports, it doesn't modify code. Upgrades happen in a separate workflow.

### Step 6: Test

- Functional: invoke on a representative repo. Confirm output is correct.
- Loading: open fresh conversation, mention `npm audit`. Verify loads.
- Negative: open fresh conversation, ask a general programming question. Verify doesn't load.

### Step 7: Iterate

Use the skill for a week. Note where it fell short. Adjust.

---

## 13. Skill Maintenance

Skills decay. Codebases change, tools change, the model changes. A skill written 12 months ago may not be accurate today.

### 13.1 Review schedule

Project skills: review quarterly during regular tech-debt sweeps.
Plugin skills: review on every minor release.

### 13.2 Health signals

A skill is healthy when:

- It's invoked regularly (manually or auto).
- Outputs are still accurate.
- No issues filed against it in the last release cycle.

A skill is unhealthy when:

- Nobody's used it in 6 months.
- It produces stale-looking output.
- The procedure references files or tools that no longer exist.

Unhealthy skills should be updated or removed. Stale skills mislead.

---

## 14. Creating Checklist

Before merging a new skill:

- [ ] Folder layout follows conventions (`SKILL.md` at root; assets in `references/`, `templates/`, `scripts/`, `examples/`).
- [ ] Frontmatter has `name`, `description`, `version`, `metadata.allowed-tools`.
- [ ] Description includes what, when, and when-not (if relevant).
- [ ] Body has Procedure with numbered concrete steps.
- [ ] Body has Verification section.
- [ ] Body has Anti-Patterns section if relevant.
- [ ] `allowed-tools` is narrow.
- [ ] Tested functionally on a representative case.
- [ ] Tested for correct auto-loading.
- [ ] Tested for not auto-loading on unrelated requests.
- [ ] Reviewed by someone other than the author.
- [ ] Added to the project / plugin's skill index.

---

## 15. Further Reading

- [Skills Guide](guide.md) — conceptual overview.
- [Skill Catalog](catalog.md) — examples and inspiration.
- [Basic Skill Template](templates/basic-skill/SKILL.md) — minimal scaffold.
- [Advanced Skill Template](templates/skill-with-script/SKILL.md) — with bundled scripts.

### External

- Claude Code documentation, Skills section.
- Plugin development docs for your target distribution channel.

---

**Status:** A skill is shipped when it's tested, documented, and reviewed. "Works on my machine" is not shipped.
