# 03 — Implement (one scoped task, with guardrails)

**When:** Executing a single piece of the plan, or a small self-contained task that doesn't need a formal plan.

---

## Template

```
Task: [ONE specific, scoped change]

Context: [1–3 lines: what this is part of, why it exists]

Requirements:
- [Functional requirement 1]
- [Functional requirement 2]
- Handle these edge cases: [LIST]

Constraints:
- Match the style/patterns in [REFERENCE FILE]
- Use [LIBRARY/VERSION]; do not add new dependencies without asking
- Do NOT modify [PROTECTED FILES/INTERFACES]

Definition of done:
- [EXECUTABLE CHECK: command + expected result]

After implementing, run [TEST/LINT/BUILD COMMAND] and fix any
failures before reporting back. Show me the diff and a one-paragraph
summary of what changed and why.
```

## Test-first variant (strong signal in interviews)

```
First, write tests for [BEHAVIOR] covering: [CASES, including edge cases].
Run them and confirm they fail for the right reason.
Then implement until the tests pass. Do not modify the tests to make them pass —
if a test seems wrong, stop and tell me instead.
```

## Notes

- "Run the check and iterate until it passes" closes the loop — the agent verifies its own work instead of handing you something untested.
- "Do not modify the tests to make them pass" prevents the classic failure mode of reward-hacking the verifier.
- "No new dependencies without asking" prevents surprise supply-chain additions.
