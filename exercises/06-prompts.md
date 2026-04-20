# Exercises — Module 06: Prompts for harnesses

## 6.1 — Cut by half

Take a 500-word system prompt (yours, or pulled from an open-source
harness). Build a 10-case eval for it. Cut the prompt by 50% without
losing measurable performance. Document what you cut and why.

**Deliverable:** before/after prompt + eval scores + reflection.

## 6.2 — Layer split

Take a prompt you own. Split it into layers: identity, behavior,
tool-use policy, safety. Put each in its own file. Build a composer
function. Verify nothing regressed.

**Deliverable:** the directory of layers + composition code.

## 6.3 — Catch the silent instruction

Pick one instruction in your prompt you suspect the model is
ignoring. Write an eval that would fail if the instruction were
removed. Run it. If the eval passes either way, you have just
learned something important — write up what.

**Deliverable:** eval code + finding.

## 6.4 — Structured output migration

Take a tool (or endpoint) that currently returns markdown and migrate
it to native structured outputs. Measure the end-to-end reliability
(schema adherence) before and after on 50 queries.

**Deliverable:** numbers.

## 6.5 — Prompt rollback drill

Deliberately ship a regressing prompt to your harness. Roll it back
using only the tooling you have today. Measure time-to-rollback.

**Deliverable:** timing + a reflection on what tooling you wish you
had.
