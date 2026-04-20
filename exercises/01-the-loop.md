# Exercises — Module 01: The agent loop

## 1.1 — Build the minimal loop

Implement the 10-line loop from Module 01 against a real LLM API. Add
one tool: `get_time() -> str` returning the current ISO timestamp.
No frameworks; raw SDK only.

**Done when:** you can run `python loop.py "what time is it?"` and get
a sensible answer after one tool call.

## 1.2 — Break it, then fix it

Add a tool `recurse_forever()` whose handler always returns
`"please call recurse_forever() again"`. Run your harness. Observe.

Then:
- Add a max-turns guard.
- Add a wall-clock guard.
- Distinguish the stop reasons in your returned result.

**Deliverable:** the broken run log, the fixed code, and a one-paragraph
reflection on how you would catch this in code review before a repeat.

## 1.3 — Error shaping

Add `flaky_network()` that fails with `ConnectionError` 30% of the
time. Implement two variants:

- **Swallow**: the harness retries up to 3 times silently.
- **Surface**: the harness immediately returns the error as a tool
  result to the model.

Run 20 queries under each. Which gets better final outputs? Under what
conditions would the answer flip?

**Deliverable:** numbers, plus a paragraph explaining them.

## 1.4 — Streaming and cancellation

Convert your loop to stream responses. Add a cancellation token checked
between streamed chunks. Demonstrate Ctrl-C cleanly aborting a mid-
generation run.

**Deliverable:** a short demo video or terminal transcript.

## 1.5 — Loop topologies

Read one paper for each of: ReAct, Plan-and-Execute, Reflexion,
Tree-of-Thoughts. For each, write 3 sentences: what it is, when you'd
use it, why you would not.

**Deliverable:** a 12-sentence note.
