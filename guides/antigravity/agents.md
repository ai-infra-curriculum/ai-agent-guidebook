# The Antigravity Agent Model

How agents work in Google Antigravity: how they plan, what autonomy and permission controls govern them, how the browser subagent verifies work, how multiple agents run in parallel, and how to shape behavior with agent instructions and Skills.

---

## Table of Contents

- [What an Antigravity Agent Is](#what-an-antigravity-agent-is)
- [Planning: Task Lists and Implementation Plans](#planning-task-lists-and-implementation-plans)
- [Autonomy and Permissions](#autonomy-and-permissions)
- [The Browser Subagent](#the-browser-subagent)
- [Multi-Agent Work](#multi-agent-work)
- [Agent Instructions and Skills](#agent-instructions-and-skills)
- [Knowledge and Memory](#knowledge-and-memory)
- [Security Considerations](#security-considerations)
- [Anti-Patterns](#anti-patterns)

---

## What an Antigravity Agent Is

An Antigravity agent is an autonomous worker that operates at the **task level**: you describe a goal, and the agent plans and executes it across three tools a human developer would use — the **editor** (write/modify code), the **terminal** (install dependencies, run commands, start servers), and the **browser** (drive the running app and verify behavior).

Google's design framing is "agent-first": rather than an agent embedded inside an editor, the editor/terminal/browser surfaces are embedded into the agent, and you orchestrate agents from the **Agent Manager** mission-control surface (see [usage.md](usage.md#agent-manager)).

Agents report progress and results through **Artifacts** — task lists, implementation plans, code diffs, screenshots, browser recordings, walkthroughs, and test results — so you verify outcomes instead of reading raw logs.

---

## Planning: Task Lists and Implementation Plans

Before changing code, an agent produces planning Artifacts:

- **Task List** — a structured list of steps the agent intends to take. This is the agent's decomposition of your goal.
- **Implementation Plan** — the technical detail of what revisions are necessary, "meant to be reviewed by the user" before execution. Use it to catch a wrong approach early.

Because these are Artifacts, you can review and comment on them (Google Cloud community tutorials describe "Google Docs-style comments") and have the agent revise the plan before it writes a line of code. This plan-then-execute shape is the main lever for keeping a long-running agent on track.

---

## Autonomy and Permissions

Antigravity treats autonomy as an explicit, configurable surface rather than a single on/off "agent mode." Per Google Cloud community tutorials, two policy families govern how much an agent does before asking.

### Terminal-execution policy

Controls whether the agent runs shell commands without confirmation:

| Policy | Behavior |
|--------|----------|
| **Off** | Never auto-execute terminal commands, except those on a configurable **Allow list** |
| **Auto** | The agent decides per command, and asks you when it judges confirmation is needed |
| **Turbo** | Always auto-execute terminal commands, except those on a configurable **Deny list** |

### Review policy

Controls how often the agent pauses for you to review its work:

| Policy | Behavior |
|--------|----------|
| **Always Proceed** | No review gate |
| **Agent Decides** | The agent decides whether a step warrants review |
| **Request Review** | Always pause for review |

These settings are **per project** (each project has isolated agent settings), so you can run a throwaway scratch project in Turbo while keeping a production repo on Request Review. The intent, per coverage of Antigravity, is to let you choose a risk posture and raise autonomy as confidence grows.

<!-- needs-research: confirm the exact policy names ("Off/Auto/Turbo", "Always Proceed/Agent Decides/Request Review") and that they are per-project against official docs; sourced from community tutorials. -->

---

## The Browser Subagent

A defining capability is that agents verify their own work in a real browser. When an agent "wants to interact with the browser, it invokes a **browser subagent**" — a specialized component that can click, scroll, type, read console logs, and capture the DOM, then surface screenshots and recordings as Artifacts.

Guardrails:

- Browser control requires a **Chrome extension** to be installed.
- Browsing is gated by a **Browser URL Allowlist** (reported at `~/.gemini/antigravity/browserAllowlist.txt`) so an agent cannot wander to arbitrary URLs.

This is what lets Antigravity close the loop on UI changes: the agent doesn't just write code, it opens the page and shows you it works.

<!-- needs-research: confirm browser-subagent details, the extension requirement, and the allowlist path against official docs; sourced from community tutorials. -->

---

## Multi-Agent Work

The Agent Manager is built for **parallel, asynchronous** agents: you can "spawn, orchestrate, and observe multiple agents working asynchronously across different workspaces." Practically:

- Spawn several agents for independent tasks and let them run concurrently.
- Watch each agent's status and Artifacts in one dashboard.
- Review and accept/reject each agent's work independently as it completes.

This is the orchestration story that distinguishes Antigravity from an inline editor assistant — closer to managing a small fleet of workers than to pairing with one.

For a deeper treatment of multi-agent orchestration patterns (fan-out/fan-in, isolation, governance) that generalize across tools, see the [agent architecture guide](../agents-subagents/architecture.md).

---

## Agent Instructions and Skills

Antigravity supports project-level files that shape agent behavior. Per Google's "autonomous developer pipelines" codelab, these live under a project `.agents/` directory:

- **Agent instructions** — `.agents/agents.md`, defining agent personas with sections such as **Goals** (the agent's responsibility), **Traits** (behavioral personality), and **Constraints** (guardrails).
- **Skills** — markdown files under `.agents/skills/` (for example `.agents/skills/write_specs.md`). A skill describes an **Objective**, **Rules of Engagement**, a **Save Location** for its output Artifact, and step-by-step **Instructions**. Skills are loaded into the agent's context only when a request matches the skill's description.
- **Workflows** — files under `.agents/workflows/` that sequence skills, with YAML frontmatter (e.g., a `description` field) that turns a workflow into a runnable command.

```text
your-project/
└── .agents/
    ├── agents.md              # agent personas: Goals / Traits / Constraints
    ├── skills/
    │   └── write_specs.md      # Objective / Rules of Engagement / Save Location / Instructions
    └── workflows/
        └── pipeline.md          # YAML frontmatter + ordered skill invocations
```

> The relationship between this `.agents/agents.md` and the widely used root-level `AGENTS.md` convention (and exact casing/precedence) is not fully confirmed from primary docs here.
> <!-- needs-research: confirm whether Antigravity reads a root-level AGENTS.md in addition to .agents/agents.md, plus exact skill/workflow frontmatter fields, from official docs. The .agents/ layout is sourced from a Google codelab; the root AGENTS.md behavior is from third-party coverage. -->

These mirror, conceptually, the skills and project-instruction files in other agent tools — see the [Skills guide](../skills/guide.md) and the [AGENTS.md template](../../templates/AGENTS.md) for transferable patterns.

---

## Knowledge and Memory

Third-party coverage describes Antigravity treating **learning as a core primitive**: agents can save useful context and code snippets to a knowledge base to improve future tasks, and the Agent Manager is described as maintaining an evolving, workspace-local knowledge file that the agent updates over time.

<!-- needs-research: confirm the exact knowledge-base/memory mechanism, file name, and location from official docs; this is sourced from third-party coverage, and reports conflict on whether the file is named AGENTS.md or something else. -->

---

## Security Considerations

Agents that can run terminal commands and drive a browser carry real risk. Keep in mind:

- **Agents act with your user's permissions.** A malicious or poorly written Skill could, in principle, delete files or leak environment variables. Audit third-party Skills before adding them to a global/shared library.
- **Use the autonomy policies deliberately.** Reserve **Turbo** for disposable projects; keep production repos on conservative terminal-execution and review policies. Maintain the terminal **Deny list** and the browser **URL allowlist**.
- **Review the planning Artifacts.** The Implementation Plan is your chance to catch a wrong or destructive approach before execution.
- **Treat fetched/browser content as untrusted.** An agent that reads attacker-controlled web or file content can be steered by prompt injection — narrow the browser allowlist accordingly.

For governance patterns that apply across agent fleets (audit logging, policy enforcement, secret scrubbing), see the [agent architecture guide](../agents-subagents/architecture.md).

---

## Anti-Patterns

- **Running everything in Turbo on a real repo.** Auto-executing all terminal commands on production code invites destructive mistakes. Match autonomy to the stakes.
- **Skipping the Implementation Plan.** Accepting execution without reading the plan throws away Antigravity's main safety lever.
- **Trusting unaudited Skills.** Skills run with your permissions; vet them before adding to a shared library.
- **Over-broad browser allowlist.** Letting the browser subagent reach arbitrary URLs widens the prompt-injection surface.
- **Treating preview behavior as stable.** Limits, models, and UI are changing during the public preview — verify against [official docs](https://antigravity.google/docs/home).

---

## Related Guides

- [Antigravity Overview](README.md)
- [Installation](installation.md) — download, platforms, sign-in, first run
- [Usage](usage.md) — Editor view, Agent Manager, running agents, Artifacts
- [Agent Architecture](../agents-subagents/architecture.md)
- [Skills Guide](../skills/guide.md)
- [AGENTS.md Template](../../templates/AGENTS.md)

---

**Last Updated**: 2026-06-16
