# 05 — Review & Verify (don't let the author grade the homework)

**When:** Before calling any piece of work done. Ideally run in a fresh session/context so the reviewer isn't anchored to the implementer's reasoning.

---

## Template

```
Review the changes in [DIFF / FILES / LAST COMMIT] against this intent:

Intent: [WHAT THE CHANGE WAS SUPPOSED TO ACCOMPLISH]
Success criteria: [THE EXECUTABLE DEFINITION OF DONE]

Check specifically for:
1. Correctness — does it actually satisfy the criteria? Run [CHECK COMMAND].
2. Edge cases — what inputs/states would break this?
3. Unintended changes — anything modified outside the stated scope?
4. Consistency — does it match the patterns in the rest of the codebase?
5. Security/safety — [DOMAIN-RELEVANT: injection, secrets in code,
   unvalidated input, etc.]

Be adversarial. Try to refute the claim that this works rather than
confirm it. List findings ranked by severity, and state explicitly
if you find nothing significant.
```

## Final sanity pass (end of session)

```
Summarize everything we changed this session:
- Files touched and why
- Commands a reviewer should run to verify
- Anything left incomplete, hacky, or worth a TODO
- Anything I should manually double-check that automated checks won't catch
```

## Notes

- "Try to refute rather than confirm" flips the agent out of agreeable mode — fresh context + adversarial framing finds bugs the implementing session is blind to.
- "State explicitly if you find nothing" prevents invented nitpicks.
- The end-of-session summary doubles as your handoff narrative — in an interview, it's also your closing walkthrough for the interviewer.
