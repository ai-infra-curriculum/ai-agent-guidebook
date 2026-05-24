# Curated Skill Catalog

A working list of skills worth writing (or adopting from public sources). Organized by category, with one paragraph per skill: what it does, when to invoke it, and a source pointer when one exists.

The bias of this catalog: skills that compound. A skill that saves 10 seconds occasionally isn't worth the maintenance. A skill that converts a one-hour task into a five-minute task — invoked weekly — pays its keep forever.

---

## How to Use This Catalog

For each skill below:

- If your team faces the recurring problem the skill addresses, adopt it.
- If a source repo is listed, install or fork from there.
- If no source is listed, write your own using the patterns in [creating.md](creating.md).

Skill names follow the `verb-noun` convention. Adapt names to your team's conventions if they differ.

---

## Category 1: Code Quality

Skills that make code review, refactoring, and testing faster and more consistent.

### 1.1 `code-review`

**Does:** Reads a diff (PR or local) and produces a structured review covering style, bugs, missing tests, security, and architecture concerns. Severity-tagged.

**Invoke when:** Before opening a PR; before requesting human review; when reviewing someone else's PR yourself.

**Source:** Common in `pr-review-toolkit` plugins; see Anthropic's example plugins.

---

### 1.2 `refactor-clean`

**Does:** Identifies code smells (long functions, deep nesting, duplicated logic, magic numbers) and proposes refactorings. Edits are presented as a plan before any changes are made.

**Invoke when:** A file or function feels gnarly; before adding new features to a legacy module.

**Source:** Often shipped as part of broader "codebase cleanup" plugins.

---

### 1.3 `test-generate`

**Does:** Reads a target file (or function), identifies its public surface, and generates unit tests covering happy paths, edge cases, and error paths. Uses the project's test framework conventions.

**Invoke when:** A function lacks test coverage; before refactoring an under-tested module.

**Source:** Multiple variants exist; framework-specific versions (Jest, pytest, JUnit) tend to outperform generic ones.

---

### 1.4 `tdd-cycle`

**Does:** Guides a strict red-green-refactor cycle. Writes the test first, runs it (expects failure), guides implementation, runs again (expects pass), then proposes refactoring.

**Invoke when:** Implementing a new feature where you want true TDD discipline.

**Source:** Available in the `tdd-workflows` plugin.

---

### 1.5 `find-bugs`

**Does:** Static analysis style review focused on bug detection — null-safety issues, off-by-one errors, race conditions, leaked resources. Produces a ranked list with explanations.

**Invoke when:** A module is producing weird behavior in production; before shipping a security-sensitive change.

**Source:** Bug-hunter style plugins.

---

### 1.6 `simplify`

**Does:** Reviews recently changed code and proposes simplifications: removing dead branches, replacing custom code with stdlib functions, collapsing redundant conditionals.

**Invoke when:** After getting a feature working but before merging; during a tech-debt pass.

---

## Category 2: Documentation

Skills that get documentation written and kept current.

### 2.1 `readme-generate`

**Does:** Reads a project's source and generates a README covering purpose, install, usage, configuration, and contribution sections. Adapts to the language ecosystem.

**Invoke when:** A new repo lacks documentation; a stale README needs a rewrite.

---

### 2.2 `codemap-generate`

**Does:** Produces a structured map of a codebase: top-level architecture, module purposes, key entry points, important interfaces. Output is a Markdown doc with a Mermaid diagram.

**Invoke when:** Onboarding to a new codebase; preparing a hand-off doc.

---

### 2.3 `doc-explain`

**Does:** Reads a file or function and generates inline documentation (docstrings, JSDoc, etc.) using the codebase's existing conventions.

**Invoke when:** Pre-merge, when adding docs to under-documented code.

---

### 2.4 `api-docs-generate`

**Does:** Reads API route definitions (FastAPI, Express, Rails routes, etc.) and produces OpenAPI / Swagger documentation with example requests and responses.

**Invoke when:** Building or updating a public API; preparing SDK generation.

---

### 2.5 `changelog-generate`

**Does:** Reads git history since the last release tag and produces a changelog grouped by type (feat/fix/refactor) following Conventional Commits.

**Invoke when:** Cutting a release.

---

### 2.6 `architecture-decision-record`

**Does:** Prompts the user for the decision context, options considered, and chosen approach. Produces a standard ADR document.

**Invoke when:** Making a substantial architectural decision worth documenting.

---

## Category 3: Workflow Automation

Skills that smooth the daily git / PR / commit cycle.

### 3.1 `commit`

**Does:** Reviews staged changes, drafts a Conventional Commits-style message, and creates the commit. Avoids amending; never commits sensitive files.

**Invoke when:** Done with a chunk of work and ready to commit.

**Source:** Ships in many commit-helper plugins.

---

### 3.2 `create-pr`

**Does:** Analyzes the branch's full diff against the base, drafts a PR title and description with summary and test plan, creates the PR via `gh`.

**Invoke when:** Branch is ready for review.

---

### 3.3 `address-github-comments`

**Does:** Fetches PR comments, groups them by file/topic, and proposes changes addressing each. User confirms each change before commit.

**Invoke when:** Returning to a PR with review comments.

---

### 3.4 `update-claude-md`

**Does:** Reviews the project for newly-introduced patterns (new directories, new tools, new conventions) and updates `CLAUDE.md` to keep agent context current.

**Invoke when:** Quarterly; after big restructurings.

---

### 3.5 `branch-from-issue`

**Does:** Reads an issue (GitHub, Linear, Jira), names a branch following the team's convention, switches to it, sets up tracking.

**Invoke when:** Starting work on a ticketed task.

---

### 3.6 `release`

**Does:** Runs the release sequence: version bump, changelog generation, tag creation, artifact build, publish. Each step confirmed before proceeding.

**Invoke when:** Cutting a release.

---

## Category 4: Data and Analytics

Skills that make ad-hoc data work faster.

### 4.1 `csv-explore`

**Does:** Reads a CSV (or JSONL, Parquet) and produces a profile: schema, row count, value distributions, null rates, suspicious outliers. No model assumptions — just shows you what's in the data.

**Invoke when:** Handed an unfamiliar data file; debugging a data quality issue.

---

### 4.2 `schema-diff`

**Does:** Compares two database schemas (or two ORM model files) and produces a structured diff with migration suggestions.

**Invoke when:** Reconciling schemas between environments; reviewing a schema change PR.

---

### 4.3 `sql-explain`

**Does:** Reads a SQL query, walks through what it does, identifies performance concerns, suggests indexes or rewrites.

**Invoke when:** Inheriting an unfamiliar query; debugging slow query performance.

---

### 4.4 `parse-and-summarize`

**Does:** Reads a log file, error dump, or large JSON output and produces a structured summary of the most relevant content.

**Invoke when:** Investigating a production incident; processing a verbose tool output.

---

## Category 5: DevOps and Infrastructure

Skills that handle the infrastructure-as-code workflows.

### 5.1 `k8s-manifest-generate`

**Does:** Generates Kubernetes manifests (Deployment, Service, Ingress, ConfigMap, Secret stub) from a high-level service description.

**Invoke when:** Standing up a new service; converting a legacy deployment to k8s.

---

### 5.2 `terraform-module-scaffold`

**Does:** Creates a new Terraform module folder with `main.tf`, `variables.tf`, `outputs.tf`, `README.md`, and example usage following the team's module conventions.

**Invoke when:** Adding a new reusable infrastructure module.

---

### 5.3 `dockerfile-optimize`

**Does:** Reads a Dockerfile and proposes optimizations: multi-stage builds, layer ordering for cache reuse, smaller base images, security improvements.

**Invoke when:** A Docker image is bigger or slower to build than it should be.

---

### 5.4 `gha-workflow-scaffold`

**Does:** Creates a GitHub Actions workflow for a common case (CI, release, scheduled job) following team conventions for caching, secrets, matrix builds.

**Invoke when:** Adding CI/CD to a new repo or job.

---

### 5.5 `helm-chart-scaffold`

**Does:** Creates a Helm chart skeleton with templates, values, and a basic README.

**Invoke when:** Packaging an application for Helm-based deployment.

---

### 5.6 `aws-cost-audit`

**Does:** Queries AWS cost data (via CLI or Cost Explorer API), highlights anomalies, identifies underutilized resources, suggests savings.

**Invoke when:** Monthly cost review; investigating a cost spike.

---

## Category 6: Language-Specific

Skills tailored to specific languages and frameworks.

### 6.1 `python-type-coverage`

**Does:** Runs `mypy` (or `pyright`) on the codebase, identifies untyped functions, and proposes type annotations file-by-file.

**Invoke when:** Improving type coverage in a Python codebase; preparing a strict-typing rollout.

---

### 6.2 `typescript-strict-migrate`

**Does:** Walks a TypeScript codebase from loose to strict mode incrementally. Identifies files that would break, proposes fixes per file, tracks progress.

**Invoke when:** Hardening type safety in an existing TS project.

---

### 6.3 `golang-test-table`

**Does:** Converts existing Go tests into idiomatic table-driven tests, adding missing cases for edge conditions.

**Invoke when:** Cleaning up Go test files; expanding test coverage.

---

### 6.4 `rust-error-refactor`

**Does:** Reviews Rust code for ad-hoc error handling, proposes consistent `thiserror`-based error enums per module, refactors call sites.

**Invoke when:** Standardizing error handling in a growing Rust codebase.

---

### 6.5 `react-component-extract`

**Does:** Reads a large React component, identifies extractable sub-components, proposes the extraction with prop interfaces.

**Invoke when:** A component file has grown too large; refactoring for reusability.

---

### 6.6 `django-security-review`

**Does:** Reviews a Django project for common security issues: missing CSRF, leaky views, ORM injection patterns, debug-mode-in-prod, weak password validators.

**Invoke when:** Pre-deployment security pass; quarterly hygiene check.

---

### 6.7 `swift-concurrency-migrate`

**Does:** Identifies legacy completion-handler-based Swift code and proposes async/await migrations preserving behavior.

**Invoke when:** Modernizing a Swift codebase to current concurrency patterns.

---

### 6.8 `kotlin-coroutines-review`

**Does:** Reviews Kotlin code for coroutine misuse: blocking calls in suspend functions, missing exception handling, structured concurrency violations.

**Invoke when:** Auditing a Kotlin codebase that uses coroutines.

---

## Category 7: Security

Skills focused on safety and compliance.

### 7.1 `security-review`

**Does:** Reviews a diff or module for OWASP-Top-10-style issues: auth bypass, SQL injection, XSS, IDOR, sensitive data leaks. Severity-tagged.

**Invoke when:** PR touches auth, payments, user data, or external inputs.

---

### 7.2 `audit-dependencies`

**Does:** Detects package manager, runs the appropriate audit tool, classifies findings, proposes remediations grouped by required risk.

**Invoke when:** Monthly; before releases; after a CVE alert.

(Worked example in [creating.md](creating.md) Section 12.)

---

### 7.3 `secrets-scan`

**Does:** Scans the repo (current state and history) for committed secrets — API keys, tokens, private keys. Recommends rotation when found.

**Invoke when:** Pre-merge of risky branches; after onboarding new contributors; after suspicious activity.

---

### 7.4 `csp-builder`

**Does:** Analyzes a web app's actual resource loading and produces a tight Content Security Policy. Iterates with the user as new sources are needed.

**Invoke when:** Adding CSP to a web app for the first time; tightening an existing policy.

---

### 7.5 `gdpr-data-handling`

**Does:** Reviews a codebase for personal-data handling: where PII enters, where it's stored, where it leaves, retention policies, deletion paths.

**Invoke when:** GDPR compliance pass; before processing EU user data.

---

## Category 8: AI / Agent Engineering

Meta-skills: skills for building things with AI.

### 8.1 `prompt-optimize`

**Does:** Reads an existing prompt, identifies common issues (vagueness, missing examples, conflicting instructions), proposes a revised version.

**Invoke when:** A prompt produces inconsistent output; before promoting a prompt to production.

---

### 8.2 `eval-harness-scaffold`

**Does:** Creates an evaluation harness for an LLM application: dataset format, scoring functions, runner script, results dashboard stub.

**Invoke when:** Standing up evals for a new AI feature.

---

### 8.3 `skill-create`

**Does:** Walks the user through creating a new skill following the conventions in [creating.md](creating.md). Generates the folder structure, frontmatter, and body skeleton.

**Invoke when:** Writing a new skill from scratch.

---

### 8.4 `mcp-server-scaffold`

**Does:** Creates an MCP server skeleton in the user's preferred language with sample tools, schemas, and a runnable entry point.

**Invoke when:** Building a new MCP integration.

---

### 8.5 `agent-design-review`

**Does:** Reviews a multi-agent system design against the patterns and anti-patterns in the agents-subagents guides. Produces a critique.

**Invoke when:** Before implementing a new multi-agent system; during architecture review.

---

## Category 9: Debugging and Diagnostics

Skills that accelerate incident response.

### 9.1 `error-trace`

**Does:** Reads an error message or stack trace, walks through the call sites, identifies the most likely root cause, proposes a fix.

**Invoke when:** Investigating an unfamiliar error.

---

### 9.2 `smart-debug`

**Does:** Guides a structured debug session: state the symptom, form a hypothesis, design a minimal test, run, observe, iterate.

**Invoke when:** Stuck on a bug after the obvious checks failed.

---

### 9.3 `incident-response`

**Does:** Walks the user through the incident-response playbook: capture state, assess scope, mitigate, communicate, document. Generates the postmortem skeleton.

**Invoke when:** During or after a production incident.

---

### 9.4 `performance-profile`

**Does:** Reads a profiling output (perf, py-spy, flame graphs) and produces a structured analysis: top consumers, suspicious patterns, optimization candidates.

**Invoke when:** A service is slow and you have a profile but need help reading it.

---

## Category 10: Onboarding and Knowledge

Skills that move knowledge from heads to invocable workflows.

### 10.1 `onboard-codebase`

**Does:** Walks a new contributor through the codebase: top-level structure, key modules, conventions, how to run, how to test, who to ask.

**Invoke when:** New hire's first week.

---

### 10.2 `runbook-from-incident`

**Does:** Reads an incident postmortem and produces a runbook for handling the same class of incident in the future.

**Invoke when:** After every meaningful incident.

---

### 10.3 `pair-programming-mode`

**Does:** Adopts a tighter, more conversational interaction style suited to real-time pair programming — smaller chunks, more confirmations, explanations alongside code.

**Invoke when:** Doing exploratory work where the user wants to stay in the loop on every move.

---

## Adopting Skills From Other Sources

This catalog draws on a few common types of source:

- **Anthropic-shipped skills.** Distributed with Claude Code. Browse with `/help`.
- **Plugin marketplaces.** Both Anthropic's and community-run. Searchable.
- **Open-source repos.** Many teams publish their internal skill collections; search GitHub for `claude-skills` or `.claude/skills`.
- **Your team's collection.** The skills you write yourself, in `.claude/skills/` and `~/.claude/skills/`.

When adopting a skill from outside:

- **Read the body.** Don't trust the description.
- **Check `allowed-tools`.** Is the scope appropriate?
- **Test in your environment.** Does it assume tools or paths you don't have?
- **Track the version.** If the upstream changes, you want to know.

---

## Skills Worth Writing First

If you're starting from scratch and want maximum return on the first three skills you write:

1. **`commit`** — invoked dozens of times per day. The improvement compounds.
2. **`code-review`** — every PR. Catches things before humans see them.
3. **A project-specific onboarding skill** — pays for itself the first time a new contributor uses it.

Build these three. Use them for a month. Then expand.

---

## Pruning the Catalog

A skill that nobody uses is overhead. Periodically:

- Remove skills that haven't been invoked in 6 months.
- Consolidate skills with overlapping descriptions.
- Promote skills that the team uses constantly into the plugin level.

The right size for a project's `.claude/skills/` folder is probably 10-30 entries. Smaller is fine. Bigger usually means duplication.

---

## Submitting to This Catalog

This catalog is meant to be extended. Add a skill entry when:

- The skill addresses a problem multiple teams face.
- The skill is well-tested and documented.
- The skill can be either self-built using the patterns here or pointed to in a public repo.

Don't add a skill that's specific to one codebase — that's a project-level skill, not a catalog entry.

---

## Further Reading

- [Skills Guide](guide.md) — conceptual basics.
- [Creating Skills](creating.md) — how to write your own.
- [Basic Skill Template](templates/basic-skill/SKILL.md) — start here for a new skill.
- [Advanced Skill Template](templates/skill-with-script/SKILL.md) — when bundling scripts.

---

**Status:** Living catalog. Last reviewed: 2026-05.
