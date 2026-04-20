# Exercises — Module 07: Evaluations

## 7.1 — Build a ten-case suite

Pick a harness (yours or the capstone). Write 10 eval cases across
three types: three golden (exact trace / output match), three rubric
(with an LLM-as-judge), four task-success (with side-effect checks).

Run them. Which are flaky? Why?

**Deliverable:** the suite + a flake analysis.

## 7.2 — Calibrate an LLM judge

Label 20 cases by hand (rubric-scored). Build an LLM-as-judge prompt.
Compare judge scores to human scores. Adjust the prompt until
agreement is ≥80%. Document the prompt and the disagreements.

**Deliverable:** prompt, agreement numbers, disagreement analysis.

## 7.3 — Replay

Implement a trace recorder and replayer. Record 10 real sessions,
save them, then re-run through your current harness.

- How many behave identically?
- Among those that do not, what changed?

**Deliverable:** replay tool + analysis.

## 7.4 — Hold-out set

Split your eval set into "dev" and "held-out" (80/20). Iterate on
your harness using only dev scores. Every 5 iterations, peek at
held-out. Plot the gap. Observe overfitting.

**Deliverable:** plot + reflection.

## 7.5 — Regression CI

Wire your eval suite into CI. Failing evals block merges. Add a
"flake quarantine" so known-flaky cases report but do not block.

**Deliverable:** CI config + a pull request that is correctly
blocked by the evals.
