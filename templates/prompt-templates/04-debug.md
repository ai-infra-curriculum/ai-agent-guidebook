# 04 — Debug (root cause, not symptom patching)

**When:** Something is broken. The goal is diagnosis before treatment.

---

## Template

```
Bug report:
- Expected: [WHAT SHOULD HAPPEN]
- Actual: [WHAT HAPPENS — exact error/output, paste it]
- Repro: [STEPS OR COMMAND THAT TRIGGERS IT]
- When it started / what changed recently: [IF KNOWN]

Before changing any code:
1. Form 2–3 hypotheses for the root cause, ranked by likelihood
2. Tell me how you'd test each hypothesis (logs to read, command to run,
   minimal repro to write)
3. Run those checks and report what you find

Only after we've confirmed the root cause: propose a fix, explain why it
addresses the cause rather than the symptom, and note any other code paths
affected by the same underlying issue.
```

## Fast variant (when the error is self-evident)

```
This command fails: [COMMAND]
Error: [PASTE FULL ERROR]

Find the root cause and fix it. Then run [COMMAND] again to confirm,
and check whether the same issue exists anywhere else in the codebase.
```

## Notes

- Hypothesis-first debugging is what distinguishes engineering from prompt-flailing. In an interview, narrating "let's see which hypothesis the evidence supports" is a strong moment.
- Always paste the *full* error, not a paraphrase.
- "Check whether the same issue exists elsewhere" turns one fix into systemic cleanup.
