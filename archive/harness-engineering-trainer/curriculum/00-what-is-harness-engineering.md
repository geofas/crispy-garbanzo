---
title: "Module 00 — What is harness engineering?"
parent: Curriculum
nav_order: 0
---

# Module 00 — What is harness engineering?

## Goals

By the end of this module you should be able to:

1. Define *harness*, *agent*, and *harness engineering* precisely enough to
   disagree productively with someone else's definition.
2. Name the subsystems of a typical harness and explain what each one does.
3. Argue — with examples — why two teams using the same model can produce
   agents that differ wildly in quality.

## 1. The vocabulary

**Model.** A fixed artifact: weights that, given a prompt, produce a
distribution over next tokens. Stateless in the theoretical sense; any
"memory" the model appears to have was put into the prompt by something
outside the model.

**Agent.** A system that *pursues goals* by taking actions in an environment.
In the LLM world, an agent is typically: (model) + (loop) + (tools) +
(environment). The "agent" is the whole system, not the model.

**Harness.** The code, data, and policy that wrap the model to produce an
agent. It is everything an engineer can change without retraining.

**Harness engineering.** The discipline of designing, building, operating,
and improving harnesses. Harness engineering is to agents what operating
systems are to programs: the unglamorous substrate that decides whether
everything above it works.

You will see "scaffold," "runtime," "agent framework," and "controller" used
as near-synonyms for harness. Whichever word a given author picks, the
referent is the same: the code around the model.

## 2. Why it is becoming its own field

Three forces are driving harness engineering into its own niche:

1. **Capability overhang.** Frontier models can already solve many tasks
    *in principle*. The gap between the model's best possible output and
    what you actually get in production is dominated by harness quality.
    Teams that prompt-and-pray leave enormous capability on the table.

2. **Agent economics.** Latency, cost, and reliability of a multi-step agent
    are determined more by routing, caching, and control flow than by which
    model you pick. A well-architected harness on a mid-tier model often
    beats a naive harness on a frontier model, at a tenth the price.

3. **Safety surface area.** The moment an LLM can execute code, send email,
    or move money, the safety story shifts from "what does the model say"
    to "what does the system do." That is a systems-engineering problem,
    and the harness is where you solve it.

Expect the title "Harness Architect" to appear on job postings by 2027. You
heard it here first.

## 3. The subsystems of a harness

There is no canonical taxonomy yet. The one below is the spine of this
trainer; every module elaborates one or two of these subsystems.

```
┌──────────────────────────────────────────────────────┐
│                     H A R N E S S                    │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐    │
│  │   Loop   │◄─┤ Context  │◄─┤   Prompt build   │    │
│  └─────┬────┘  │ manager  │  └──────────────────┘    │
│        │       └──────────┘                          │
│        ▼                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐    │
│  │  Model   │─►│  Tools   │─►│   Permissions    │    │
│  │  client  │  │ registry │  │   & sandbox      │    │
│  └──────────┘  └──────────┘  └──────────────────┘    │
│        │            │                │               │
│        ▼            ▼                ▼               │
│  ┌──────────────────────────────────────────────┐    │
│  │                   Hooks / telemetry          │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │         Evaluations & replay                 │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

- **Loop.** The control flow that calls the model, dispatches tools, and
  decides when to stop. Usually a `while` loop, though "usually" is doing
  heavy lifting; see Module 04.
- **Context manager.** Decides what goes into the prompt each turn:
  system prompt, history, tool results, retrieved documents, scratch files.
  Also decides what to *drop* when the window fills up.
- **Prompt build.** The mechanics of producing a valid request: rendering
  templates, attaching tool schemas, applying caching breakpoints.
- **Model client.** The SDK call, with retries, streaming, timeouts.
- **Tools registry.** The set of actions the model can invoke, their
  schemas, and the code that runs when they are called.
- **Permissions & sandbox.** What the agent is allowed to do, under what
  conditions, and how that is enforced.
- **Hooks / telemetry.** Interception points — lifecycle events where
  logging, interception, or behavior-modification code runs.
- **Evaluations & replay.** How you know the harness is getting better,
  not worse.

Every harness has all of these, whether its authors recognize them or not.
Part of the craft is making the subsystems explicit so they can be tuned
independently.

## 4. Harness engineering vs. neighboring disciplines

| Discipline | Primary object | Harness engineering overlap |
|---|---|---|
| Prompt engineering | One prompt / one call | Prompts are inputs to the harness. Harness engineering studies how prompts are *assembled and reused*. |
| Model training / RLHF | Model weights | Out of scope here, but harness choices (tools, action space) inform training data. |
| MLOps | Model deployment infra | Overlaps heavily around evaluation, observability, rollout. |
| Software architecture | All software | Everything from Fowler still applies; agents just add non-determinism. |
| Traditional automation (RPA, workflow) | Deterministic pipelines | Harnesses often *replace* these, but borrow ideas (idempotency, retries). |

## 5. A case study in variance

Two teams receive identical specs: build an agent that triages incoming
customer-support tickets. Both use the same frontier model.

**Team A** wires the model into a single prompt: "Here is the ticket,
output JSON with priority and category." They ship in a week.

**Team B** builds a harness:

- A router that classifies the ticket into one of three sub-agents
  (technical, billing, account) each with domain-tuned system prompts.
- A retrieval tool hooked to the support KB, with a citation check that
  re-runs the model if the agent claims a fact not present in retrieved
  docs.
- A permissions layer that refuses to let the agent issue refunds above
  $50 without human approval.
- A hook that logs every tool call to a warehouse, plus an evaluation
  harness that replays yesterday's tickets nightly and alerts on
  regressions.
- Prompt caching on the long static portions of the system prompt,
  cutting cost 70%.

Team A's agent hallucinates refunds, loses tickets in edge cases, and is
expensive. Team B's ships with 99% routing accuracy and survives its first
model migration painlessly. *Same model.* The variance is harness quality.

This is the shape of every real-world agent project. The moat — if there is
one — is almost never the model.

## 6. The mental model for this trainer

Throughout the rest of the curriculum, whenever you encounter a technique,
ask yourself four questions:

1. **Which subsystem does it belong to?** (Loop? Context? Tools? Permissions?)
2. **What problem does it solve?** (Cost? Latency? Reliability? Safety?)
3. **What does it cost?** (Complexity, compute, a new failure mode.)
4. **How would I know it's working?** (The evaluation that would catch its
   absence.)

If you cannot answer all four, you do not yet understand the technique well
enough to use it in production.

## Exercises

See [exercises/00-foundations.md](../exercises/00-foundations.md). At
minimum:

1. Pick an agent product you use (Claude Code, Cursor, Devin, a support
   bot, etc.). Sketch its harness using the subsystem diagram above.
   Which subsystems are visible to you? Which are you inferring?
2. Write a one-paragraph definition of "harness engineering" that you would
   be willing to defend in a job interview. Save it; revisit it after
   Module 10 and see how it has changed.

## Open questions

- Is a harness a product of the *model* or the *task*? (Probably both, but
  the ratio matters.)
- Where does the harness end and the application begin? Is the UI part of
  the harness? The database? The user?
- If models become dramatically more agentic, do harnesses get thicker or
  thinner?

Carry these questions into later modules; they do not yet have clean
answers.
