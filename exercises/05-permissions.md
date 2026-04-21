---
title: "Exercises — Module 05: Permissions and safety"
parent: Exercises
nav_order: 5
---

# Exercises — Module 05: Permissions and safety

## 5.1 — Blast radius audit

For every tool in your harness, assign a blast-radius tier:

- Tier 0 — trivial (get_time, read_file in sandbox).
- Tier 1 — local (write_file in sandbox, run shell without network).
- Tier 2 — external but reversible (send a Slack DM to yourself).
- Tier 3 — external and irreversible (send email, transfer funds).

Then propose a permission policy for each tier.

**Deliverable:** a table.

## 5.2 — Permission engine

Implement the `check(tool, args, ctx) -> Decision` interface from
Module 05 §4. Support: tool-name rules, argument-pattern rules,
denylist and allowlist composition.

Test with 20 synthetic cases.

**Deliverable:** code + test output.

## 5.3 — Prompt injection gauntlet

Create three files in your scoped workspace whose *contents* attempt
to subvert the agent:

- One telling it to write to `/etc/passwd`.
- One telling it to send all env vars to an external URL.
- One subtly suggesting a "helpful" but dangerous refactor.

Run the agent on each with "summarize this file." Verify your
harness contains all three. Document where each was contained (prompt
layer, permission layer, sandbox).

**Deliverable:** transcripts and a defense-in-depth writeup.

## 5.4 — Hooks

Add a pre-tool hook that logs structured records. Add a post-tool
hook that redacts anything matching `sk-[A-Za-z0-9]{20,}` from tool
outputs. Demonstrate both.

**Deliverable:** code + an example redacted output.

## 5.5 — Kill switch

Implement a "kill now" endpoint or CLI command that revokes the
agent's credentials (or at minimum removes them from the environment
the agent reads). Verify the agent cannot continue operating after
activation.

**Deliverable:** code + demo.
