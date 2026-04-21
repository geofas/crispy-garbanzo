---
title: "Module 03 — Context engineering"
parent: Curriculum
nav_order: 3
---

# Module 03 — Context engineering

## Goals

By the end of this module you should be able to:

1. Explain why context management is the single highest-leverage problem
   in harness engineering today.
2. Implement compaction, retrieval, and scratchpad patterns and know when
   each is appropriate.
3. Use prompt caching intelligently to cut cost by an order of magnitude.

## 1. The central problem

The model has a fixed input budget. Long agent sessions produce more
content than that budget can hold. Everything in this module is a strategy
for deciding what goes into the next model call.

A common mistake: treating the context window as the problem. It is not
the problem. Even with an infinite window, you would still need to decide
what is *useful*, because:

- The model's attention is not uniform across a long prompt. Middle tokens
  get less attention than beginning and end ("lost in the middle").
- Cost scales with input tokens. A 500k-token conversation, re-sent each
  turn, is a budget crater.
- Latency scales with input tokens too.
- Noise actively harms performance: irrelevant content confuses the model.

Context engineering is about *selection*, not *capacity*. Even a model
with a 10M-token window needs it.

## 2. The anatomy of a prompt

A single model call in a typical harness is assembled from:

```
┌────────────────────────────────────────────┐
│ System prompt (static, cache-friendly)     │
│   - identity & persona                     │
│   - task framing                           │
│   - tool-use policy                        │
│   - response-format policy                 │
├────────────────────────────────────────────┤
│ Tool schemas (semi-static)                 │
├────────────────────────────────────────────┤
│ Long-term memory / retrieved docs (dynamic)│
├────────────────────────────────────────────┤
│ Conversation history (accumulates)         │
│   - user turns                             │
│   - assistant turns                        │
│   - tool calls + results                   │
├────────────────────────────────────────────┤
│ Current user turn                          │
└────────────────────────────────────────────┘
```

Each layer has different growth, staleness, and caching properties. A
good context manager addresses each one separately.

## 3. Compaction

When the conversation history gets long, you have to shrink it. Options:

### Sliding window

Keep the last N turns, drop the rest. Simplest, worst. Loses earliest
context, which often contained the task definition. Use only when task
length is bounded.

### Summarization

Periodically ask the model to summarize older turns into a paragraph.
Insert the summary in place of the dropped turns. Good for preserving
intent; bad when detail matters (a summary of a tool result rarely
preserves enough for the agent to reason about it later).

### Hierarchical summarization

Summaries of summaries. Old turns compress more than recent ones. Works
well for long agentic sessions (coding agents, research agents). More
complex to implement; watch for summary drift.

### Selective retention

Tag each turn (user intent, tool call, tool result, reasoning) and keep
tags with different policies: always keep user turns, compress tool
results after 10 turns, drop assistant "thinking" after it is used.

### External memory

Move information *out* of the prompt and into a tool-addressable store
(files, a KV store, a vector DB). The agent calls a tool to retrieve
when it needs the information. This is the highest-leverage pattern for
truly long sessions — and the foundation for multi-session agents. It is
also the hardest to get right, because now the *agent* has to remember
to retrieve.

Real harnesses usually combine these. A good default: keep the last K
turns verbatim, summarize the rest periodically, and dump large tool
outputs (file reads, search results) to files that the agent re-reads
on demand.

## 4. Retrieval

RAG (retrieval-augmented generation) is context engineering's oldest
pattern. The pipeline:

1. Index a corpus (documents, past tickets, code, wiki) into a vector
   store (and/or keyword index).
2. At query time, embed the user's request, retrieve top-K chunks.
3. Inject the chunks into the prompt.

Things that go wrong in production:

- **Chunking is not free.** Naively chopping documents every 512 tokens
  cuts semantic units in half. Chunk by semantic boundaries (sections,
  paragraphs, code functions) when possible.
- **Pure semantic search misses exact strings.** A user asking about
  "error code E401" may fail if E401 never appears in the embedded
  training corpus. Hybrid search (BM25 + vectors) dominates pure vector
  search on most real corpora.
- **Top-K is not a plan.** If the answer is spread across documents,
  K=3 will not cut it. If the query is ambiguous, K=20 will drown the
  model in noise. Reranking after retrieval — with a cheaper model or
  an explicit rule — is often worth it.
- **Stale indexes.** Your index is a copy of the world; the world moves.
  Plan the refresh cycle from day one.

In agent settings, a powerful variation is *agentic retrieval*: expose
retrieval as a tool the model can call zero or more times per turn,
rather than injecting retrieved docs unconditionally. The model decides
whether it needs more context. This is a much better fit for tasks
where the question is not known in advance.

## 5. Scratchpads and external state

The prompt is an expensive place to store information. For structured,
addressable data, write it out:

- **Files on disk** the agent reads and writes. Canonical for coding
  agents.
- **A scratchpad file** where the agent records intermediate plans, TODO
  lists, observations. Can be the single source of truth for long-horizon
  work.
- **A structured store** (SQLite, DuckDB, a KV store) for facts that need
  querying.
- **A "memory" API** with write/read/search tools.

Design principle: *the prompt should contain pointers to knowledge, not
knowledge itself*, whenever the knowledge is large or reusable.

The agent's prompt becomes an index of "here is where stuff is" plus
recent working state. The heavy content lives outside and is pulled in
on demand.

## 6. Prompt caching

Most LLM providers now support **prompt caching**: the static prefix of a
prompt is hashed and cached server-side, and subsequent calls with the
same prefix pay a fraction of the input cost (and latency). This is the
single most effective cost lever in agent harnesses.

How to use it well:

- Order prompts from **most static to most dynamic**. System prompt and
  tool schemas first, conversation last. Every dynamic prefix byte
  invalidates everything after it.
- Place explicit cache breakpoints at stable boundaries (end of system
  prompt, end of tool schemas, end of last stable summary).
- Avoid gratuitous edits to the system prompt. Every A/B test on a
  system prompt word invalidates the cache.
- Consolidate small dynamic strings into one late-in-prompt block rather
  than sprinkling them throughout.

Typical wins: 70-90% cost reduction on long-context agents with heavy
system prompts. Set it up before you need it, not after.

## 7. Long-horizon state: the hardest thing

When sessions span days, weeks, or months — or when a single task spans
thousands of turns — context engineering becomes long-horizon state
management. Research frontier as of 2026:

- **Episodic memory**: per-session memory that summarizes into long-term
  memory at session end.
- **Semantic memory**: extracted facts, user preferences, project
  conventions. Often stored as key-value with TTLs.
- **Procedural memory**: "how to do X here" notes — effectively a prompt
  library indexed by situation.
- **Compression cascades**: multi-level summaries that resemble how human
  memory consolidates.

None of these are solved. They are where most of the interesting harness
engineering research is happening right now. If you want to publish in
this field, pick one and go deep.

## 8. What to drop

A principle for when you have to make room:

1. **Tool inputs and outputs that have already been acted upon** are
   usually safe to drop. The model has incorporated them into its
   reasoning; the raw form is rarely needed again.
2. **"Thinking" blocks** from earlier turns can be summarized aggressively.
3. **Duplicated retrieval results** — if you retrieved the same doc
   three turns ago, you do not need it three times.
4. **Error messages from tools that later succeeded** — keep the
   success, drop the failure once resolved.

Never drop:

- The current user turn.
- The task definition (often embedded in the first user turn).
- Anything the model explicitly referenced in its current reasoning.

A sound heuristic: *if you would not be able to reconstruct the agent's
current plan without it, keep it*.

## 9. Observability for context

You cannot tune what you cannot see. Instrument:

- Prompt size per turn (tokens in system, tools, history, user).
- Cache hit rate per turn.
- Compaction events: when, what was dropped, how much was saved.
- Retrieval recall/precision (you need ground truth for this — build an
  eval set).
- Per-turn cost and latency broken down by input vs. output tokens.

Every serious harness has a context-manager dashboard. If you cannot see
it, you cannot improve it.

## Exercises

See [exercises/03-context.md](../exercises/03-context.md).

1. Implement a compaction policy that keeps the last 8 turns verbatim and
   summarizes older turns as a single paragraph. Test it on a 40-turn
   conversation and compare quality to a sliding window of 8.
2. Take your Module 02 tool registry and add an agentic-retrieval tool
   over a small corpus. Compare against unconditional-RAG.
3. Measure the cache hit rate of your harness. Reorder the prompt and
   see how much you can move. Report the cost delta.

## Open questions

- Should compaction be rule-based or learned? (The answer is probably
  "both," but nobody has a clean architecture yet.)
- How do we represent "the agent does not know X yet" vs. "the agent has
  forgotten X"? These are very different states for reasoning, and most
  harnesses conflate them.
- Where does context engineering end and database engineering begin?
  (Short answer: it does not; get comfortable.)
