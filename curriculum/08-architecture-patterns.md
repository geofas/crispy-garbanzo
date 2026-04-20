# Module 08 — Architecture patterns

## Goals

By the end of this module you should be able to:

1. Recognize the major architectural shapes in production agent
   systems.
2. Choose a shape based on task, team, and operational constraints —
   not fashion.
3. Avoid the "god agent" and other common architectural pitfalls.

## 1. Why architecture matters more than any single technique

So far you have studied subsystems. This module is about what holds
them together. Two harnesses that use the same tools, prompts, and
model can produce wildly different systems based on how the pieces are
composed.

Architecture decisions are the ones you hate to reverse later:

- Monolith vs. multi-agent.
- In-process tools vs. MCP servers.
- Long-running sessions vs. one-shot tasks.
- Stateless loop vs. persistent-memory agent.
- Conversational front-end vs. API-first.

Get these roughly right up front; iterate on the inside freely.

## 2. The canonical shapes

### The single-agent REPL

One loop, one prompt, a tool set, a conversational UI. Examples:
ChatGPT's first incarnation, early coding assistants. Strengths:
simplest to reason about, easy to debug. Weaknesses: scales poorly in
complexity, mixes concerns.

**Use when:** the task is relatively narrow and the user is patient.

### The router + specialists

A small router agent classifies incoming tasks and dispatches to
specialists with tuned prompts and tool sets. Examples: support
triage, workflow automation. See Module 04.

**Use when:** tasks fall into a handful of recognizable buckets.

### The orchestrator + workers

An orchestrator agent plans; workers execute (possibly in parallel).
Results come back and the orchestrator decides what to do next.
Examples: research agents that fan out over sources, ops agents that
investigate incidents.

**Use when:** tasks are decomposable and benefit from parallelism.

### The pipeline / state machine

Explicit stages, each with its own prompt and tool scope; transitions
are deterministic or gated. Examples: regulated document processing,
medical triage flows.

**Use when:** auditability and predictability beat flexibility.

### The persistent / ambient agent

Always on, watching for events (new email, new PR, monitoring alert).
Takes actions when conditions warrant. Examples: on-call co-pilots,
inbox assistants.

**Use when:** the trigger is external, not a user request.

### The hybrid

Most real systems. A state machine on the outside, agent loops inside
each state, subagents within loops. Perfectly fine — just be
intentional about the decomposition.

## 3. The product surface

The architecture is shaped hugely by how users interact with the
system.

- **Chat UIs.** Conversational, low-latency expected, interruption
  support critical. Streaming is mandatory. Long-session memory
  matters.
- **API endpoints.** Typically one-shot. Latency SLOs tight.
  Observability and cost per call matter more than experience.
- **IDEs / editors.** Tightly scoped tools (read/edit files, run
  tests), context grounded in the repo, latency paramount, partial
  outputs welcome.
- **Batch.** Can take minutes or hours. Parallelism at the top level
  matters. Replay and retries matter.
- **Ambient / background.** Triggered by events, not users. Must be
  resilient to absent humans; must surface errors to humans
  eventually.

Each surface demands different trade-offs. Pick the surfaces
explicitly; do not build generically and discover at launch that your
harness does not fit any of them well.

## 4. The platform question

When an organization builds more than one agent, it inevitably faces
the platform question: *do we build a shared harness?*

Cost of building a platform:

- Generalization pressure (the harness must fit several teams).
- Team friction (changes require coordination).
- Onboarding cost (new teams must learn it).

Benefits:

- Shared evals, observability, safety rails.
- Shared tools and prompts.
- Unified compliance and audit posture.

The right time to platformize is after you have two or three agents
and see the duplication, not before. Premature platforms solve the
wrong problems and ossify around them.

Platform harnesses should offer:

- **A loop library** with swappable policies (compaction, retries,
  termination).
- **A tool registry and MCP bridge.**
- **A permission and policy engine.**
- **Observability out of the box** (traces, metrics, replay).
- **An eval runner** with CI integration.
- **A prompt and schema registry** with versioning.

A concrete example to study: Claude Code, as documented in the Anthropic
Agent SDK docs. It is a mature harness and a useful reference; read its
docs end-to-end once, even if you will not use it.

## 5. State and persistence

Agents accumulate state: conversation history, memory, user
preferences, intermediate work products. Architectural choices:

- **Ephemeral in-memory.** Simplest; fine for one-shot tasks.
- **Session store.** Keyed by conversation id; survives restarts.
- **User profile store.** Persists across sessions (preferences,
  memory).
- **Artifact store.** For intermediate work (files the agent edits,
  reports it generated).
- **Event log / trace store.** Append-only record of every turn, for
  replay and audit.

Separate these concerns in storage even if they live in the same DB.
Do not conflate "which chat is this?" with "what has this user always
preferred?" — the lifetimes, access patterns, and privacy stories are
different.

## 6. Observability as architecture

You cannot architect what you cannot see. Modern agent systems need:

- **Distributed tracing.** Each turn is a trace; each tool call a
  span; subagent calls are child traces. OpenTelemetry maps well.
- **Structured logs.** Per-turn records with prompt size, model,
  latency, cost. Queryable.
- **Tracing UIs.** Every production agent team ends up with or
  adopting a trace viewer. Budget for this.
- **Metric SLOs.** Latency, cost, success rate, per-tool error rate,
  cache hit rate. Alert on SLO violations.

Teams that treat observability as "optional polish" ship worse agents.
This is not close.

## 7. Deployment

Agents are stateful, long-running, network-heavy, and cost-variable.
Some implications for deployment:

- **Warm processes.** Cold starts eat latency budgets; keep processes
  warm.
- **Streaming responses.** Gateway and load balancer must support
  server-sent events (or similar). Many default setups do not.
- **Rate limit propagation.** If the upstream model rate-limits you,
  propagate a clear error; do not retry forever.
- **Backpressure.** If a subagent pool is saturated, shed or queue
  gracefully.
- **Cost kill switch.** A runaway agent can incur thousands of
  dollars per hour. Per-user and per-org cost caps.
- **Model rollouts.** You will migrate models (you always do). Build
  shadow-traffic capability from day one so migrations are boring.

## 8. The anti-architectures

### The god agent

One enormous prompt with every tool, every instruction, every piece of
user context. Initially impressive; unmaintainable within months.
Decompose before the sprawl becomes load-bearing.

### The layer cake

Seven abstractions between user request and model call. Each layer
"protects" the one below. The result is that nothing works end-to-end;
every debugging session tours the cake. Fewer, thicker layers with
clear contracts beat many thin ones.

### The agent soup

A dozen agents with shared mutable state, no clear ownership of
decisions, emergent behavior praised as "intelligence" but in practice
unreliable. If you cannot draw the graph on one page, it is probably
the wrong graph.

### The framework trap

Adopting a heavyweight agent framework before understanding the
problem. Frameworks prescribe architecture. If their prescriptions
match your problem, great. If not, you will fight them forever. Learn
the principles first, the frameworks second.

## 9. Migrations

Systems migrate: models change, SDKs change, tool schemas change, MCP
servers change, prompts change. Build for migration:

- **Schema versioning** for tools and outputs.
- **Prompt versioning** with side-by-side eval runs.
- **Trace recording with harness version tagged.** So you can tell
  which harness produced what.
- **Shadow evaluation.** Before cutover, run the new version against
  real recent traffic and compare.
- **Gradual rollout.** Canary → 10% → 50% → 100%, watching metrics at
  each step.

Migrations are where harness engineers prove their value. Bad
harnesses regress; good ones do not.

## Exercises

See [exercises/08-architecture.md](../exercises/08-architecture.md).

1. Take a product you use and reverse-engineer its architecture. What
   shape is it? What trade-offs did the team make? Write it up.
2. Design a new agent from scratch: choose a surface, draw the
   architecture, list the observability you would build, name the
   first three evals.
3. Pair up two architectures for the same task (single-agent vs.
   router + specialists). Implement both minimally and compare cost,
   latency, and quality on a small eval set.

## Open questions

- Is there a useful "reference architecture" for agents, analogous to
  the LAMP stack? (Nothing has won yet; the field has many local
  maxima.)
- How do we design harnesses that migrate across models *without
  regression*? This is an operational and scientific problem.
- What is the right relationship between agent frameworks and the
  model providers that ship their own SDKs? (Currently: awkward.)
