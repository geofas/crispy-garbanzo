# References

A canonical reading list for harness engineering. Prefer primary
sources. Skim widely; read the starred items carefully.

## Foundational papers (read these)

- ★ **"ReAct: Synergizing Reasoning and Acting in Language Models"** —
  Yao et al., 2022. The intellectual backbone of the modern agent
  loop.
- ★ **"Toolformer: Language Models Can Teach Themselves to Use
  Tools"** — Schick et al., 2023. An early, still-relevant framing of
  tools as a first-class modality.
- **"Reflexion: Language Agents with Verbal Reinforcement
  Learning"** — Shinn et al., 2023. Where the critic-loop pattern
  became widely known.
- **"Tree of Thoughts: Deliberate Problem Solving with Large Language
  Models"** — Yao et al., 2023. Search as a loop topology.
- **"Voyager: An Open-Ended Embodied Agent with Large Language
  Models"** — Wang et al., 2023. Long-horizon, self-directed agents.
- **"Large Language Models as Tool Makers"** — Cai et al., 2023. The
  agent as its own tool author.
- **"Lost in the Middle: How Language Models Use Long Contexts"** —
  Liu et al., 2023. Why long contexts underperform expectations.

## Tool use and protocols

- **Model Context Protocol (MCP) specification** — https://modelcontextprotocol.io
- **Anthropic: Tool use on the Claude API** — official docs.
- **OpenAI: Function calling / tools** — official docs.
- **Gorilla: Large Language Model Connected with Massive APIs** —
  Patil et al., 2023.

## Context engineering

- **"RAG vs. Fine-tuning: Pipelines, Tradeoffs, and a Case Study on
  Agriculture"** — Balaguer et al., 2024.
- **"Lost in the Middle"** (see above).
- **Anthropic: Prompt caching best practices** — engineering blog.
- **"MemGPT: Towards LLMs as Operating Systems"** — Packer et al.,
  2023. Memory hierarchies for long-horizon agents.

## Evaluations

- ★ **SWE-bench** — Jimenez et al., 2023. Task-success eval for
  coding agents.
- **WebArena / VisualWebArena** — Zhou et al., 2023; Koh et al.,
  2024. Browser-agent benchmarks.
- **AgentBench** — Liu et al., 2023. Multi-domain agent benchmarks.
- **"Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena"** —
  Zheng et al., 2023.
- **"Holistic Evaluation of Language Models (HELM)"** — Liang et al.,
  2022. Not agent-specific but the methodology transfers.

## Safety and prompt injection

- ★ **Simon Willison's prompt-injection archive** —
  simonwillison.net. The single best running commentary on the topic.
- **"Prompt Injection attacks against GPT-3"** — Willison, 2022.
- **"Dual-Use Dilemma of Prompt Injection"** — multiple authors,
  2023-2024.
- **OWASP Top 10 for LLM Applications** — owasp.org.
- **NIST AI Risk Management Framework** — nist.gov.

## Multi-agent systems

- **"AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent
  Conversation"** — Wu et al., 2023.
- **"ChatDev: Communicative Agents for Software Development"** — Qian
  et al., 2023.
- **"Generative Agents: Interactive Simulacra of Human Behavior"** —
  Park et al., 2023.

## Computer use / browser agents

- **"WebArena" / "VisualWebArena"** (see above).
- **"SeeAct: GPT-4V(ision) is a Generalist Web Agent, if
  Grounded"** — Zheng et al., 2024.
- **Anthropic: Computer Use** — technical blog and system card.

## Production harnesses (read the code)

- **Claude Code** — docs.claude.com; the CLI reference harness.
- **Claude Agent SDK** — for building custom agents on top of the
  Claude primitives.
- **OpenAI Agents SDK** — GitHub.
- **LangChain / LangGraph** — GitHub. Strong opinions, study with a
  critical eye.
- **CrewAI** — GitHub. Multi-agent orchestration patterns.
- **Autogen** — Microsoft Research.

## Operational

- **"The Prompt Report: A Systematic Survey of Prompting
  Techniques"** — Schulhoff et al., 2024. Comprehensive tour.
- **Anthropic engineering blog** — anthropic.com/news. Post-mortem
  and technique-share quality tends to be high.
- **OpenAI cookbook** — github.com/openai/openai-cookbook.

## Books and longer-form

- **"Designing Machine Learning Systems"** — Chip Huyen. Not
  agent-specific, but the MLOps spine carries over.
- **"Engineering a Safer World"** — Nancy Leveson. System safety
  thinking that agent harness designers should not ignore.

## Stay-current practice

- Follow arXiv cs.CL and cs.AI new submissions feeds.
- Read the engineering blogs of Anthropic, OpenAI, Google DeepMind,
  Cohere.
- Follow a small number of researchers and engineers on whatever
  social media still exists.
- Re-read the primary papers above every six months. They read
  differently as your experience grows.
