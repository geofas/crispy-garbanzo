# Evals (Milestone 7)

Build your eval runner here. Suggested layout:

```
runner.py       # runs a suite of cases, prints scorecard
cases/
  golden/       # trace-match cases (see Module 07 §4)
  rubric/       # LLM-as-judge cases
  task/         # task-success cases with side-effect assertions
judges/
  code_review.py  # rubric judges
fixtures/       # inputs the cases share
```

Minimum requirements to pass Milestone 7:

- 10 cases total across the three types.
- `make eval` (or `python -m evals.runner`) returns non-zero on any failure.
- A held-out set of 3 cases that you touch less often, to catch overfitting.
- Per-case output is deterministic enough to diff between runs (same model
  temperature, recorded tool outputs, seeded randomness).

Hints:

- Start by running real tasks through the harness and saving the traces.
  Convert the best ones into cases.
- Pick failures from your own usage to seed the initial set.
- Do not build a general-purpose eval framework. Build the one you need for
  this harness, kept simple enough to iterate on in a week.
