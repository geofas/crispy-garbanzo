---
title: "Module 06 — Prompts for harnesses"
parent: Curriculum
nav_order: 6
---

# Module 06 — Prompts for harnesses

## Goals

By the end of this module you should be able to:

1. Write a system prompt that degrades gracefully as model capabilities
   change.
2. Distinguish the six (or so) prompt layers that compose a real
   harness prompt, and know who owns each.
3. Avoid the common anti-patterns that turn prompts into brittle
   regex in English.

## 1. Prompts in a harness are different

Classical prompt engineering is about finding *the* prompt that makes
the model do the thing. That is important but it is a different job.

In a harness, a prompt is:

- **Composed** from multiple layers written by different authors.
- **Reused** across many conversations, not tuned to one.
- **Cached** in pieces, so structural stability matters.
- **Safety-critical** because it bounds what the agent will do.
- **Versioned** because changes to it cause behavioral regressions.

Think of prompts less like poetry and more like configuration files or
APIs. They need tests. They need version control. They need backwards
compatibility where users have come to depend on a behavior.

## 2. The layers of a harness prompt

A typical assistant prompt, assembled in order:

1. **Identity.** "You are X." Very short. Sets persona and voice.
2. **Task framing.** What the agent does and why. A paragraph or two.
3. **Capability and limitation notes.** What the agent *can* do (tools,
   memory), what it *cannot* (browse, run code, call external APIs
   except through tools), what it *must not*.
4. **Behavioral policy.** Style rules: how terse, when to clarify, how
   to refuse, output format.
5. **Tool-use policy.** When to use tools, when not to, how to handle
   tool errors, when to chain vs. parallelize.
6. **Safety policy.** Refusals, escalations, confirmation requirements.
7. **Dynamic context.** Current date, user preferences, environment,
   retrieved facts.
8. **Task / user turn.** The actual message.

Layers 1-6 are stable; 7 changes sometimes; 8 every turn. The stable
layers belong in the cacheable prefix (Module 03). Keep them boring.

Different layers typically have different authors and different
release cycles. Make that explicit: have a file per layer, version
them independently, and compose at runtime. That way your safety team
can update layer 6 without your product team touching layer 3.

## 3. Structure over adjectives

"Be concise" is a weak instruction. "Keep responses under 100 words
unless the user asked for detail" is a strong instruction. "Respond
with only JSON matching this schema: {...}" is a contract.

As you move from adjective → constraint → structured output, you move
from hope to reliability. Default to as much structure as the task
allows.

### Structured output is a prompt tool

For machine-consumed outputs, demand structured output. Most SDKs now
support native structured outputs (schema-enforced); use them. They are
cheaper, more reliable, and less brittle than parsing markdown.

For human-consumed outputs, structure still helps. A checklist format
for code review. A bullet list for options. The structure tells the
model what kind of thinking to do.

## 4. Concision and the prompt-length paradox

Shorter prompts are more cache-friendly and often work better than
long ones. But there is a paradox: as agents get more capable, the
scope of instructions you want to give them *increases*. Claude Code's
system prompt is long for a reason.

Guidelines:

- Remove instructions the model no longer needs. Modern models are
  better at politeness than 2022 models; you can drop "Be polite."
- Replace prose with examples when behavior is subtle. Two examples
  beats a paragraph.
- Remove negative instructions ("Do not X") when you can replace them
  with positive framings ("Prefer Y"). Negative instructions mention
  the thing you want to prevent, which can prime the model toward it.
- Keep only the instructions the model actually respects. If an
  instruction is routinely violated, either enforce it at the
  harness layer or drop it.

## 5. Anti-patterns

### Prompts as regex

```
Always start your response with "Sure!" unless the user said "no". If
the user said "no", start with "Understood." If the user said "please",
say "Of course!" unless it's Tuesday...
```

This is a symptom. It means (a) the model is not following an
underlying principle, so you are patching symptoms; or (b) the behavior
belongs in the harness layer (a formatter, a response rewriter), not
the prompt.

### Magic words

"You are an expert. Think step by step. Take a deep breath." Some of
these worked on older models; few still do. They are cargo-culted and
add length without effect. Delete them. If a magic word *does* work,
measure it in your evals; do not just assume.

### Instructions without examples

For any subtle behavior, *show* as well as *tell*. One good few-shot
example is often worth a paragraph of prose.

### Overlapping layers

The same rule duplicated across identity, behavioral policy, and
safety policy — with slightly different wording — is a maintenance
nightmare. Pick one layer to own each rule and reference from the
others if needed.

### Prompts that name the harness

"You are running in Harness v3.2." Almost always a mistake. It
couples your prompts to an implementation detail and the model gets
confused if the version changes. Describe *capabilities*, not
*implementations*.

## 6. Prompts as code: version and test them

Your prompts are code. Treat them that way.

- **Version control.** Every prompt change is a commit. You want
  `git log` on your system prompt.
- **Code review.** Prompt changes affect behavior; they should go
  through review like any other change.
- **Tests.** For every instruction in a system prompt that you care
  about, there should be an eval that would fail if the instruction
  were dropped. If you cannot write the eval, you do not know whether
  the instruction is doing anything.
- **Canarying.** Roll out prompt changes to a slice of traffic first.
- **Rollback.** Prompts can silently regress; make rollback fast.

The harness-engineering discipline is "prompt-as-code" — writing
prompts with the same rigor as source code, and treating them as the
durable product surface they are.

## 7. Tool descriptions: a special prompt

Covered in Module 02 but worth repeating: **every tool description is
a prompt**, and often the highest-leverage one. If the model is not
calling your tool when it should — or is calling it wrong — fix the
description before you fix the code.

Tool descriptions benefit from the same rules:

- Structure (what / when / not when / returns).
- Examples for subtle use cases.
- Consistency with the system prompt's voice.
- Versioned and tested.

## 8. Output shaping

A remarkable amount of end-user quality comes from how you instruct
the model's *output*. Principles:

- Decide the output shape in advance. Markdown? JSON? Plain text?
  Length bound? Tell the model, and use structured outputs to enforce.
- Separate "thinking" from "response." If the model reasons aloud, do
  it in a region the user will not see (a thinking block, a scratchpad
  tool). Do not intermix reasoning with the answer.
- Pick one formatting convention and stick to it across the product.
  Jumping between headers and dashes and tables is disorienting.

## 9. Personalization

User- or session-specific preferences ("I prefer Rust; never suggest
Python") belong in a dedicated prompt layer, late in the prompt, with
clear provenance. Mixing them into the system prompt makes caching
harder and mixes up "what the product does" with "what this user
prefers."

The emerging pattern is a **memory file** (Claude's `CLAUDE.md`, other
harnesses' equivalents) that the user owns and the harness appends at
a stable position in the prompt. Respect user authorship; do not
silently rewrite user memories.

## Exercises

See [exercises/06-prompts.md](../exercises/06-prompts.md).

1. Take a 500-word system prompt and cut it by 50% without losing
   measurable performance. Define "measurable" first by building a
   10-case eval.
2. Design a layered prompt for a coding assistant: identity, task,
   capability, behavior, tool-use, safety. Put each in its own file
   and compose at runtime.
3. Find an instruction in your prompt that you suspect the model
   ignores. Write an eval that would catch violations. Run it.

## Open questions

- Will prompt design converge to a declarative format (something like
  a "behavior spec" compiled to natural language)? Prototypes exist;
  nothing has won.
- How should we author prompts for *future* model generations when we
  don't know what they'll do better or worse than current ones? (Hint:
  by decoupling from specific failure modes.)
- What is the right abstraction for "user preferences" that outlive
  a session? Memory files are a local maximum, not an answer.
