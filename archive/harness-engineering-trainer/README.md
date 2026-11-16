# Harness Engineering Trainer

A self-directed curriculum for becoming a subject-matter expert in **harness
engineering** — the discipline of designing, building, and operating the
scaffolding that turns a language model into a capable agent.

## What is a harness?

A **harness** is everything around the LLM call: the loop that drives it, the
tools it can reach, the prompts that shape its behavior, the context it
remembers, the permissions that constrain it, the hooks that observe it, and
the evaluations that measure it. The model is the engine; the harness is the
car. A better engine is useless without steering, brakes, seat belts, and a
dashboard.

Harness engineering is distinct from prompt engineering (which tunes a single
interaction) and distinct from model training (which changes the weights). It
is the systems engineering of agents.

## Why a new discipline?

For most of the deep-learning era, a "good AI" meant a good model. Harnessing
was an afterthought — a `while` loop and a string template. That is no longer
true. Frontier models now have enough raw capability that *outcome quality is
dominated by the harness*, not the weights. Two teams using the same model
can produce agents that differ by an order of magnitude in reliability,
safety, cost, and latency. The variance lives in the harness.

"Harness architecture" — the higher-level design discipline that shapes
multi-agent, long-horizon, multi-surface systems — is already emerging as the
next rung. This trainer prepares you for both.

## Who this is for

- Engineers building agent products and wanting a principled foundation.
- Researchers who want to understand why the same model behaves differently
  in different agent shells.
- Tech leads evaluating or designing an internal agent platform.
- Anyone who has built "a ReAct loop with some tools" and suspects there is
  a lot more to learn. (There is.)

## Prerequisites

- Comfort writing Python (or TypeScript — examples are in Python but the
  concepts transfer).
- Familiarity with at least one LLM API (Anthropic, OpenAI, Gemini).
- Basic understanding of HTTP, JSON, and shell.
- Willingness to read primary sources (papers, API docs, open-source harness
  code).

## Learning path

| Module | Topic | Est. time |
|---|---|---|
| [00](curriculum/00-what-is-harness-engineering.md) | What is harness engineering? | 1 hr |
| [01](curriculum/01-the-agent-loop.md) | The agent loop | 2 hr |
| [02](curriculum/02-tools-and-tool-use.md) | Tools and tool use | 3 hr |
| [03](curriculum/03-context-engineering.md) | Context engineering | 3 hr |
| [04](curriculum/04-control-flow-and-subagents.md) | Control flow and subagents | 2 hr |
| [05](curriculum/05-permissions-and-safety.md) | Permissions and safety | 2 hr |
| [06](curriculum/06-prompts-for-harnesses.md) | Prompts for harnesses | 2 hr |
| [07](curriculum/07-evaluations.md) | Evaluations | 3 hr |
| [08](curriculum/08-architecture-patterns.md) | Architecture patterns | 3 hr |
| [09](curriculum/09-frontier-topics.md) | Frontier topics | 2 hr |
| [10](curriculum/10-capstone.md) | Capstone: build a harness | 8+ hr |

Total: roughly 30-40 hours for the reading and exercises, plus the capstone.

## How to use this trainer

1. Read each module in order — later modules assume earlier ones.
2. At the end of every module, do the exercises. They are the learning; the
   prose is the setup.
3. Keep a **decision journal** as you go: when you make a design choice in an
   exercise, write down the alternatives you rejected and why. Harness
   engineering is mostly trade-offs, and the journal is your evidence.
4. Consult [glossary.md](glossary.md) when terms are unfamiliar and
   [references.md](references.md) when you want to go deeper.
5. Build the capstone. You do not *know* harness engineering until you have
   shipped a harness, watched it fail, and debugged it end-to-end.

## Repository layout

```
curriculum/     # the modules
exercises/      # hands-on exercises per module
capstone/       # starter code for the capstone harness
glossary.md     # terms of art
references.md   # canonical reading list
```

## A note on humility

This field is five minutes old. Any curriculum written today will be partly
wrong in eighteen months. The goal is not to memorize today's answers — it is
to develop the taste and vocabulary to recognize tomorrow's. Every module
ends with open questions for a reason.
