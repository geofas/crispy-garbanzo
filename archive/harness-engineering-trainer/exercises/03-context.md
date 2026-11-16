---
title: "Exercises — Module 03: Context engineering"
parent: Exercises
nav_order: 3
---

# Exercises — Module 03: Context engineering

## 3.1 — Compaction bake-off

Generate a 40-turn conversation (a coding agent on a small task is
ideal). Implement three compaction policies:

- Sliding window of last 8.
- Summarize older, keep last 8 verbatim.
- Hierarchical: rolling summary + per-turn tags + selective retention.

For each, measure: final-answer quality (rubric-judged), input tokens
per turn, cost.

**Deliverable:** table of results + one-paragraph recommendation.

## 3.2 — Caching

Profile your harness's cache hit rate. Reorganize the prompt so
static content moves to the front. Re-measure.

**Deliverable:** before/after cache hit rate and cost per call.

## 3.3 — Agentic retrieval

Build a small corpus (say, 100 chunks of docs). Compare:

- Unconditional RAG: always inject top-K chunks.
- Agentic retrieval: a `search_docs` tool the model decides to call.

Use a 20-case eval. Compare cost, latency, and answer quality.

**Deliverable:** numbers + recommendation.

## 3.4 — External state

Replace in-prompt conversation history with an external file the
agent can read and write via tools. Measure the context size at turn
40. How does this interact with compaction?

**Deliverable:** code + reflection.

## 3.5 — Hybrid search

For a corpus of your choice, build retrieval with: pure BM25, pure
vector, hybrid (with reranking). Measure recall@10 on a hand-labeled
ground truth of 30 queries.

**Deliverable:** a chart.
