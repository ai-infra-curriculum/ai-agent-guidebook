# Testing

Testing AI-generated code and the AI workflows themselves. Property-based, differential, golden-file, evals, regression, CI.

Last updated 2026-06-11.

---

## Table of Contents

- [Two Test Surfaces](#two-test-surfaces)
- [Testing AI-Generated Code](#testing-ai-generated-code)
- [Property-Based Testing](#property-based-testing)
- [Differential Testing](#differential-testing)
- [Golden-File Tests for Prompts](#golden-file-tests-for-prompts)
- [Evaluation Frameworks](#evaluation-frameworks)
- [Regression Testing as Prompts Evolve](#regression-testing-as-prompts-evolve)
- [CI Integration](#ci-integration)
- [When to Require Human Review](#when-to-require-human-review)
- [Checklist](#checklist)

---

## Two Test Surfaces

When AI is in the loop, there are two things to test:

1. **The code the AI wrote.** Standard testing, with extra emphasis because the author wasn't human and didn't reason about edge cases the way humans do.
2. **The AI workflow itself.** Prompts, agents, chains — these are software too, with regressions, drift, and inputs that produce wrong outputs.

Both need testing. Most teams cover #1 reasonably and ignore #2 entirely.

---

## Testing AI-Generated Code

### The bar doesn't drop

AI-generated code should hit the same bar as human-written code: same coverage targets, same review process, same CI gates. If anything, the bar is higher — the author can't explain its choices when you ask.

Default minimums (carry over from human standards):
- Unit test coverage: 80%
- Integration tests on every external boundary
- E2E tests on critical user flows
- Type checking strict mode
- Linter passing

### Edge-case prompting

The model writes the happy path well and the edge cases poorly. Prompt for the edges explicitly:

```text
Write the function. Then write tests covering:
- Empty input
- Single-element input
- Maximum-size input (specify what max is for our system)
- Null / undefined / None
- Unicode strings (emoji, RTL, combining characters)
- Concurrent calls
- Whatever else this function's failure modes are
```

Edge-case coverage from the same prompt that wrote the function is correlated — if the model missed a case while implementing, it often misses it in tests too. The fix: ask a *different model* (or a fresh context) to enumerate edge cases.

### Test the post-condition, not the implementation

When the AI writes tests, watch for "tests that pass because they assert what the implementation does, not what it should do." A test that pins behavior is worse than no test — it cements a bug.

Pattern: write the test first (from a spec or expectation), then have the AI implement. TDD with AI works well; AI-test-after often produces circular tests.

### Mutation testing

Mutation testing tools (`stryker` for JS, `mutmut` for Python, `pitest` for Java, `mutagen` for Rust) flip operators and conditions in your code, then run tests. If tests still pass, the mutation survived — the test suite has a gap.

Mutation testing is especially valuable on AI-generated code because it surfaces tests that don't actually exercise behavior, only check that the function returns *something*.

Run a mutation pass quarterly on critical code. Anything below ~70% mutation score has weak tests.

### Fuzzing

Property-based fuzzers (`hypothesis` for Python, `fast-check` for JS, `proptest` for Rust, Go's native fuzz) generate inputs you didn't think of.

Use on:
- Parsers
- Serializers / deserializers
- Validation functions
- State machines
- Anything with combinatorial input

A 5-minute fuzz run on AI-generated parser code routinely finds 1-3 crashes the AI's tests didn't.

---

## Property-Based Testing

For AI output specifically, property-based testing is high leverage because the AI is good at implementing examples and weak at general properties.

### Property examples

```python
from hypothesis import given, strategies as st

# Property: encoding then decoding returns the original
@given(st.binary())
def test_encode_decode_roundtrip(data):
    assert decode(encode(data)) == data

# Property: sorting is idempotent
@given(st.lists(st.integers()))
def test_sort_idempotent(xs):
    assert sorted(sorted(xs)) == sorted(xs)

# Property: serialization preserves length
@given(st.text())
def test_serialize_length(s):
    assert len(deserialize(serialize(s))) == len(s)

# Property: AI-written function never raises on valid input
@given(st.integers(min_value=0, max_value=2**31))
def test_no_unexpected_exceptions(n):
    try:
        result = ai_written_function(n)
        assert isinstance(result, int)
    except ValueError:
        pass  # documented failure mode
    except Exception:
        pytest.fail("undocumented exception")
```

### When properties beat examples

- Encoding/decoding, serialize/deserialize, parse/format pairs
- Mathematical operations with known properties (commutative, associative, identity)
- State machines (every transition preserves invariants)
- Filters / selectors (output is subset of input)
- Idempotent operations

### Limits

Property tests can't catch:
- Performance regressions (use benchmarks)
- Wrong but consistent behavior (use differential testing)
- Cross-call ordering (use sequence-aware fuzzing — `hypothesis.stateful`)

---

## Differential Testing

Run two implementations on the same input and compare. The two implementations can be:
- Old version vs new version (regression)
- Reference implementation vs production (compatibility)
- Two AI-generated variants (sanity)

### When to use

- Refactoring AI-generated code: run old vs new on a corpus, assert identical output.
- Replacing a library: run both on production-shape inputs.
- Migrating between LLM versions: run old prompt + old model vs new prompt + new model, compare.
- Cross-platform: run on Linux + macOS + Windows, compare.

### Example

```python
def test_refactor_preserves_behavior():
    inputs = load_corpus("fixtures/production-samples.jsonl")
    for inp in inputs:
        old = old_implementation(inp)
        new = new_implementation(inp)
        assert old == new, f"Mismatch on {inp}: {old} != {new}"
```

The corpus should be real-shape data, not synthetic. Sample from production logs (after PII scrubbing). 500-5000 samples is usually enough to surface regressions.

### Tolerance

Sometimes "identical" isn't the right bar — floating point, ordering, timestamps. Define tolerance per field:

```python
def near_equal(a, b):
    if isinstance(a, float):
        return abs(a - b) < 1e-9
    if isinstance(a, list):
        return sorted(a) == sorted(b)  # order doesn't matter
    return a == b
```

---

## Golden-File Tests for Prompts

Treat prompts like compiled code: a prompt + a model = a deterministic function (sort of). Golden-file tests pin the output.

### Pattern

```python
def test_prompt_summarize_pr():
    pr_diff = load_fixture("fixtures/pr-1234.diff")
    output = run_prompt("summarize-pr", pr_diff)
    expected = load_fixture("fixtures/pr-1234.summary.txt")
    assert similar(output, expected, threshold=0.85)
```

Where `similar` is:
- BLEU / ROUGE for natural language
- Embedding cosine similarity for semantic equivalence
- LLM-as-judge for "are these effectively the same"
- Exact match for structured (JSON) output

### Handling non-determinism

LLMs are non-deterministic by default. Mitigations:
- Set `temperature=0` for tests.
- Pin a dated model snapshot (`claude-sonnet-4-6-20251022`), not the rolling alias (`claude-sonnet-4-6`) — aliases move to new snapshots over time. (There is no `-latest` suffix; the alias is just the bare model name.)
- Use seed parameter where supported (OpenAI).
- Run N samples and assert against the consensus.
- For non-text output (JSON), validate schema and key fields, not the full byte string.

### When to update goldens

Goldens drift when:
- Model version updates
- Prompt changes
- Underlying behavior intentionally changes

Workflow:
1. Run the suite. Goldens fail.
2. For each failure: diff old vs new output. Decide if the change is intentional.
3. Intentional → `pytest --update-goldens` style flag updates them.
4. Unintentional → fix the prompt or the model pinning.

Never bulk-accept golden updates. Each one needs a human eye.

### Structure

```text
prompts/
├── summarize-pr/
│   ├── prompt.md            # the prompt template
│   ├── fixtures/
│   │   ├── pr-1234.diff
│   │   ├── pr-1234.summary.txt   # golden
│   │   ├── pr-5678.diff
│   │   └── pr-5678.summary.txt   # golden
│   └── test_summarize_pr.py
```

Version your prompts. A prompt change is a code change.

---

## Evaluation Frameworks

For non-trivial LLM workflows you graduate from golden files to eval suites: structured, scored, parameterized.

### Promptfoo

Config-file-driven. Compare prompts, models, and parameters side by side.

```yaml
# promptfooconfig.yaml
prompts:
  - file://prompts/summarize-v1.md
  - file://prompts/summarize-v2.md
providers:
  - anthropic:claude-sonnet-4-6
  - anthropic:claude-opus-4-8
  - openai:gpt-5.5
tests:
  - vars:
      diff: file://fixtures/pr-1234.diff
    assert:
      - type: contains
        value: "authentication"
      - type: llm-rubric
        value: "summary accurately describes the security fix"
      - type: latency
        threshold: 5000
```

Run: `promptfoo eval`. Get a matrix of (prompt × model × test → score). Output as HTML, JSON, or CSV.

Strengths: fast iteration, multi-provider, easy CI integration. Weaknesses: less suited to multi-turn agent eval.

### LangSmith Evaluations

Hosted by LangChain. Strong for LangChain / LangGraph workflows. Trace-based eval — every run is captured and replayable.

```python
from langsmith import Client
from langsmith.evaluation import evaluate

def correctness_eval(run, example):
    return {"score": 1 if run.outputs["answer"] == example.outputs["answer"] else 0}

evaluate(
    my_chain,
    data="dataset-id",
    evaluators=[correctness_eval, "qa", "embedding_distance"],
)
```

Strengths: integrated tracing, dataset management, regression dashboards. Weaknesses: tied to LangChain ecosystem; hosted-only for the full feature set.

### Arize Phoenix

Open source. OpenTelemetry-based. Evals are local-first.

Strengths: self-hostable, framework-agnostic, OTel native. Weaknesses: smaller library of built-in evaluators.

### Patronus AI

Managed evals focused on hallucination, PII, and safety. Built-in evaluators for "is this answer grounded?", "did this contain PII?", "is this on-topic?".

Strengths: production-grade safety evals out of the box. Use when you need defensible "we tested this for hallucinations" claims.

### Helicone, Langfuse, Braintrust

Each combines tracing + eval + prompt management with different opinions. Pick based on:
- Self-host vs SaaS
- Framework lock-in
- Pricing model
- Team's existing observability stack

### Eval taxonomy

Three classes of evaluator:

1. **Deterministic:** exact match, regex match, JSON schema, latency thresholds.
2. **Model-based:** LLM-as-judge ("rate this response 1-5 for accuracy"), semantic similarity, faithfulness check.
3. **Human-in-the-loop:** spot-check N% of runs, label outcomes, feed back into the deterministic + model-based evaluators.

Real production setups use all three. Deterministic for hard constraints (latency, format), model-based for fuzzy quality, human for ground truth and to calibrate the model-based judges.

---

## Regression Testing as Prompts Evolve

Prompts drift. New model version, new edge case, someone rewords a line — quality changes.

### Snapshot the metrics

Every time you change a prompt or model:
1. Run the full eval suite.
2. Save the scores with a version label.
3. Compare to previous version.

```text
v1.3 (claude-sonnet-4-6, prompt-rev-12)
  accuracy: 0.87
  latency_p95: 3.2s
  cost_per_call: $0.012

v1.4 (claude-sonnet-4-6, prompt-rev-13)
  accuracy: 0.91  up
  latency_p95: 4.8s  down
  cost_per_call: $0.018  down
```

Improvement on accuracy, regression on latency and cost. Decision is now informed, not vibes.

### Holdout sets

Maintain three datasets:
- **Dev set:** what you iterate against. Open. Updated freely.
- **Eval set:** the gate for merging prompt changes. Stable. Snapshotted with prompt versions.
- **Holdout set:** never seen during iteration. Run quarterly. Catches overfitting to the eval set.

### Prompt-A/B testing in production

Production traffic can be split between prompt versions to compare on real input. Pattern:

- 95% on the stable prompt
- 5% on the candidate prompt
- Log outcomes, user satisfaction, downstream metrics
- Promote candidate when it wins on the agreed metrics for a defined window

LangSmith, Helicone, Braintrust, and PromptLayer support this directly.

---

## CI Integration

Tests are useless if they don't run automatically.

### What runs in CI

**Always:**
- Unit tests
- Type checking
- Linters
- Security scans
- Secret scanners
- License checks

**On PRs that touch prompts:**
- Prompt eval suite
- Golden-file tests
- Latency benchmarks

**Nightly / scheduled:**
- Property-based tests with longer budgets
- Mutation testing
- Fuzz runs (1-hour budgets)
- Differential tests against last week's prod corpus

**Weekly / quarterly:**
- Holdout eval run
- Cost-per-task trend
- Regression sweep across all prompt versions

### Speed budget

If CI takes longer than 10 minutes for typical PRs, developers will route around it. Strategies:
- Parallelize across runners.
- Cache test fixtures, embedding corpora, model weights.
- Use eval subsets for PRs, full eval nightly.
- Use cheaper models for evaluator LLMs (Haiku 4.5 judging Sonnet output is fine).

### Cost budget

LLM eval calls cost money. Per-PR eval budgets:
- Small change (single prompt): $0.50-$2
- Medium change (prompt + dataset update): $5-$20
- Major refactor: cap at $50, alert on exceed

Track in CI. A runaway eval suite that calls Opus 1000 times on every PR is a real budget event.

### Required vs optional checks

Required (blocks merge):
- Unit tests pass
- Type check passes
- Security scan green (no new criticals)
- Prompt eval >= baseline

Optional (informational):
- Latency comparison
- Cost delta
- Mutation score
- Holdout regression

The "optional" ones should still annotate the PR — comments or status checks — so reviewers see them.

---

## When to Require Human Review

Some changes are not safe to automate, even with green tests.

### Always-human

- Authentication and authorization logic
- Cryptography and key management
- Payment processing
- PII or PHI handling
- Database migrations (especially destructive)
- IAM policies, security groups, network ACLs
- Permissions / RBAC
- Anything that touches money, secrets, or compliance-scoped data

### Human-when-novel

- New external dependencies (any first-use of a package)
- New deploy targets / environments
- New tool / MCP server integrations
- Cross-service contract changes
- API breaking changes

### Automatable-with-tests

- Bug fixes with regression tests
- Refactors within a service
- Test additions
- Documentation
- Style fixes
- Dependency version bumps within a major version (with green tests)

### Review checklist for AI PRs

Reviewers should explicitly verify:
- [ ] Tests cover the failure modes, not just the happy path
- [ ] No new dependencies snuck in (or new ones are reviewed)
- [ ] Error handling is explicit
- [ ] No commented-out code, no TODOs that should be issues
- [ ] No hardcoded values that should be config
- [ ] Logs don't leak PII or secrets
- [ ] Security patterns followed (parameterized queries, input validation)
- [ ] If the AI hallucinated something, it's been corrected

---

## Checklist

For any AI-generated code:
- [ ] Tests written, ideally before the implementation
- [ ] Tests cover edge cases, not just happy path
- [ ] Type checker / linter / security scanner pass
- [ ] No new package added without verification
- [ ] Human review on auth / payments / crypto / IaC

For any LLM-based workflow:
- [ ] Prompts versioned in git
- [ ] Golden-file or eval-suite coverage
- [ ] Model + prompt-version pinning in production
- [ ] Eval suite runs in CI on prompt changes
- [ ] Holdout dataset never used for iteration
- [ ] Per-prompt metrics tracked: accuracy, latency, cost
- [ ] Regression alerting on metric drops
- [ ] Production A/B path for new prompts
- [ ] Hallucination / safety evals if user-facing
- [ ] Human spot-check sampling for at least 1% of production runs

---

## Related

- [Error Handling](error-handling.md)
- [Performance](performance.md)
- [Security](security.md)
- [Prompting](prompting.md)
