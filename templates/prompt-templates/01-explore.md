# 01 — Explore (build the map before touching anything)

**When:** First contact with a repo or problem space. Read-only. No edits.

**Why:** Agent quality jumps dramatically when the model has a mental map of the system before acting. This also surfaces your *own* understanding gaps early.

---

## Template

```
Analyze this repository/codebase. Do NOT modify any files — exploration only.

Explain:
- Overall architecture and key directories
- Entry points (how does this app/service start?)
- [DOMAIN-SPECIFIC LAYER, e.g., auth flow / API layer / data layer / build pipeline]
- How tests are run, and what the test coverage looks like
- Any conventions or patterns I should follow when adding code

Then answer:
1. Where would [THE FEATURE/FIX I'M ABOUT TO DO] most naturally live?
2. What existing code is most similar to what I'm about to add?
3. What could break if I change [AREA]?

Output a short system map I can refer back to.
```

## Quick variant (time-boxed)

```
Read [SPECIFIC FILES/DIRECTORY] only. In 10 bullets or fewer:
what does this do, how does data flow through it, and where are
the seams where I could safely add [CHANGE]?
Don't modify anything yet.
```

## Notes

- "Don't modify anything" / "exploration only" is the guardrail — say it explicitly.
- Pointing at *similar existing code* is gold: it anchors the agent to the repo's own conventions instead of generic patterns.
