# Creating Skills: Step by Step

A practical guide to writing skills that actually work. Covers layout, frontmatter, body structure, bundled assets, testing, iteration, publishing, and versioning.

This document is operational. By the end, you'll have shipped a working skill or have a clear understanding of why your draft isn't working.

Last verified: 2026-10 (against the [Agent Skills specification](https://agentskills.io/specification) and [Claude Code skills docs](https://code.claude.com/docs/en/skills)).

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
- **`templates/`** holds file templates the skill copies and customizes. (The spec's own convention for static resources is `assets/`.)
- **`scripts/`** holds runnable helpers. The skill body invokes them.
- **`examples/`** holds worked input/output pairs. Optional but valuable.

There's no enforcement of these names. The spec recommends `scripts/`, `references/`, and `assets/`; the rest are conventions that make skill folders easier to navigate. Keep references one level deep from `SKILL.md`.

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
compatibility: Needs the matching audit CLI (npm, pip-audit, or govulncheck) on PATH
allowed-tools: Read Bash(npm audit *) Bash(pip-audit *) Bash(govulncheck *)
metadata:
  version: "1.0.0"
  category: security
  tags: "audit, security, dependencies"
  owner: platform-team
---
```

**Required (spec):**

- `name` — lowercase letters, digits, and single hyphens; 1–64 characters; no leading/trailing hyphen; **must match the folder name**. Verb-noun reads best.
- `description` — what + when, as discussed in the guide; 1–1,024 characters.

**Optional (spec):**

- `allowed-tools` — a **top-level** field (nested under `metadata:` it is inert). It **pre-approves** the listed tools; it does not restrict anything. See [Section 6](#6-the-allowed-tools-decision).
- `compatibility` — environment requirements, ≤500 characters.
- `license` — a license name or bundled license file.
- `metadata` — a map of string keys to **string** values; the home for `version`, `category`, tags, owner, and anything else you track.

**Optional (Claude Code extensions):** `disable-model-invocation`, `user-invocable`, `when_to_use`, `argument-hint`, `arguments`, `paths`, `context`, `agent`, `background`, `model`, `effort`, `hooks`, `disallowed-tools`, `shell`. These are ignored or rejected by other clients.

**Don't** invent top-level fields (`version`, `requires`, `inputs`, `tags`, `triggers`). Claude Code silently ignores them, so they do nothing; claude.ai uploads and the Skills API reject the whole skill with `Unexpected key(s) in SKILL.md frontmatter`.

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

Helper programs. Run by the model via Bash. In Claude Code, reference them as `${CLAUDE_SKILL_DIR}/scripts/<name>` so the path resolves to the skill's own folder whatever the working directory is — and so a matching `allowed-tools` rule can pre-approve exactly that script.

```
my-skill/
└── scripts/
    ├── parse_npm_audit.py
    ├── parse_pip_audit.py
    └── verify_no_high_severity.sh
```

In the body:

```markdown
4. Parse the audit output with `python3 ${CLAUDE_SKILL_DIR}/scripts/parse_npm_audit.py`
   and store the result.
```

```yaml
allowed-tools: Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/parse_npm_audit.py *)
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

`allowed-tools` is a **pre-approval list**, not a sandbox. Per the spec it names "tools that are pre-approved to run"; in Claude Code, the listed tools run **without a permission prompt** during the turn that invokes the skill, while every unlisted tool remains available under your normal permission rules. An earlier version of this guide described the field as a restriction — that was wrong, and the difference is security-relevant: adding a tool here *removes* a human checkpoint.

### 6.1 Start with nothing

Begin with **no** `allowed-tools`. The skill still works; you just approve tool calls as they come (or your permission mode handles them). Add an entry only when a specific, low-risk call is annoying to approve every time — and make it as narrow as the pattern syntax allows:

```yaml
# Good: exactly the commands the procedure runs
allowed-tools: Read Bash(npm audit --json) Bash(${CLAUDE_SKILL_DIR}/scripts/verify.sh *)

# Dangerous: pre-approves any shell command, any file write
allowed-tools: Bash Write
```

### 6.2 Restricting is a different field

To keep a skill from using a tool at all, Claude Code has `disallowed-tools` (removed from the pool while the skill is active). For hard guarantees across every skill and prompt, use permission **deny** rules or a `PreToolUse` hook. Organizations can make Claude Code ignore skills' `allowed-tools` entirely with the managed `allowManagedPermissionRulesOnly` setting.

### 6.3 Why each tool is a risk to pre-approve

| Tool | Risk |
|------|------|
| `Read` | Information disclosure (if combined with WebFetch / Bash) |
| `Write`, `Edit` | Data destruction |
| `Bash` | Code execution; broadest blast radius |
| `WebFetch`, `WebSearch` | Exfiltration channel; supply chain |
| MCP server tools | Whatever that server can do |

For each tool you add to `allowed-tools`, ask: "If this skill were prompt-injected, what's the worst it could do without anyone being asked?" If the answer is "anything," scope the pattern more narrowly or leave the tool off the list so a human sees each call.

Note for reviewers: in Claude Code, a repository skill's `allowed-tools` applies even in a `claude -p` run in a folder you've never trusted. Review checked-in skills like you'd review CI scripts.

### 6.4 Composing with hooks

Hooks gate tool calls regardless of skill metadata. A `PreToolUse` hook that blocks `Write` to certain paths catches mistakes the skill author didn't anticipate. Claude Code skills can also declare their own `hooks` in frontmatter, active from invocation until the session ends — the right place for a rule that must hold every time the skill runs.

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

When you iterate, keep a small set of "this should work" cases and re-test on every change. Manual is fine for small skill libraries; automate when the count exceeds ~10. Tools that exist for this:

- Anthropic's **`skill-creator`** skill (in [anthropics/skills](https://github.com/anthropics/skills) and the official plugin marketplace) drafts skills and runs evals on them.
- For skills shipped in a Claude Code plugin, **`claude plugin eval`** (v2.1.269+) runs a suite of cases, scores them, and by default reruns each case *without* the plugin so you see what the skill contributes. A `tool_used: Skill` grader measures triggering.
- `claude plugin validate .claude/skills` catches `SKILL.md` frontmatter that doesn't parse; the spec's `skills-ref validate ./my-skill` checks naming and field rules.

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
├── .claude-plugin/
│   └── plugin.json              # plugin manifest (optional)
├── README.md                    # docs for installers
├── skills/
│   ├── audit-dependencies/
│   │   └── SKILL.md
│   ├── generate-typeguards/
│   │   └── SKILL.md
│   └── ...
├── agents/                      # optional bundled agents
└── hooks/                       # optional bundled hooks
```

The manifest at `.claude-plugin/plugin.json` declares the plugin's identity; it's optional (without it, the name comes from the marketplace entry or directory), and `name` is its only required key. The `skills/`, `agents/`, and `hooks/` directories sit at the plugin root (not inside `.claude-plugin/`) and are **auto-discovered** — you don't enumerate skills in the manifest. Plugin skills are invoked as `/<plugin-name>:<skill-name>`. Run `claude plugin validate` before publishing.

### 9.2 Manifest

```json
{
  "name": "platform-team-toolkit",
  "version": "2.4.1",
  "description": "Internal platform team's standard set of skills.",
  "author": {
    "name": "Platform Team",
    "email": "platform-team@company.com"
  },
  "license": "MIT"
}
```

### 9.3 Distribution

Plugins are distributed via marketplaces — a marketplace is just a repo with a marketplace manifest listing plugins. Options, from simplest to most controlled:

- **Public marketplace repo.** Users run `/plugin marketplace add org/marketplace-repo` (GitHub `owner/repo`, any git URL, or a local path; append `#ref` to pin a branch or tag), then `/plugin install platform-team-toolkit@marketplace-name`. Anthropic's official marketplace (`claude-plugins-official`) is added automatically the first time you start an interactive session.
- **Private / internal marketplace.** Same mechanism on a private repo. Controlled access, internal versioning. Marketplaces can also serve plugins as zip archives with an optional SHA-256 pin, and orgs can allowlist marketplaces through managed settings.
- **Single skill, no plugin.** The skill folder itself is portable across tools that implement the Agent Skills standard; Claude Code users can also enable skills on their claude.ai account to use them in cloud sessions.

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

Record the version where tools can read it: `metadata.version` in `SKILL.md` (a string, per the spec) and/or the plugin's `version` in `plugin.json`. Semantic versioning works:

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
- **`allowed-tools` treated as a restriction.** It pre-approves; bare `Bash` or `Write` in it removes the human checkpoint. Audit failure.
- **Invented top-level fields** (`version`, `requires`, `triggers`). Ignored by Claude Code, rejected by claude.ai uploads.
- **`name` doesn't match the folder.** Violates the spec; confusing in Claude Code, where `name` sets the command.
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
allowed-tools: Read Bash(npm audit --json) Bash(pnpm audit --json) Bash(govulncheck -json *)
disallowed-tools: Edit Write
metadata:
  version: "1.0.0"
  category: security
---
```

The audit commands are pre-approved because they're read-only and run on every invocation; anything else (e.g. `pip-audit` piped through `poetry export`) still prompts. `disallowed-tools` (a Claude Code extension) removes `Edit` and `Write` while the skill is active — this skill reports, it doesn't modify code. Upgrades happen in a separate workflow.

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
- [ ] Frontmatter has `name` (matching the folder) and `description`; any version/owner data is under `metadata`.
- [ ] `allowed-tools`, if present, is top-level and lists only narrow pre-approvals.
- [ ] Description includes what, when, and when-not (if relevant).
- [ ] Body has Procedure with numbered concrete steps.
- [ ] Body has Verification section.
- [ ] Body has Anti-Patterns section if relevant.
- [ ] Side-effecting skills set `disable-model-invocation: true` (Claude Code).
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

- [Agent Skills specification](https://agentskills.io/specification), [best practices](https://agentskills.io/skill-creation/best-practices), and [using scripts in skills](https://agentskills.io/skill-creation/using-scripts).
- [Claude Code: Extend Claude with skills](https://code.claude.com/docs/en/skills).
- [Claude Code: Create plugins](https://code.claude.com/docs/en/plugins/create) and [Test plugins with evals](https://code.claude.com/docs/en/plugin-evals).

---

**Status:** A skill is shipped when it's tested, documented, and reviewed. "Works on my machine" is not shipped.
