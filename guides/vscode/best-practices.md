# VS Code Agentic Best Practices

Proven patterns and the anti-patterns that bite people, for running VS Code as an agentic environment — covering the agent loop, approvals and trust, MCP hygiene, customization discipline, and a security posture you can defend.

---

## Table of Contents

- [The Short Version](#the-short-version)
- [Pick the Right Mode for the Job](#pick-the-right-mode-for-the-job)
- [Approvals and Trust](#approvals-and-trust)
- [Scope the Agent's Tools](#scope-the-agents-tools)
- [Keep the Request Budget Honest](#keep-the-request-budget-honest)
- [Customization Discipline](#customization-discipline)
- [MCP Hygiene](#mcp-hygiene)
- [Reviewing Agent Output](#reviewing-agent-output)
- [Security Posture](#security-posture)
- [Anti-Patterns](#anti-patterns)
- [Related Guides](#related-guides)

---

## The Short Version

Five habits that compound:

1. **Match the mode to the task.** Ask to learn, Edit to make a scoped change, Agent for autonomous multi-step work. Don't reach for agent mode to answer a one-line question.
2. **Never globally auto-approve on your real machine.** Keep tool confirmations on; allow-list only safe, idempotent terminal commands.
3. **Restrict tools per agent.** A reviewer that can't edit is safer than a reviewer you're trusting to not edit.
4. **Write instructions once, not in every prompt.** `AGENTS.md` plus a couple of scoped `*.instructions.md` files beats re-typing context.
5. **Review the diff, not the chat.** The agent's narrative is not the change. Read what actually landed.

---

## Pick the Right Mode for the Job

The three built-in modes exist for different jobs. Using the wrong one is the most common inefficiency.

| Task | Mode | Why |
|------|------|-----|
| "What does this function do?" | **Ask** | No edits needed; fastest, cheapest |
| "Convert this file to async/await" | **Edit** | Scoped, single-target rewrite you can preview as a diff |
| "Add a feature across the API, service, and tests, and make the tests pass" | **Agent** | Needs to gather context, edit multiple files, run tests, iterate |
| A recurring, well-defined task | **Prompt file** | Captures the steps so you don't re-describe them |
| A persistent role (reviewer, planner) | **Custom agent** | Pins tools and behavior across many sessions |

Agent mode is powerful but it spends model requests gathering context and iterating. For a question you could answer in Ask mode, agent mode is slower and more expensive for no benefit.

---

## Approvals and Trust

This is the most important section. Agent mode can edit your files and run commands on your machine — the approval system is what keeps that safe.

### The default posture is correct

Out of the box, agent mode confirms before running tools and before terminal commands. **Leave it that way on any machine you care about.** When a confirmation appears:

- Expand it and read the actual command or tool parameters.
- Edit the parameters if the agent got something subtly wrong.
- Allow once for one-off actions; allow-for-session only for things you'll repeat and trust.

### Terminal allow-listing, done right

`chat.tools.terminal.autoApprove` lets you skip the prompt for specific commands. Allow-list only **read-only or idempotent** commands you run constantly:

- Good candidates: `git status`, `git diff`, `ls`, your test runner, your linter, your build.
- Never: `git push`, `rm`, anything that writes to a remote, anything that pipes a download into a shell.

VS Code already hard-blocks a dangerous set (`rm`, `rmdir`, `del`, `kill`, `curl`, `wget`, `eval`, `chmod`, `chown`) from auto-approval regardless of your list — don't fight that; it's the backstop.

### `chat.tools.global.autoApprove` is not for you

Setting `chat.tools.global.autoApprove: true` auto-approves *everything* and turns off the safety prompts. The only legitimate place for it is a **disposable, sandboxed, network-isolated container** — CI, an ephemeral worktree, a throwaway VM. On your workstation it is the agentic equivalent of running every suggested command as root, unread.

> Detail: [agent-mode.md](agent-mode.md#approvals-and-confirmations). Source: [Manage approvals and permissions](https://code.visualstudio.com/docs/agents/approvals).

---

## Scope the Agent's Tools

Two layers of scoping, both worth using:

1. **Per-request** — the **Configure Tools** button. Before a sensitive run, deselect tools the task doesn't need. Fewer tools means fewer ways to go wrong and a tighter, faster prompt (remember the 128-tool ceiling).
2. **Per-agent** — the `tools` frontmatter on a [custom agent](customization.md#custom-agents-formerly-chat-modes). A reviewer agent given only read/search tools *cannot* edit files. This is enforcement, not a polite request in the prompt.

The principle is identical to least-privilege everywhere else: grant the minimum capability the role needs. A planning agent doesn't need terminal access; a reviewer doesn't need edit access; a scaffolding prompt doesn't need network fetch.

---

## Keep the Request Budget Honest

`chat.agent.maxRequests` (default 25) caps iterations per run. Treat the cap as a smoke detector, not a nuisance:

- **Hitting it on a big, legitimate refactor?** Raise it deliberately for that task.
- **Hitting it on something routine?** Stop. The agent is usually thrashing — failing the same test repeatedly, or working from an under-specified goal. Re-scope the prompt rather than handing it more budget to spin.

Cheap, fast models burn budget on iteration; frontier models often converge in fewer requests. Factor that into model choice for autonomous runs.

---

## Customization Discipline

The customization mechanisms (see [customization.md](customization.md)) are leverage — and like all leverage, easy to overdo.

**Do:**

- Keep `AGENTS.md` (or `.github/copilot-instructions.md`) **short and imperative**. Conventions, commands, hard "never do X" rules. An agent skims a focused file better than it parses a manifesto.
- Use `applyTo`-scoped instructions for language- or directory-specific rules so they only load when relevant.
- Build a small library of prompt files for genuinely recurring tasks.
- Migrate any old `*.chatmode.md` files to `*.agent.md` — the old extension is deprecated.

**Don't:**

- Don't dump your entire style guide into one instructions file. Long, low-signal instructions dilute the rules that matter and cost context on every turn.
- Don't encode secrets or environment specifics in instruction files (they're committed).
- Don't create five overlapping custom agents you'll never switch between. One reviewer and one planner beats a drawer of half-used personas.

---

## MCP Hygiene

(Full treatment in [mcp-servers.md](mcp-servers.md); the operational essentials:)

- **Right key, right file.** Workspace servers go in `.vscode/mcp.json` under `servers` — *not* `mcpServers` (that's Claude Code's key). This is the #1 "my server doesn't appear" bug.
- **Pin versions.** `@scope/server@1.2.3`, never `@latest`. MCP servers are a supply-chain surface.
- **Secrets via `inputs`,** never hardcoded in the committed file.
- **Least privilege per server.** Read-only DB replicas, scoped tokens, namespaced service accounts.
- **Prune what you don't use.** Every connected server costs startup time and eats into the 128-tool budget. `MCP: List Servers` to audit.

---

## Reviewing Agent Output

The agent's chat narrative describes what it *intended*. The diff is what *happened*. Review the diff.

- **Use Source Control.** Agent edits land as working-tree changes. Read them in the diff view before staging, exactly as you'd review a teammate's PR.
- **Re-run the verification yourself.** If the agent says "tests pass," run them in a terminal you control. Auto-approved test runs can pass against a state the agent half-mutated.
- **Grep for invented symbols.** Agents occasionally reference functions or packages that don't exist. A quick search catches hallucinated imports before they reach CI.
- **Watch for scope creep.** A "fix this bug" task that also reformatted three unrelated files needs to be split — revert the noise.

---

## Security Posture

A defensible setup for a real workstation:

1. **Confirmations on.** `chat.tools.global.autoApprove` stays `false`.
2. **Terminal allow-list is read-only/idempotent only.** No remote-mutating or download-piping commands.
3. **MCP servers are pinned, least-privilege, and secret-free in source.** Use `inputs` for credentials.
4. **Custom agents are tool-restricted** to their role.
5. **Sensitive files are out of reach.** Keep `.env`, secrets, and key material out of the workspace context the agent reads; use the `sandbox` block (macOS/Linux) for servers you don't fully trust.
6. **Org policy where it belongs.** In managed fleets, gate MCP with `chat.mcp.access` and model availability by policy rather than relying on every developer's local config.

Prompt injection is the agentic threat that's easy to forget: a malicious MCP resource, a fetched web page, or a crafted file comment can carry instructions the model may act on. Auto-approving a "fetch any URL" tool is equivalent to unattended network egress driven by untrusted text. The cross-framework governance layer for this — PII scrubbing, injection interception, audit logging in front of tools — is the same regardless of client and is covered in the [Claude Code MCP governance section](../claude-code/mcp-servers.md#agent-governance-layer).

> Source: [Manage approvals and permissions](https://code.visualstudio.com/docs/agents/approvals), [Manage AI settings in enterprise environments](https://code.visualstudio.com/docs/enterprise/ai-settings).

---

## Anti-Patterns

| Anti-pattern | Why it bites | Do instead |
|--------------|--------------|------------|
| Global auto-approve on your laptop | One bad command runs unattended | Confirmations on; allow-list safe commands only |
| Pasting `mcpServers` into `.vscode/mcp.json` | VS Code reads `servers`; nothing loads | Use the `servers` key |
| Hardcoded tokens in `.vscode/mcp.json` | Leaks to repo + git history | `inputs` array with `password: true` |
| Agent mode for a quick question | Slower, costs requests | Ask mode |
| One giant instructions file | Dilutes the rules that matter | Short `AGENTS.md` + scoped `applyTo` files |
| Trusting the chat summary as the change | The narrative isn't the diff | Review the working-tree diff |
| Raising `maxRequests` to push through thrashing | Spends budget on a broken loop | Re-scope the prompt |
| 30 MCP servers "just in case" | Slow startup, blows the 128-tool cap | Prune to what you use; group with toolsets |
| `*.chatmode.md` files | Deprecated extension | Rename to `*.agent.md` |

---

## Related Guides

- [VS Code README](README.md) — the agentic surface overview
- [Agent Mode](agent-mode.md) — the loop, tools, approvals, models in depth
- [MCP Servers in VS Code](mcp-servers.md) — full MCP configuration and security
- [Customization](customization.md) — instructions, custom agents, prompt files
- [GitHub Copilot Best Practices](../github-copilot/best-practices.md) — completion- and chat-level habits this guide doesn't repeat
- [Repo Security Best Practices](../../best-practices/security.md)
- [Agent Governance](../../best-practices/agent-governance.md)

---

**Last Updated**: 2026-06-16
