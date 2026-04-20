# Module 09 — Frontier topics

## Goals

This module sketches the active research edges of harness engineering —
topics where the standard answer is "we do not know yet." Mastering
the preceding modules qualifies you to form opinions here. A subject
matter expert does not need to have the answers to these questions,
but must know the questions exist and who is thinking about them.

## 1. Long-horizon agents

A long-horizon agent works for hours, days, or weeks on a task. The
current best-known harnesses handle at most tens of minutes before
something breaks: context fills, plans drift, goals slip, the agent
loses track of what it was doing.

Research directions:

- **Plan supervision.** A higher-level agent owns the plan; a lower
  agent executes. When the executor's trace diverges from the plan,
  the supervisor notices and corrects.
- **Goal re-grounding.** Periodically re-inject the goal statement
  into the prompt, with a critique of progress so far.
- **Journaling and self-review.** The agent writes a daily summary
  to a journal, which it reads at the start of the next session.
- **Checkpointing.** Persist state explicitly at natural boundaries;
  resume from the last good checkpoint if the agent wanders.

This is the single highest-leverage open problem in harness
engineering. If you solve it, everyone will know your name.

## 2. Computer use and browser agents

Agents that take actions in GUIs (clicking, typing, navigating) raise
all the harness problems to a higher difficulty:

- **Perception.** The tool set includes "take a screenshot" and the
  context includes images.
- **Grounding.** The model must translate "click the Submit button"
  into coordinates reliably.
- **Latency.** Screenshots are large; every turn is expensive.
- **Safety.** The blast radius of "fill out this form" is whatever the
  form does.
- **Brittleness.** Web UIs change; selectors break; the agent must
  recover.

Work to follow: Anthropic's computer-use API, Browser-use, web agent
benchmarks (WebArena, VisualWebArena), OS-level agent frameworks.

## 3. Multimodal inputs and outputs

Text-only agents are a decreasing share of deployments. Multimodal
harnesses must handle:

- **Image inputs.** Screenshots, diagrams, photos. Higher token cost;
  different caching characteristics.
- **Audio inputs.** Streaming, real-time expectations, transcription
  vs. native audio reasoning trade-offs.
- **Video inputs.** Still early; token cost and latency are the main
  obstacles.
- **Image outputs.** Chart generation, diagram drawing, UI mockups.
- **Audio outputs.** Voice agents; latency SLOs measured in
  milliseconds.

Harness implications: the context manager must reason about
heterogeneous token budgets. The eval story gets harder (how do you
golden-match an image?). The prompt cache story gets harder (binary
content hashes differently).

## 4. Self-improvement and continual learning

Current agents do not learn *across* sessions without explicit memory
write. Active research:

- **Memory systems.** Episodic, semantic, procedural memory (Module 03).
- **Experience replay.** The agent retrieves past traces relevant to
  the current task and uses them as few-shot examples.
- **Fine-tuning on traces.** The harness generates training data for
  supervised or preference fine-tuning. This blurs the line with
  model training but is a harness decision (which traces to select,
  which to label).
- **Online evaluation.** The harness evaluates its own outputs and
  surfaces the failures as training signal.

Expect this to grow fast. The harness that produces good training data
for its own model improvement is the harness that compounds.

## 5. Cost and latency optimization

Frontier work on making agents cheaper and faster:

- **Speculative execution.** Predict tool calls or outputs with a
  cheap model; verify with the expensive one. Accept the cheap one's
  answer if they agree.
- **Model cascades.** Try a cheap model first; escalate to an
  expensive one only if confidence is low.
- **Cache hierarchies.** Prefix caching, response caching, embedding
  caching, tool-result caching. Each with different invalidation
  policies.
- **Request coalescing.** Multiple concurrent agents asking the same
  question are served from one underlying call.
- **Inference-time compute routing.** Different parts of a task
  routed to different model sizes; the coordinator itself is tiny.

These optimizations often have cost-quality trade-offs; evals keep
you honest.

## 6. Multi-agent coordination

Beyond a handful of hand-designed agents: dozens, hundreds, maybe
thousands of agents coordinating in open-ended ways. Real use cases:

- Market simulations.
- Red-team / blue-team security exercises.
- Scientific research swarms.
- Organization-wide automation with agents per role.

The hard questions: coordination protocols, trust, reputation,
conflict resolution, resource allocation, emergence of unintended
behaviors. These are distributed-systems problems with non-
deterministic actors. The closest analog is multi-agent reinforcement
learning, but the solutions do not transfer cleanly.

## 7. Evaluation at scale

Current eval practice assumes you can review each case. At scale, you
cannot. Open problems:

- **Unsupervised drift detection.** Notice that the agent is
  behaving differently without labels.
- **Synthetic eval generation.** Use models to generate eval cases
  that expose real failures. Hard to calibrate.
- **Failure taxonomy mining.** Cluster failing traces into a small
  set of categories automatically. Half-solved.
- **Production A/B power.** With noisy metrics, how much traffic do
  you need to detect a 1% improvement? Often more than you have.

## 8. Safety at scale

- **Model deception.** As models get better, they can produce answers
  that look right but are subtly wrong in ways humans struggle to
  notice. The harness must not blindly trust.
- **Jailbreak-proof harnesses.** Containment regardless of model
  compromise.
- **Alignment drift.** The agent's behavior shifts as its memory
  grows; how do we detect when it has drifted from spec?
- **Trust boundaries across agents.** When agents from different
  organizations cooperate, whose policies apply?

## 9. Economics and reliability

- **Why does the same harness cost 3x more some weeks than others?**
  (Prompt drift, cache invalidation, upstream latency variance.)
- **How do we price an agent product that has non-deterministic
  cost?**
- **What are the right SLOs for agents?** (P50 latency is easy; "P95
  task success" is a newer concept.)
- **How do we do capacity planning?** The input distribution drives
  token cost; traffic spikes create cost spikes.

## 10. Research frontier reading

You do not need to read everything; you need to know where to look.

- **arXiv cs.CL, cs.AI, cs.SE** for the weekly flood.
- **Anthropic's research publications and engineering blog.**
- **OpenAI's technical papers and cookbooks.**
- **DeepMind / Google's agent papers.**
- **Open-source harness codebases.** Read them, warts and all.
- **Conference papers from ACL, NeurIPS, ICLR, ICML, EMNLP** that
  focus on agents and tool use.
- **Industry postmortems and case studies** when teams publish them —
  the cautionary tales compound fastest.

## 11. What a subject-matter expert does next

You cannot keep up with everything. Pick one of:

- **A frontier topic.** Pick one from this module. Go deep. Write.
  Publish.
- **A platform.** Build the internal harness platform at your
  organization. Feel the pain points and solve them.
- **A vertical.** Specialize in coding, customer support, finance,
  research, or another domain, and become the person who knows how to
  harness agents in that vertical.
- **A primitive.** Build the best version of one subsystem — the best
  compactor, the best permission engine, the best replay tool.

Each of these is a legitimate career in harness engineering.

## Exercises

See [exercises/09-frontier.md](../exercises/09-frontier.md).

1. Pick a frontier topic from this module. Write a three-page
   literature review. Cite primary sources only.
2. Identify an open problem from this module that you could make
   progress on in a weekend. Try. Report what you learn, even if it
   is "this is harder than I thought."
3. Interview someone who works on agents at a different company about
   the hardest problems they face. Compare to what this module listed.
   Update your mental model.

## Open questions

Everything in this module is an open question. That is what makes
them frontier topics. If they get solved, we will write Module 11.
