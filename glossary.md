# Glossary

Terms of art used in this trainer, with enough precision to be useful
and short enough to be memorable.

**Agent.** A system that pursues goals in an environment by taking
actions. In LLM contexts: model + loop + tools + environment.

**Agent graph.** The directed graph of agents and subagents that
collectively perform a task. Roots are user-facing; leaves are usually
tools.

**Agentic retrieval.** Retrieval exposed as a tool the model decides
when to call, as opposed to unconditional RAG.

**Allowlist / denylist.** Permission patterns that allow (or deny)
specific tool calls or arguments. Allowlists are safer where feasible;
denylists catch the obvious bad cases but miss creative ones.

**Blast radius.** The worst-case impact of a tool call or action.
Drives permission design.

**Cache breakpoint.** A marker in the prompt telling the model
provider "hash everything up to here." Lets you skip re-pricing the
static prefix of a long prompt.

**Cancellation token.** A first-class signal the loop checks to know
it should stop. Distinguishes "user aborted" from "model finished" and
from errors.

**Compaction.** Reducing the size of the conversation history to fit
the prompt: summarization, selective retention, sliding window,
hierarchical.

**Context manager.** The subsystem that decides what goes into and
out of each prompt call.

**Context window.** The maximum token count a model can accept in one
call.

**Escrow (budget).** Allocation pattern where a parent agent gives a
child a budget, and reclaims the unused portion.

**Eval (evaluation).** A test case that measures agent behavior.
Golden, rubric, judged, task-success, shadow, A/B.

**Frontier model.** The current most capable model generation from a
given provider. Expect frontier to advance twice a year.

**Golden eval.** An eval that compares output (or trace) to a
pre-recorded expected result.

**Hallucination.** Model output that is confident and wrong. In
agents, often manifests as calling a tool that does not exist or
claiming a file that is not there.

**Harness.** Everything around the model call that turns it into an
agent: loop, tools, prompts, context manager, permissions, hooks,
evals.

**Harness architect.** Someone responsible for the high-level shape of
a harness or multiple harnesses in an organization. An emerging role
as of 2026.

**Harness engineering.** The discipline this trainer is about.

**Hook.** A lifecycle callback that runs around harness events
(pre/post tool, on start/stop, on error). Used for policy, logging,
redaction, telemetry.

**LLM-as-judge.** Using an LLM to score the output of another LLM
call. Scalable but noisy; requires calibration.

**Loop.** The control-flow part of the harness: call model, dispatch
tools, decide when to stop.

**MCP (Model Context Protocol).** An open standard for tool servers.
Lets harnesses discover and call tools over JSON-RPC.

**Permission.** The allow/deny/ask decision for a proposed tool call.
See Module 05.

**Prompt caching.** A provider-side feature that caches the static
prefix of a prompt and bills subsequent calls at a fraction of the
input cost.

**Prompt injection.** An attack in which instructions hidden inside
content the agent reads override the user's intent.

**ReAct (Reason + Act).** The canonical agent loop: the model
alternates reasoning and tool calls until done.

**Reflexion.** A loop pattern where the model critiques its own
output and the harness re-runs.

**Replay.** Re-running a recorded trace through the current harness.
Essential for debugging and regression testing.

**Router.** An agent (or rule set) whose job is to classify an
incoming request and dispatch to a specialist.

**Sandbox.** A runtime boundary (process, container, network policy)
that limits what a tool handler can do, independent of permissions.

**Scratchpad.** External file or store the agent reads and writes as
working memory.

**Shadow traffic.** Running a new version alongside the production
version on the same inputs, comparing outputs without affecting
users.

**Specialist.** A subagent with a tuned prompt and a restricted tool
set, dispatched by a router.

**Stop reason.** Why the loop ended: end_turn, max_turns,
wall_clock, cancelled, error. Surface all of them to callers.

**Subagent.** An agent invoked by another agent. Parent briefs it and
receives a compressed return.

**Task-success eval.** An eval that checks whether a goal was
achieved by verifying side effects or artifacts.

**Tool.** A callable action exposed to the model via a schema.

**Tool registry.** The collection of tools a given agent has access
to, with validation, dispatch, and policy.

**Trace.** The recorded log of a run — prompts, responses, tool
calls and results, metadata. The unit of debuggability.
