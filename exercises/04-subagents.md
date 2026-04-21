---
title: "Exercises — Module 04: Control flow and subagents"
parent: Exercises
nav_order: 4
---

# Exercises — Module 04: Control flow and subagents

## 4.1 — Subagent vs. tool

Take an existing tool that produces a long free-form output (e.g., a
web scraper or a file-read tool over a large file). Convert it into a
subagent that returns a compressed summary.

Measure:

- Parent context size at turn N under each approach.
- Total cost.
- Task-success rate on a 10-case eval.

When is the subagent worth it?

**Deliverable:** results + recommendation.

## 4.2 — Router + specialists

Design a router for a help-desk bot with three specialists:
technical, billing, account. Implement it. Route 50 real (or
realistic) tickets. Measure routing accuracy.

**Deliverable:** confusion matrix + one paragraph on the hardest
misclassifications.

## 4.3 — Critic loop

Take a writing task (e.g., "write a PR description for this diff").
Add a critic subagent that reviews the worker's output and requests
revisions. Cap revisions at 3.

Run on 20 examples. Is quality higher? At what cost?

**Deliverable:** numbers.

## 4.4 — Budget negotiation

Implement an escrow budget system: parent allocates N turns to
child, child returns unused portion. Demonstrate that a runaway
child cannot starve the parent.

**Deliverable:** code + a deliberately-runaway test case.

## 4.5 — Graph review

Take a multi-agent system from the open-source world (or design one
on paper). Draw its agent graph. Identify one simplification and one
elaboration that would make sense. Defend both.

**Deliverable:** diagram + analysis.
