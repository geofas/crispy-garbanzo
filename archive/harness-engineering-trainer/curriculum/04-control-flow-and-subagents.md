---
title: "Module 04 — Control flow and subagents"
parent: Curriculum
nav_order: 4
---

# Module 04 — Control flow and subagents

## Goals

By the end of this module you should be able to:

1. Decide when to use a subagent instead of a tool.
2. Design an agent graph (router → specialist → critic → aggregator) and
   justify each edge.
3. Reason about budgets, isolation, and information flow in multi-agent
   systems.

## 1. Beyond the single loop

Module 01's `while` loop is one agent doing one thing. Real systems are
rarely that simple. Three forces push you toward multi-agent control
flow:

1. **Specialization.** Different sub-tasks want different system prompts,
   tool sets, or even different models.
2. **Context isolation.** A research sub-task can produce a lot of noise
   you do not want polluting the parent's context.
3. **Parallelism.** Independent branches can run concurrently.

The unit of decomposition is the **subagent**: another loop, with its own
prompt, tools, and budget, invoked by the parent.

## 2. Subagent vs. tool: the decision

This is a choice that confuses newcomers. When should a capability be a
tool versus a subagent?

| Use a **tool** when | Use a **subagent** when |
|---|---|
| The operation is a single deterministic action | The operation itself requires reasoning |
| Input and output are well-structured | The work is open-ended or exploratory |
| Latency must be low | Latency tolerance is higher |
| No intermediate LLM reasoning is needed | Multiple LLM steps are needed inside |
| Output fits cleanly in the prompt | Output would overwhelm the parent context |

A subagent is worth its cost when it both (a) needs to reason and (b)
can return a compressed result that is cheaper than the raw trace.

Example: "search the codebase for auth logic and summarize it."

- As a tool: one shot, returns raw search hits. Parent has to read and
  filter. Parent context grows by megabytes.
- As a subagent: the child does the search, the filtering, the reading,
  the summarization. Parent gets a paragraph back. Parent context grows
  by a paragraph.

The subagent paid for itself if the compression ratio outweighs the
extra model calls.

## 3. Agent graphs

Multi-agent systems form a directed graph. Common shapes:

### Router + specialists

```
          user
           │
           ▼
      ┌─router─┐
      │        │
      ▼        ▼
  specialist specialist
```

The router is a small, fast classifier agent (or even a rule) that picks
a specialist. Specialists have tuned prompts and focused tool sets.
Great for support, triage, workflow automation.

### Critic / reflexion

```
worker → critic → worker (retry with critique) → done
```

A second agent examines the first's output and either approves or asks
for revision. Improves quality at the cost of turns. Works well for
writing, code review, plan-quality checking.

### Plan / execute

```
planner → step 1 → step 2 → ... → done
```

The planner produces a structured list of steps; a fresh agent (or
subagent per step) executes each. Good for long horizons; careful about
plan staleness.

### Map-reduce

```
         dispatcher
        /    |    \
  worker  worker  worker
        \    |    /
         reducer
```

Fan out independent sub-tasks (read 50 files, summarize each), then
reduce (combine summaries). The canonical way to parallelize.

### Hierarchy

Subagents with their own subagents. The Claude Code Explore agent is an
example: it spawns further tool calls and returns a summary to the
parent. Hierarchies go as deep as your budgets allow.

Real systems combine these: a router selects a planner, which invokes a
map-reduce over workers, each of which uses a critic. Drawing the graph
is genuinely the first step; do it on a whiteboard before you code.

## 4. Information flow

The most important property of a subagent is: **the parent does not see
the child's context, only its result**. This is a feature, not a bug —
it is precisely why subagents exist. But it has consequences:

- The parent must brief the child **self-sufficiently**. The child starts
  cold. Everything it needs — file paths, the user's intent, relevant
  constraints — must be in the dispatch prompt. Writing good subagent
  prompts is a skill in itself.
- The child's return must be **compressed**. A subagent that dumps
  500 KB of raw tool output into the parent defeats the purpose. Specify
  what the child should return, in what format, and at what length.
- The parent cannot **interrupt** the child mid-stream in the simple
  case. Plan for this: give the child a budget and let it finish or
  abort itself.

A useful discipline: before calling a subagent, write its prompt as if
you were writing a ticket for a new hire who has not seen this project.
Context, goal, constraints, expected output format. If you cannot produce
that brief, the subagent is probably not ready.

## 5. Budgets and backpressure

A subagent is a budget-consuming thing. Parents must allocate:

- **Max turns** the child can run.
- **Max tokens** (input and output).
- **Max wall-clock**.
- **Max tool calls**.
- **Max sub-subagents** (depth limit).

Without these, a runaway child drains the parent's budget. Treat budgets
as capabilities: children spend what they are given and cannot ask for
more without the parent's approval.

A pattern worth learning: **escrow**. The parent reserves a budget
slice, passes it to the child, and reclaims the unused portion on
return. Implemented carefully, this prevents both runaway consumption
and premature termination.

## 6. Concurrency

When subagents are independent, run them concurrently. The gains can be
dramatic: a 5-way parallel research agent can finish in the time of one.

Pitfalls:

- **Rate limits.** Five concurrent calls will hit API rate limits faster
  than one. Implement a semaphore at the harness level.
- **Ordering.** If the parent appends child results in completion order,
  behavior will be non-deterministic. Append in dispatch order or
  explicitly sort before feeding to the parent.
- **Error handling.** If one child fails, do the others matter? Usually
  yes; return partial results. Sometimes no; cancel the rest. Decide
  per-graph-edge.
- **Shared writes.** Two children writing the same file is a race. Make
  writes go through a single serializing agent or use a mutex.

## 7. When a state machine is better

For high-stakes, regulated, or well-understood workflows, free-form
agent loops are overkill. A state machine gives you:

- Auditable transitions.
- Per-state prompt and tool scopes.
- Deterministic rollback on failure.
- Clean separation of policy ("what states exist") from behavior
  ("how does the model reason within a state").

Use a state machine when:

- The task has well-known phases.
- Regulators or stakeholders demand auditability.
- The cost of a wrong state transition is high.
- You need to resume a partially-complete run without re-running
  earlier states.

Use a free loop when:

- Flexibility matters more than auditability.
- The task is exploratory.
- You cannot enumerate the states in advance.

Hybrid systems — a state machine at the top level, with agent loops
inside each state — are often the sweet spot.

## 8. Control-flow anti-patterns

- **Chatty subagents.** A subagent that calls the parent back with
  clarifying questions usually indicates that the parent's brief was too
  thin.
- **Hierarchies too deep.** Five levels of subagent nesting is almost
  always a sign that the decomposition is wrong. Keep it to two or
  three.
- **Implicit shared state.** If two sibling agents "both read the same
  file," they are coupled in ways the parent cannot see. Make shared
  dependencies explicit, ideally as inputs to the dispatch call.
- **Returning raw traces.** If a subagent returns its entire transcript
  to the parent, you have paid for a subagent and received a tool call.
  Specify the return format.

## Exercises

See [exercises/04-subagents.md](../exercises/04-subagents.md).

1. Convert the research tool from Module 02 into a subagent. Measure the
   parent's context size before and after. Compute the compression
   ratio. When is it worth it?
2. Design a router-specialist system for a help-desk bot. Draw the
   graph. Implement the router as a small prompt and route to one of
   three specialists.
3. Take a working single-agent and add a critic loop. Measure quality
   change and turn count.

## Open questions

- Are subagents a form of recursion? If so, do we have a base case?
  (Budgets are the practical base case, but this is unsatisfying.)
- When two agents disagree, who decides? (Voting? A judge agent? The
  user? This is a live research area.)
- How should agents *negotiate* budgets — not just receive them?
