---
title: "Exercises — Module 08: Architecture patterns"
parent: Exercises
nav_order: 8
---

# Exercises — Module 08: Architecture patterns

## 8.1 — Reverse-engineer an architecture

Pick a real agent product. Write a one-page description of its
architecture, inferred from its behavior and any public docs.
Identify the shape (Module 08 §2), the product surface, and at least
two trade-offs you think the team made.

**Deliverable:** one-page architecture doc.

## 8.2 — Greenfield design

You are the harness architect for a new agent that operates on a
corporate inbox (reads new email, drafts replies, flags urgent
items). Produce:

- A chosen architectural shape, with rationale.
- The agent graph.
- A list of the first five tools.
- The first three safety rails.
- The first three evals you would build.

**Deliverable:** a design doc.

## 8.3 — Compare shapes

Pick a task. Implement it two ways: single-agent loop, and
router+specialists. Compare on a 20-case eval: cost, latency,
quality, code complexity.

**Deliverable:** the two implementations and a comparison writeup.

## 8.4 — Observability from zero

Take a harness that has only print-statements. Add:

- OpenTelemetry tracing with spans for model calls and tools.
- Structured logs per turn.
- A metric for task success, cost, latency, per-tool error rate.
- A local dashboard (anything — Grafana, a spreadsheet).

**Deliverable:** code + screenshot.

## 8.5 — Migration drill

Your provider deprecates your model and you need to migrate. Without
having access to a real deprecation, simulate one: switch models,
see what breaks, fix, document. Now write the playbook you wish you
had had.

**Deliverable:** the playbook.
