# Content Generation System — End-to-End Walkthrough

A condensed but complete project run: the prompts, agent activity, intermediate artifacts, and checkpoint saves/resumes across the 10–15 sessions it took to produce 24 repositories and 200,000+ words. Use it as a template when you adapt the system to your own long-running content project.

---

## Prerequisites

A project workspace laid out like this:

```text
curriculum-project/
├── CLAUDE.md                    # project config, phases, style guide
├── AGENTS.md                    # agent contracts (this example's AGENTS.md)
├── .claude/
│   ├── agents/                  # dispatchable subagent definitions
│   │   ├── research-agent.md
│   │   ├── curriculum-agent.md
│   │   ├── content-generator.md
│   │   ├── solutions-agent.md
│   │   └── qa-agent.md
│   └── memory/                  # Memory MCP storage path
├── .mcp.json                    # project-scoped MCP servers (committed)
├── research/                    # Phase 1 output
├── curriculum/                  # Phase 2 output
├── tracks/                      # Phase 3 working area (one dir per track)
├── checkpoints/                 # checkpoint notes per save
└── validation/                  # Phase 5 output
```

Each file in `.claude/agents/` is a subagent definition with YAML frontmatter (`name`, `description`, optional `tools`) and a system-prompt body — see the example in [`AGENTS.md`](AGENTS.md). You can also create them interactively with `/agents`.

Environment:

```bash
export GITHUB_TOKEN=ghp_...      # repo creation rights in your org
export GITHUB_ORG=your-curriculum-org
```

MCP servers (`.mcp.json` at the project root — see [`README.md`](README.md) for the full config): GitHub, Memory, Filesystem, Quality Guard.

Launch Claude Code from the project root:

```bash
cd curriculum-project
claude
```

Claude Code picks up `CLAUDE.md`, `AGENTS.md`, the `.mcp.json` servers, and the subagent definitions automatically. Verify with `/mcp` that all four servers are connected before starting — Phase 1 silently degrades if Memory MCP is missing.

---

## Session 1 — Phase 1: Research

### Prompt

```text
"Let's start the AI Infrastructure Curriculum project. Begin with Phase 1:
Research, per CLAUDE.md. Use the research-agent."
```

### What Happens

```text
[research-agent spawned]

market-research sub-agent:
  brave_search("AI infrastructure engineer job requirements 2026")
  brave_search("MLOps engineer responsibilities senior vs junior")
  ... (~40 queries across roles and levels)
  → 500+ postings analyzed

skills-analysis sub-agent:
  memory_create_entities([
    {name: "kubernetes", type: "skill", observations: ["required in 412 postings", "level: all"]},
    {name: "distributed-training", type: "skill", observations: ["senior-level in 88% of mentions"]},
    ...
  ])
  → skills matrix: 96 skills, leveled junior/engineer/senior

write_file(research/role-analysis.json)
```

Excerpt of `research/role-analysis.json`:

```json
{
  "skills_matrix": [
    { "skill": "kubernetes", "level": "engineer", "evidence_count": 412 },
    { "skill": "terraform", "level": "engineer", "evidence_count": 287 },
    { "skill": "distributed-training", "level": "senior", "evidence_count": 88 },
    { "skill": "model-serving", "level": "junior", "evidence_count": 198 }
  ]
}
```

One skill came back with `evidence_count: 1` and was flagged `low_confidence` per research-agent rule R1 — it was dropped from the matrix rather than silently included.

### Checkpoint

```text
"Save checkpoint: checkpoint-phase1-complete"

→ Memory MCP entity: checkpoint-phase1-complete
  (phase status, output paths, skills matrix summary)
→ checkpoints/phase1-complete.md (human-readable progress note)
```

Session ends. Total: ~2.5 hours of agent time.

---

## Sessions 2–3 — Phase 2: Curriculum Design

### Prompt (new session)

```text
"Resume from checkpoint: checkpoint-phase1-complete and start Phase 2:
Curriculum Design with the curriculum-agent."
```

### What Happens

```text
[checkpoint loaded: research findings, skills matrix via Memory MCP]
[curriculum-agent spawned]

learning-path sub-agent:
  - Designs 12 progressive tracks across junior/engineer/senior levels
  - Sequences ~10 modules per track (122 total)
  - Verifies prerequisite DAG has no cycles  ✓

project-definition sub-agent:
  - Defines per-module project themes
  - Plans 300+ exercises (5–10 per module)
  - Maps every module to skills-matrix entries — 3 modules initially
    failed the mapping check (no research backing) and were re-scoped

write_file(curriculum/master-plan.json)
```

Excerpt of `curriculum/master-plan.json`:

```yaml
tracks:
  - id: junior-engineer
    level: junior
    modules:
      - id: 1
        title: "Containers and Images from First Principles"
        objectives: ["explain image layering", "build minimal images", ...]
        skills: ["docker", "containerization"]
        exercises_planned: 7
        project_theme: "Containerize and harden a model-serving API"
quality_gates:
  min_words_per_lecture: 12000
  min_code_examples: 10
  min_case_studies: 3
  exercises_per_module: [5, 10]
```

Note the quality gates live here, once. Every later agent reads them from the plan rather than carrying its own copy — this is what makes the QA phase mechanical.

### Checkpoint

```text
"Save checkpoint: checkpoint-phase2-complete"
```

The plan's content-freeze hash is recorded in the checkpoint. Phase 3 agents will refuse to generate against a modified plan (curriculum-agent rule R4).

---

## Sessions 4–10 — Phase 3: Content Generation (Parallel)

This is the long middle of the project: 40–60 hours of agent time across seven sessions.

### Prompt

```text
"Resume from checkpoint-phase2-complete. Generate content for the junior,
engineer, and senior tracks in parallel — one content-generation-agent per
track. Checkpoint every 5 modules."
```

### What Happens

```text
[3 content-generation-agents spawned in parallel]

Agent A: tracks/junior-engineer/   (modules 1–10)
Agent B: tracks/engineer/          (modules 1–10)
Agent C: tracks/senior-engineer/   (modules 1–10)

Each agent, per module:
  1. read master-plan.json (its track section) + CLAUDE.md style guide
  2. memory queries for the module's skills (research context)
  3. lecture-notes generator  → lessons/module-N.md      (12,000+ words)
  4. exercise generator       → exercises/module-N/      (5–10 exercises)
  5. project-stub generator   → projects/module-N/       (stubs + TODOs)
  6. write module manifest, measure word count with wc -w
```

A real module manifest from Agent A:

```yaml
module_manifest:
  track: junior-engineer
  module: 3
  title: "Model Serving Fundamentals"
  word_count: 13247        # measured, not estimated
  code_examples: 14
  case_studies: 3
  exercises: 8
  files:
    - path: tracks/junior-engineer/lessons/module-3.md
      kind: lecture
    - path: tracks/junior-engineer/exercises/module-3/
      kind: exercise
    - path: tracks/junior-engineer/projects/module-3/serve_stub.py
      kind: stub
  status: complete
  generated_by: content-generation-agent-A
  checkpoint: checkpoint-junior-engineer-modules-1-5
```

### Mid-Track Resume (the checkpoint system earning its keep)

Session 6 ended with Agent B's context nearly exhausted partway through module 7. Per rule R6 it finished the module, wrote the manifest, and stopped:

```text
"Save checkpoint: checkpoint-engineer-modules-6-7"
```

Session 7 opened with:

```text
"Resume the engineer track from its last module manifest."

[content-generation-agent spawned]
  read tracks/engineer/manifests/  → modules 1–7 status: complete
  re-read CLAUDE.md style guide    (rule R1: re-read after every resume)
  → resumes at module 8. No regenerated work.
```

The style-guide re-read on resume matters: the one time it was skipped, modules 8–10 came back with a noticeably different voice than 1–7 (see the failure-mode variant below).

### Checkpoints Through Phase 3

```text
checkpoint-junior-engineer-modules-1-5
checkpoint-junior-engineer-modules-6-10
checkpoint-engineer-modules-6-7          ← unplanned, context exhaustion
checkpoint-engineer-complete
checkpoint-senior-engineer-complete
...
checkpoint-all-learning-repos-complete   ← Phase 3 freeze point
```

Parallel generation across independent tracks cut wall-clock time roughly 60% versus the sequential dry run.

---

## Sessions 11–13 — Phase 4: Solutions

### Prompt

```text
"Resume from checkpoint-all-learning-repos-complete. Have the solutions-agent
implement all exercises and projects, one solutions repo per learning repo."
```

### What Happens

```text
[solutions-agent spawned, track by track]

For each of the 12 learning repos:
  gh_create_repository(<track>-solutions)           # GitHub MCP

  implementation sub-agent:
    - reads module manifests (the authoritative exercise list)
    - implements every stub, runs the tests          # rule R2: solutions must run
    - quality_guard_check(...)                       # Quality Guard MCP
    - coverage measured per module → recorded in manifest

  documentation sub-agent:
    - step-by-step guides (the "why" at each step)
    - API documentation, deployment configs
```

One stub turned out to be unimplementable as written (a TODO referenced a function the spec never defined). Per rule R4 the solutions-agent did **not** quietly patch the learning repo — it filed a defect, and the content-generation-agent fixed the stub in the learning repo so both repos stayed in sync.

Coverage at end of phase: 80%+ on solution code across all 12 repos.

### Checkpoint

```text
"Save checkpoint: checkpoint-solutions-complete"
```

---

## Sessions 14–15 — Phase 5: QA

### Prompt

```text
"Run the qa-agent against all 24 repositories. Validate against the master
plan and the module manifests, and produce the validation report."
```

### What Happens

```text
[qa-agent spawned]

content-validator sub-agent:
  - completeness: 122/122 planned modules present                    ✓
  - quality gates: re-measures every lecture independently
      → 2 findings (below)
  - parity: every stub has a solution, every solution a stub         ✓
  - consistency: heading/voice scan across tracks
      → 1 finding (below)

link-checker sub-agent:
  - 4,100+ links checked
      → 3 broken (vendor docs moved)

code checks:
  - ruff: clean across all repos                                     ✓
  - solution test suites: all passing, coverage ≥ 80%                ✓
```

`validation/findings.yaml` (excerpt):

```yaml
findings:
  - id: qa-001
    track: engineer
    module: 4
    check: quality_gate
    severity: blocking
    message: "Lecture measures 9,418 words; gate is 12,000. Manifest claimed 12,100."
    owner_agent: content-generation-agent
  - id: qa-002
    track: senior-engineer
    module: 9
    check: links
    severity: should_fix
    message: "3 links return 404 (vendor docs relocated)."
    owner_agent: content-generation-agent
  - id: qa-003
    track: engineer
    check: consistency
    severity: should_fix
    message: "Modules 8–10 use different heading conventions and voice than 1–7."
    owner_agent: content-generation-agent
```

Note `qa-001`: the manifest **lied** — the generating agent had estimated rather than measured (an early run before rule R3 was enforced). This is exactly why the qa-agent re-measures everything itself (qa-agent rule R1).

### Remediation Loop

Findings route back scoped to the failing modules only:

```text
"Have the content-generation-agent expand engineer module 4 to meet the
12,000-word gate, fix the 3 broken links in senior module 9, and normalize
the headings in engineer modules 8–10 against the style guide."

[content-generation-agent: 3 scoped fixes, manifests updated]

"Re-run the qa-agent on the affected modules."
→ all findings resolved. validation-report.md: PASS
```

### Final Checkpoint

```text
"Save checkpoint: checkpoint-project-complete"
```

Final tallies match the README: 24 repositories, 200,000+ words, 1,000+ code examples, 300+ exercises, 100% working links, all linters passing.

---

## What This Walkthrough Demonstrates

1. **Checkpoints make multi-session work survivable.** The engineer track's unplanned mid-track stop cost zero regenerated modules because every module had a manifest and the checkpoint recorded exactly where work stopped.
2. **Manifests beat prose claims.** The one thin lecture in the whole project was caught because QA re-measures instead of trusting the generating agent's numbers.
3. **Parallelism only across independent units.** Three agents on three disjoint track directories ran cleanly; nothing shared state except the read-only master plan.
4. **Freeze before depending.** Solutions were only started after `checkpoint-all-learning-repos-complete`, so stub/solution parity held across all 12 repo pairs.
5. **Failures route back scoped.** Three QA findings triggered three module-level fixes — not a regeneration of 122 modules.

---

## Failure-Mode Variant: Style Drift Across Sessions

The most common defect class in long-running content generation. During an early dry run, the engineer track's modules 8–10 (generated after a resume, without re-reading the style guide) came back with second-person voice and different heading depth than modules 1–7 (third-person, `##`-level sections).

```text
[qa-agent consistency check]
  modules 1–7:  voice=third-person, headings=##, examples fenced w/ language tags
  modules 8–10: voice=second-person, headings=###, bare fences
  → finding: consistency, severity: should_fix
```

Two fixes, both adopted:

1. **Rule fix** — the style guide in `CLAUDE.md` was rewritten from "match the established tone" (interpretable) to explicit rules (testable): voice, heading depth, fence format, terminology table.
2. **Process fix** — content-generation-agent rule R1: re-read the style guide after every checkpoint resume, not just at track start.

After both fixes, the consistency check stayed clean for the remainder of the project.

---

## Adapting This Walkthrough

| Reference | Replace with |
|---|---|
| Curriculum tracks/modules | your content units (docs chapters, course lessons, KB articles) |
| `role-analysis.json` skills matrix | your evidence base (user research, support tickets, SME interviews) |
| 12,000-word / 10-example gates | your quality gates — define them once, in the plan |
| GitHub MCP repo-per-track | your publishing target (CMS, docs site, monorepo) |
| Ruff / Code Checker MCP | linters and test runners for your stack |

The structural ideas port directly: phase the work, freeze upstream output before downstream depends on it, make every unit emit a measured manifest, and validate with an agent that didn't write the content. The agent contracts in [`AGENTS.md`](AGENTS.md) generalize to any high-volume content domain — the hardest part is usually writing a style guide precise enough that parallel agents can't interpret it differently.

---

**Last Updated**: 2026-06-11
