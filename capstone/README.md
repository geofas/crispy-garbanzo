# Capstone: micro-harness

Starter code for the Module 10 capstone. Each file is a runnable
skeleton; the TODOs mark where you extend it as you progress through
the milestones.

## Layout

```
agent.py       # the loop (Milestone 1)
tools.py       # tool registry and built-in tools (Milestone 2)
context.py     # compaction and caching (Milestone 3)
subagents.py   # router and specialists (Milestone 4)
permissions.py # permission engine (Milestone 5)
prompts/       # layered system prompts (Milestone 6)
evals/         # eval runner and cases (Milestone 7)
trace.py       # logging and replay (Milestone 8)
main.py        # CLI entry point
```

## Running

```bash
pip install anthropic jsonschema
export ANTHROPIC_API_KEY=...
python main.py "your task here"
```

## What is here

Everything you need to implement Milestone 1 exists as stubs with
clear TODOs. Later milestones will require you to add files or
modules; the starter is intentionally small.

## What is not here

- A specific model provider. The code uses the Anthropic SDK as a
  reference; swap for any provider.
- A web UI. The harness is CLI-first.
- Tests or evals. You write those in Milestone 7.

## Hints

- Keep `agent.py` small. If it balloons past 200 lines, you are
  probably missing an abstraction.
- Write tests (or at least a main-block smoke test) as you go, not
  at the end.
- When you get stuck, go back to the module that covers the
  subsystem you are working on. The answers are there.
