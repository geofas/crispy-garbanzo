# Exercises — Module 00: Foundations

## 0.1 — Harness archaeology

Pick an agent product you use (Claude Code, Cursor, ChatGPT with tools,
a customer support bot). Write a 1-page description of its harness using
the subsystem diagram from the module. Which subsystems are *visible* to
you as a user? Which are you *inferring*?

**Deliverable:** one page, with the subsystem diagram annotated.

## 0.2 — Defend a definition

Write a one-paragraph definition of "harness engineering" that you would
defend in a job interview. Underline the words you expect to be
challenged on. Save this; revisit it after Module 10.

**Deliverable:** one paragraph, dated.

## 0.3 — Same model, different harness

Describe two hypothetical products that could be built with the same
base model but different harnesses, such that one is dramatically
better than the other at its task. Identify at least five harness-level
differences that explain the gap.

**Deliverable:** two paragraphs.

## 0.4 — The subsystem audit

For each subsystem in the trainer's diagram (loop, context manager,
prompt build, model client, tools, permissions, hooks, evals):

- One sentence: what a novice team usually gets wrong.
- One sentence: the symptom that wrongness produces in production.
- One sentence: the fix.

**Deliverable:** a 24-line document. Brevity is the point.
