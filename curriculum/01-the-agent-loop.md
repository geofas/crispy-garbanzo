# Module 01 — The agent loop

## Goals

By the end of this module you should be able to:

1. Write an agent loop from scratch in under 50 lines.
2. Name the major loop variants (ReAct, plan-and-execute, reflexion, etc.)
   and describe when each is appropriate.
3. Enumerate the failure modes of a naive loop and explain how each is
   mitigated.

## 1. The minimal loop

Strip away every feature and the agent loop is astonishingly simple:

```python
def run(model, tools, user_message):
    messages = [{"role": "user", "content": user_message}]
    while True:
        response = model.complete(messages, tools=tools)
        messages.append({"role": "assistant", "content": response.content})
        if response.stop_reason == "end_turn":
            return response
        tool_results = [dispatch(tc, tools) for tc in response.tool_calls]
        messages.append({"role": "user", "content": tool_results})
```

Read it closely. Everything a harness does is either (a) a modification of
this loop, (b) something that runs around this loop, or (c) something that
runs *inside* `dispatch`.

If you cannot write this loop from memory, stop and practice until you can.
Everything downstream assumes fluency with this ten-line object.

## 2. Where naive loops fail

A loop written exactly as above will, in production, exhibit every one of
the following pathologies within its first thousand conversations:

| Failure mode | What happens | Fix introduced in |
|---|---|---|
| Infinite loop | Model keeps calling tools forever | Max-turns guard (§3) |
| Context overflow | `messages` grows past the window | Module 03 |
| Flaky tool errors | One 500 response poisons the trace | Retries + error shaping (§4) |
| Silent hallucinated tool | Model invents a tool name | Schema validation (§5) |
| User wants to interrupt | No way to break in | Streaming + cancel (§6) |
| Cost blow-up | Every turn re-sends the full history | Prompt caching (Module 03) |
| No audit trail | Nobody can debug what happened | Hooks (Module 05) |

A production-grade loop is the minimal loop plus a fix for each row of that
table. "Production-grade" is not a moral quality — it is a checklist.

## 3. Termination: the first hard problem

A loop needs stopping conditions. There are three:

1. **Model says stop.** The API returns `stop_reason="end_turn"` (or
   equivalent) and no tool calls. Respect this; the model believes it is
   done.
2. **Budget exhausted.** Max turns, max tokens, max wall-clock, max tool
   calls. Every budget should be explicit.
3. **External signal.** User cancel, supervisor abort, policy violation.

Good harnesses separate these three. The response you return to the caller
should distinguish "done" from "ran out of turns" from "was cancelled";
downstream code cares about the difference.

### A subtlety: partial termination

Sometimes only *one* of several parallel tool calls fails. Does the agent
stop, retry just that tool, or continue with partial results? There is no
universal answer — it depends on whether tool calls are independent
(probably continue) or sequenced (probably stop). Make the choice
explicit in the tool schema or harness config.

## 4. Error handling in the loop

Tools fail. Networks blip. File systems throw. The loop must decide:
retry, return the error to the model, or abort.

Rule of thumb:

- **Deterministic, retryable errors** (rate limit, 503, network timeout):
  retry with exponential backoff, up to a small N. Hide from the model.
- **Semantic errors** (file not found, SQL syntax, permission denied):
  *surface to the model as a tool result*. The model can often recover —
  it may have typo'd the filename, it may try a different path. Let it.
- **Catastrophic errors** (tool handler crashed, OOM, disk full): propagate
  up. The agent cannot fix infrastructure failures.

A remarkable amount of agent reliability comes from disciplined error
shaping. A good error message to the model is:

```
File not found: /etc/paswd
Hint: did you mean /etc/passwd?
Available files in /etc: passwd, hosts, fstab, ...
```

A bad one is `FileNotFoundError: [Errno 2]`. The bad one causes the model
to retry the same path; the good one causes it to self-correct.

## 5. Schema enforcement

The model does not know what tools you have — it only knows what you told
it in the tool schema. When it calls a nonexistent tool, or passes the
wrong arguments, you have a choice:

- **Reject silently and crash.** Never do this.
- **Return a structured error to the model.** This is correct. Include the
  list of valid tools, the missing/unexpected arguments, and a hint.

Most harnesses validate tool calls against JSONSchema before dispatching.
This catches wrong types, missing required fields, and unknown tools.
Validation errors are then shaped as tool results and fed back.

## 6. Streaming and cancellation

Streaming is not just a UX polish. It is the foundation of *cancellation*:
you cannot interrupt a completed response. A production loop:

- Streams every model response.
- Has a cancellation token checked between tokens, between tool calls,
  and around the SDK call itself.
- Treats cancellation as a first-class stop reason distinct from errors.

Harnesses that skip this get permanent "the agent is frozen — kill -9 is
my only option" tickets.

## 7. Loop topologies beyond `while`

The minimal loop is ReAct (Reason + Act) in disguise. Other patterns you
should know:

### Plan-and-execute

Two phases: first the model produces a plan (as text), then the harness
iterates over plan steps, calling the model to execute each. Good for
long horizons where drift kills a single-loop agent. Bad when plans need
to change mid-flight (they usually do).

### Reflexion

After each attempt, the model critiques its own output and the harness
re-runs. A form of *iterative refinement*. Adds turns, but can rescue
near-misses.

### Tree / graph search

The harness explores multiple continuations in parallel (different
initial tool calls, different system prompts), scores them, picks a
winner. Examples: Tree of Thoughts, Language Agent Tree Search. Expensive
but powerful for hard problems where the first path often fails.

### Debate / multi-agent

Several agents with different prompts argue; a judge or aggregator
decides. Popular in research, rarer in production because of cost and
coordination complexity.

### State machine

Not a free-form loop at all. The harness defines explicit states
(intake, triage, resolve, handoff) and the model only picks transitions
within the legal state graph. Trades flexibility for auditability;
excellent for regulated domains.

Most real systems combine these: a state machine at the top, ReAct
within each state, reflexion on the output before state transition. Good
harness engineers treat loop topology as a design variable, not a default.

## 8. Evaluating a loop in isolation

Before blaming the model for bad behavior, instrument the loop. Useful
invariants:

- Every tool call has a matching tool result.
- Every model turn has `stop_reason` in the set you expect.
- No two consecutive assistant turns without an intervening tool result.
- Total turns ≤ configured max.
- Wall-clock per turn within SLO.

Violations are almost always harness bugs, not model bugs. Fix the harness
first.

## Exercises

See [exercises/01-the-loop.md](../exercises/01-the-loop.md). Key tasks:

1. Implement the minimal loop against a real LLM API, with one tool
   (`get_time`). Make it work end-to-end.
2. Now break it: add an `infinite_recursion` tool that always calls
   itself. Observe the failure, then add a max-turns guard.
3. Add a `flaky_network` tool that fails 30% of the time. Implement two
   error-shaping strategies (swallow vs. surface) and decide which is
   better. Write up why.

## Open questions

- Should the loop be a library or a framework? (Inversion of control is
  a real trade-off.)
- When is a state machine the right shape and when is it premature
  structure? There is no formula; develop the taste.
- How do loops compose? A subagent is another loop; how should the
  parent loop reason about a child loop's budget?
