# Content Generation System — Agent Contracts

Detailed contracts for the five agents in the curriculum content generation system. Read alongside [`README.md`](README.md) (system overview) and [`WALKTHROUGH.md`](WALKTHROUGH.md) (worked example across sessions).

---

## How These Agents Are Defined

This file is the project's shared **instructions/design document** — the cross-tool `AGENTS.md` standard that Claude Code and other coding agents read as project context. It documents each agent's role, contract, and place in the workflow. **It does not register or configure dispatchable agents.**

In Claude Code, the actual dispatchable subagents live in `.claude/agents/*.md` — one file per agent, with YAML frontmatter — or are created interactively via the `/agents` command:

```markdown
---
name: content-generator
description: Generates lecture notes, exercises, and project stubs for one assigned curriculum track. Use when a track in the master plan is ready for content generation.
tools: Read, Write, Edit, Glob, Grep
---

You are a curriculum content generator. You own exactly one track at a time.
Read the master plan and style guide before writing anything. Every module you
produce must meet the quality gates: 12,000+ words of lecture notes, 10+ code
examples, 3+ case studies, and 5–10 exercises. Emit a module manifest after
each module and never touch directories outside your assigned track.
```

**Recommended pattern:** keep one `.claude/agents/<name>.md` per agent below, and treat this file as the contract those definitions must honor.

---

## Shared Module Manifest

Every content-producing agent emits a manifest per module. This is what makes the QA phase mechanical — the validator checks manifests against measured reality, never prose claims.

```yaml
module_manifest:
  track: string                # e.g., junior-engineer
  module: int                  # 1-indexed position in the track
  title: string
  word_count: int              # measured (wc -w), never estimated
  code_examples: int
  case_studies: int
  exercises: int
  files:
    - path: string             # repo-relative
      kind: lecture | exercise | stub | spec | solution | guide
  status: draft | complete | validated
  generated_by: string         # agent instance id
  checkpoint: string | null    # checkpoint name this module was saved under
```

A module without a manifest does not exist as far as the QA agent is concerned.

---

## Phase State Machine

The orchestrator (the main Claude Code instance) advances the project through five phases. A phase cannot start until the previous phase's checkpoint has been saved **and** validated.

```text
┌──────────┐    ┌──────────────┐    ┌────────────────┐    ┌───────────┐    ┌──────┐
│ RESEARCH │───►│ CURRICULUM   │───►│ CONTENT        │───►│ SOLUTIONS │───►│  QA  │
│ (Phase 1)│    │ DESIGN (Ph 2)│    │ GENERATION     │    │ (Phase 4) │    │(Ph 5)│
└──────────┘    └──────────────┘    │ (Phase 3, ∥)   │    └───────────┘    └──┬───┘
                                    └────────────────┘                        │
                                            ▲                 fail: route back│
                                            └─────────────────────────────────┘
```

QA failures route back to the phase that owns the failing artifact (usually Phase 3 or 4), scoped to the failing modules only — never a full-phase redo.

### Orchestrator Rules

- **O1.** Save a checkpoint after every phase and after every 5 modules within Phase 3. Checkpoint names follow `checkpoint-<phase-or-track>-<scope>` (see README for the full naming tree).
- **O2.** Spawn parallel content agents only across **independent tracks**. Two agents never share a track directory.
- **O3.** If an agent fails mid-track, resume from its last module manifest — never regenerate modules that already have `status: complete`.
- **O4.** Phase 4 starts only after **all** learning-repo content is checkpointed. Solutions written against moving stubs drift.
- **O5.** An agent that errors writes a short reason file next to its manifests. The orchestrator surfaces this; it never silently drops a track.

---

## 1. research-agent

**Purpose**: Market research and requirements analysis. Produces the evidence base every later phase builds on.

### Sub-Agents

- **market-research** — analyzes job postings and role descriptions at scale.
- **skills-analysis** — distills postings into a deduplicated, leveled skills matrix.

### Inputs

- Target role list and career levels (from `CLAUDE.md` project overview).
- Seed sources: job boards, certification bodies, vendor documentation.

### Tools

| Tool | Server | Purpose |
|---|---|---|
| Web search | Brave Search MCP | Job postings, certifications, technology trends |
| Entity/relation store | Memory MCP | Persist findings for later phases |
| `read_file`, `write_file` | Filesystem MCP | Write `research/role-analysis.json` |

### Output

`research/role-analysis.json`:

```json
{
  "role_analysis": {
    "junior": { "responsibilities": [], "typical_requirements": [] },
    "engineer": { "...": "..." },
    "senior": { "...": "..." }
  },
  "skills_matrix": [
    { "skill": "string", "level": "junior|engineer|senior", "evidence_count": 0 }
  ],
  "technologies": []
}
```

### Behavioral Rules

- **R1.** Every skill in the matrix cites at least 3 independent sources (`evidence_count >= 3`). Single-posting skills are noted but flagged `low_confidence`.
- **R2.** Findings are stored as Memory MCP entities, not just prose — the curriculum-agent queries them by skill and level.
- **R3.** No curriculum design. Sequencing, module counts, and project themes are the curriculum-agent's job.
- **R4.** Record the research date in the output. Skills data goes stale; downstream agents should know how old it is.

---

## 2. curriculum-agent

**Purpose**: Turn the research evidence into a progressive learning architecture: tracks, modules, objectives, and project themes.

### Sub-Agents

- **learning-path** — sequences modules and prerequisites within and across tracks.
- **project-definition** — defines the capstone and per-module project themes.

### Inputs

- `research/role-analysis.json` and the Memory MCP graph from Phase 1.
- Quality standards from `CLAUDE.md` (word counts, exercise counts, coverage gates).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `read_file`, `write_file` | Filesystem MCP | Read research, write curriculum files |
| Entity/relation queries | Memory MCP | Pull skills matrix by level |

### Output

`curriculum/master-plan.json`:

```yaml
tracks:                          # 12 tracks total
  - id: string                   # e.g., junior-engineer
    level: junior | engineer | senior
    modules:                     # ~10 per track, 120+ total
      - id: int
        title: string
        objectives: [string]
        skills: [string]         # must exist in skills_matrix
        exercises_planned: int   # 5–10
        project_theme: string
    prerequisites: [track_id]
quality_gates:
  min_words_per_lecture: 12000
  min_code_examples: 10
  min_case_studies: 3
  exercises_per_module: [5, 10]
```

### Behavioral Rules

- **R1.** Every module maps to at least one skill in the skills matrix. Modules without research backing are rejected — invent nothing.
- **R2.** Prerequisites form a DAG. The learning-path sub-agent must verify no cycles before the plan is written.
- **R3.** Quality gates are defined here, once, and copied nowhere. Content and QA agents read them from the master plan.
- **R4.** The plan records a content-freeze hash. Phase 3 agents refuse to generate against a plan whose hash has changed since they started.

---

## 3. content-generation-agent

**Purpose**: Generate lecture notes, exercises, and project stubs for **one assigned track**. Multiple instances run in parallel during Phase 3, one per track.

### Sub-Generators

- **lecture-notes generator** — long-form technical writing (12,000+ words per major module).
- **exercise generator** — guided exercises with starter code and acceptance criteria.
- **project-stub generator** — code stubs with comprehensive TODOs matching the project spec.

### Inputs

- `curriculum/master-plan.json` (read-only) — its assigned track section.
- The style guide section of `CLAUDE.md` (voice, heading conventions, code-block formatting).
- Memory MCP research entities for the skills its modules cover.

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `read_file`, `write_file` | Filesystem MCP | Write content into the track directory |
| Entity queries | Memory MCP | Pull research context per skill |

### Quality Standards (per major module)

- Minimum 12,000 words of lecture notes — **measured**, not estimated.
- 10+ runnable code examples.
- 3+ case studies grounded in research findings.
- 5–10 exercises with stubs and acceptance criteria.

### Behavioral Rules

- **R1.** Read the style guide before writing module 1, and re-read it after every checkpoint resume. Style drift across sessions is the system's most common defect (see Anti-Patterns).
- **R2.** Never write outside the assigned track directory. Cross-track edits are an orchestrator-blocking error.
- **R3.** Emit a module manifest after every module. Word counts come from an actual count of the written file.
- **R4.** Checkpoint every 5 modules. A session that ends without a checkpoint repeats up to 5 modules of work.
- **R5.** Stubs contain TODOs and interface contracts only — no working implementations. Solutions are Phase 4's job, and learners should not find answers in the learning repo.
- **R6.** When context is running low mid-module, finish the current module, manifest it, checkpoint, and stop. Never leave a module half-written across a session boundary.

---

## 4. solutions-agent

**Purpose**: Produce complete, working implementations for every exercise and project stub, in the parallel solutions repositories.

### Sub-Agents

- **implementation** — writes and tests the solution code.
- **documentation** — writes step-by-step guides and API documentation.

### Inputs

- The frozen learning repos (content checkpointed at end of Phase 3).
- Module manifests (the authoritative list of exercises to solve).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| Repo creation, branches, pushes | GitHub MCP | Create and populate solutions repositories |
| Code validation | Quality Guard MCP | Lint/quality gates on solution code |
| `read_file`, `write_file` | Filesystem MCP | Implementation work |

### Output

One solutions repository per learning repository (12 total): implementations, step-by-step guides, API docs, deployment configs.

### Behavioral Rules

- **R1.** Every exercise stub has exactly one matching solution, keyed by the manifest's file paths. Stub/solution parity is a QA-blocking check.
- **R2.** Solutions must run. Execute the tests before marking a module's solutions complete — "looks correct" is not a status.
- **R3.** Maintain 80%+ test coverage on solution code. Coverage is reported per module in the manifest.
- **R4.** Never modify the learning repos. If a stub is wrong, file it as a defect for the content-generation-agent; do not silently fix it in only one of the two repos.
- **R5.** Step-by-step guides explain *why* at each step, not just *what*. A guide that restates the diff is a failed guide.

---

## 5. qa-agent

**Purpose**: Validate everything against the master plan and the manifests. The only agent allowed to set `status: validated`.

### Sub-Agents

- **content-validator** — completeness, quality-gate, and consistency checks.
- **link-checker** — every link in every repo resolves.

### Inputs

- `curriculum/master-plan.json` (the contract).
- All module manifests (the claims).
- The repos themselves (the reality).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| Test execution | Code Checker MCP | Run solution test suites |
| Linting | Ruff MCP | Python code quality |
| `read_file` | Filesystem MCP | Recount words, examples, exercises |
| Link validation | (script via Bash) | HTTP-check every link |

### Checks

1. **Completeness** — every planned module exists with all manifest files present.
2. **Quality gates** — word counts, example counts, case studies, exercise counts re-measured independently; manifests that disagree with reality are themselves findings.
3. **Code quality** — linters pass; solution tests pass; coverage ≥ 80%.
4. **Parity** — every stub has a solution; every solution has a stub.
5. **Links** — 100% of links resolve.
6. **Consistency** — heading conventions, voice, and terminology uniform across tracks generated by different parallel agents.

### Output

`validation-report.md` plus a machine-readable findings file:

```yaml
findings:
  - id: string
    track: string
    module: int
    check: completeness | quality_gate | code_quality | parity | links | consistency
    severity: blocking | should_fix | note
    message: string
    owner_agent: content-generation-agent | solutions-agent | curriculum-agent
```

### Behavioral Rules

- **R1.** Validate against manifests *and* re-measure. Trust nothing an agent said about its own output.
- **R2.** Every finding names the owner agent. Findings route back scoped to the failing module — never trigger full-track regeneration.
- **R3.** The qa-agent never fixes content itself. Validators that edit lose their independence.
- **R4.** Run on the cheapest model tier appropriate. Most of this work is counting and diffing; expensive reasoning is wasted here.

---

## Cross-Cutting Rules

These apply to every agent.

- **C1.** All inter-agent state flows through Memory MCP entities and files on disk. No agent assumes another agent's conversational context.
- **C2.** Every produced artifact is declared in a manifest. Undeclared files are deleted at QA time.
- **C3.** Content agents are read-only outside their assigned track; the solutions-agent is read-only against learning repos; the qa-agent is read-only against everything.
- **C4.** Checkpoint names are descriptive and follow the `checkpoint-<phase-or-track>-<scope>` convention so any future session can resume without archaeology.
- **C5.** Quality numbers (word counts, coverage) are measured by tools, never estimated by the model.

---

## Calling Conventions

Manual invocation (the project was driven this way; see [`WALKTHROUGH.md`](WALKTHROUGH.md)):

```text
"Use the research-agent to analyze the AI Infrastructure Engineer role across levels."
"Have the curriculum-agent design the master plan from research/role-analysis.json."
"Spawn content-generation-agents for the junior, engineer, and senior tracks in parallel."
"Have the solutions-agent implement all exercises for the junior-engineer track."
"Run the qa-agent against all 24 repositories and produce the validation report."
```

Resume conventions:

```text
"Resume from checkpoint: checkpoint-phase2-complete and start Phase 3."
"Resume the engineer track from its last module manifest."
```

---

## Anti-Patterns

- **Anti-pattern 1: One mega-prompt per track.** Tried first. Generating a whole 10-module track in one shot exhausts context mid-track and the back half degrades sharply. Generate module-by-module with manifests and checkpoints.
- **Anti-pattern 2: Skipping checkpoints on "short" sessions.** The session that crashes is always the one you didn't checkpoint. Checkpoint every 5 modules, no exceptions.
- **Anti-pattern 3: Letting content agents self-certify.** An agent reporting its own word count as "approximately 12,000" was the original source of thin modules. Measure with tools; verify independently in QA.
- **Anti-pattern 4: Starting solutions against unfrozen stubs.** Stubs that change after solutions are written produce silent stub/solution drift. Freeze Phase 3 output (checkpoint + plan hash) before Phase 4 begins.
- **Anti-pattern 5: Sharing a style by example instead of by rule.** "Match the tone of track 1" gave every parallel agent a different interpretation. Write the style guide as explicit rules in `CLAUDE.md` and have agents re-read it after every resume.

---

**Last Updated**: 2026-06-11
