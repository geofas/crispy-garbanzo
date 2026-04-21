---
title: "Exercises — Module 09: Frontier topics"
parent: Exercises
nav_order: 9
---

# Exercises — Module 09: Frontier topics

## 9.1 — Literature review

Pick one frontier topic from Module 09 (long-horizon agents, computer
use, memory systems, multi-agent coordination, eval at scale, etc.).
Write a three-page literature review of primary sources (papers,
technical blog posts by the people doing the work). No secondhand
summaries.

**Deliverable:** three pages with a citation list.

## 9.2 — Weekend attempt

From your chosen topic, pick an open sub-problem that looks tractable
in a weekend. Try. Expect to fail. Write up what you tried, what you
learned, and what you would try next if you had another week.

**Deliverable:** the attempt + the post-mortem.

## 9.3 — Interview

Find someone who works on agents at a different organization.
Interview them about the hardest problems they currently face. Compare
to Module 09. Update your mental model of the field. Save the
"before" and "after" notes.

**Deliverable:** the interview notes and the delta.

## 9.4 — Model cascade

Implement a cheap-then-escalate cascade: try a small model first, fall
back to a larger model if a confidence check fails. Measure cost and
quality on a 30-case eval. Does it beat the large model alone at
equivalent quality?

**Deliverable:** results.

## 9.5 — Persistent memory

Add a persistent memory file (simple JSON) that your harness reads at
start and writes to at end. Run it across 5 sessions on related
tasks. Does session N benefit from sessions 1..N-1? How did memory
drift?

**Deliverable:** traces + analysis.
