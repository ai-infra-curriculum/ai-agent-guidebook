# 02 — Plan (strategy before code)

**When:** Any non-trivial task. This is the highest-leverage prompt in the set.

**Why:** Forcing a plan first lets you catch wrong assumptions when they're cheap to fix — before they're embedded in 400 lines of code. You review the plan like you'd review a junior engineer's design sketch.

---

## Template

```
I need to [GOAL — outcome in user/business terms, not just the mechanical task].

Context:
- [What the system does / who uses this]
- [What already exists that's relevant]
- [Anything you learned in the explore step]

Constraints:
- Language/framework: [e.g., Python 3.12, FastAPI]
- Follow existing patterns in: [FILE/MODULE]
- Do NOT change: [FILES/BEHAVIOR THAT MUST STAY STABLE]
- [Performance / security / compatibility requirements]

Success criteria:
- [Executable check if possible: "pytest tests/test_x.py passes", "endpoint returns 200 with shape Y"]
- [Edge cases that must be handled]

Think through the approach and produce a step-by-step implementation plan.
DO NOT write implementation code yet.

For the plan, include:
1. Files you'll create or modify, and why
2. The order of changes
3. Risks or assumptions you're making — flag anything you're unsure about
4. How we'll verify each step
```

## Then (critical step — human in the loop)

**Read the plan. Push back on it.** Correct wrong assumptions, cut scope, reorder. Only then say:

```
The plan looks good with these changes: [CORRECTIONS].
Proceed with step 1 only, then stop so I can review.
```

## Notes

- "Do not write code yet" must be explicit or the agent will jump ahead.
- "Flag anything you're unsure about" surfaces hidden assumptions — in an interview, *reading those aloud and reacting to them* demonstrates exactly the judgment they're testing for.
- Stepwise execution ("step 1 only, then stop") keeps every diff small enough to actually review.
