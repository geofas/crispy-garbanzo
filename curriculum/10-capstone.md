---
title: "Module 10 — Capstone: build your own harness"
parent: Curriculum
nav_order: 10
---

# Module 10 — Capstone: build your own harness

## Goals

Build a working harness end-to-end, from empty directory to passing
evals, demonstrating fluency with every subsystem. This is the
exercise that turns "has read about harness engineering" into "has
done harness engineering."

## 1. The assignment

Build **micro-harness**: a CLI agent that can:

- Read and write files in a scoped directory.
- Run shell commands through a sandbox.
- Search the web via a mock tool.
- Route to one of two subagents (`coder`, `researcher`) based on the
  user's request.
- Respect a permission model with `allow | deny | ask` semantics.
- Be driven by an eval harness you also build.

Starter code is in [`../capstone/`](../capstone/). Read it, then
extend it.

You do not need to use the Anthropic SDK specifically — any model
provider is fine — but the starter uses the Anthropic SDK as a
reference. Substitute if you prefer.

## 2. Milestones

Tackle these in order; each milestone references earlier modules.

### Milestone 1 — The minimal loop (Module 01)

- Implement the core `while` loop in [`agent.py`](../capstone/agent.py).
- Add termination: end-turn, max-turns, max-wall-clock.
- Implement streaming and a cancellation token.
- Shape errors: retry transient, surface semantic, propagate
  catastrophic.

**Done when:** you can run `python -m micro_harness "say hello"` and
get a streamed response; you can Ctrl-C mid-stream and it exits
cleanly; a tool that always 500s does not crash the loop.

### Milestone 2 — The tool registry (Module 02)

- Flesh out the tool registry with JSONSchema validation.
- Add tools: `read_file`, `write_file`, `list_dir`, `run_shell`,
  `web_search` (mocked).
- Support parallel tool calls.
- Add versioning metadata.

**Done when:** tools with invalid arguments return structured errors;
parallel tools run concurrently; tool handlers cannot access files
outside the scoped directory.

### Milestone 3 — Context and caching (Module 03)

- Add a compaction policy: keep last K turns verbatim, summarize
  older turns.
- Add prompt caching with cache breakpoints at end-of-system,
  end-of-tools.
- Measure: before/after token count and cache hit rate.

**Done when:** a 40-turn conversation fits in context; a second run
of the same conversation hits cache on the prefix.

### Milestone 4 — Subagents (Module 04)

- Split into router, `coder`, `researcher`.
- Router is a lightweight agent with a tiny prompt.
- Subagents receive a self-sufficient brief and return a compressed
  result.
- Budget each subagent: max turns, max tokens, max wall-clock.

**Done when:** `"fix the bug in foo.py"` routes to coder;
`"summarize the latest news on X"` routes to researcher; the parent
context stays under budget.

### Milestone 5 — Permissions and safety (Module 05)

- Implement a permission layer with `allow | deny | ask`.
- Gate `run_shell` on an argument-level policy (denylist of obvious
  dangers; allowlist of safe patterns).
- Gate `write_file` outside a whitelisted directory.
- Add hooks: pre/post-tool logging, redaction of anything that looks
  like an API key in tool outputs.
- Simulate a prompt injection in a file the agent reads; confirm it
  is contained.

**Done when:** a deliberately-crafted adversarial file cannot cause
writes outside the scope; the permission layer logs every decision
with reason.

### Milestone 6 — Prompts as code (Module 06)

- Split the system prompt into named layers (identity, behavior,
  tool-use policy, safety). Each in its own file.
- Version the layers.
- Add a CLI flag to swap prompt versions for A/B testing.

**Done when:** `git log` on any prompt layer shows its history;
running with `--prompt-version v1` vs. `v2` produces measurably
different behavior.

### Milestone 7 — Evals (Module 07)

- Build an eval runner.
- Write ten eval cases: three golden (exact tool-call trace match),
  three rubric (LLM-as-judge), four task-success (side-effect
  verification).
- Run the suite in CI. Require passing for merges.

**Done when:** `make eval` prints a green scorecard; introducing a
regression (e.g., dropping a permission check) fails the suite.

### Milestone 8 — Observability (Module 08)

- Emit structured logs for every turn and tool call.
- Record a replay-able trace for every run.
- Implement `micro_harness replay <trace_id>` that re-runs a past
  trace through the current harness.

**Done when:** you can `replay` a week-old trace and see whether
today's harness handles it the same or differently.

### Milestone 9 — Architecture review (Module 08)

- Write a one-page architecture doc: the subsystems, their
  interfaces, the decisions you made and rejected.
- Draw the agent graph.
- Identify the three places you would have done it differently on a
  second attempt.

**Done when:** someone who has not read this trainer could read your
architecture doc and modify your harness without getting lost.

### Milestone 10 — Frontier stretch (Module 09)

Pick one:

- Add a second model for cheap-then-escalate model cascade.
- Add a persistent memory file the agent reads on every run and
  writes summaries to at session end.
- Add shadow-traffic comparison: run two versions of the harness
  side-by-side on a fixture set and diff their behaviors.
- Add computer-use: one screenshot tool, one click-at-coords tool,
  and a test harness that drives a headless browser.

Whatever you pick, write up what worked, what did not, and what you
would try next.

## 3. Grading rubric

Grade yourself honestly against this rubric (this is what an
interviewer would use):

| Dimension | 0 (missing) | 1 (present) | 2 (thoughtful) | 3 (excellent) |
|---|---|---|---|---|
| Loop hygiene | No termination | Basic | Handles all three stop reasons | Also handles cancellation and partial termination |
| Tool registry | Ad-hoc | Validates schemas | Structured errors, timeouts, parallelism | Versioning, metrics, MCP-compatible |
| Context mgmt | All-or-nothing | Sliding window | Compaction + caching | Adaptive policy with measurement |
| Subagents | None | One subagent | Router + specialists | Budgets, briefing, compressed returns |
| Permissions | None | Ask-on-everything | Tiered by blast radius | Argument-sensitive, logged, with recovery |
| Prompts | One blob | Layered | Versioned and tested | Separate owners, measured |
| Evals | None | Runs manually | In CI, multiple types | Replay, drift detection, dashboard |
| Architecture | Not drawn | Sketched | Justified decisions | Trade-offs articulated, migration-ready |

A capstone at all 2s is production-grade. Any 3s are bonus points and
show deep engagement.

## 4. Reflection

After the capstone, re-read your Module 00 one-paragraph definition
of harness engineering. Rewrite it. The delta between the two
versions is what you learned. Save both.

## 5. Where to go next

- **Ship it.** Deploy the harness to yourself for a month. Use it
  daily. Take notes on every failure.
- **Read production harnesses.** Claude Code, OpenAI Agents SDK, the
  big open-source options. Read them with the vocabulary you now
  own. Notice what they did and did not solve.
- **Pick a specialty.** See Module 09, section 11.
- **Teach.** Nothing cements understanding like explaining it. Give
  a talk. Write a blog post. Mentor someone through this trainer.

You are now a harness engineer. Welcome to the field.
