# Module 07 — Evaluations

## Goals

By the end of this module you should be able to:

1. Design an eval set that actually catches regressions, not just one
   that looks impressive.
2. Choose between golden, rubric, and judged evals intelligently.
3. Build a replay harness that lets you debug real traces offline.

## 1. Why evals are the heart of harness engineering

Agents are non-deterministic. A change you believe is an improvement
might regress something else. You cannot `git diff` a behavior. The
only way to engineer reliably is to *measure*, and the only way to
measure is with evals.

Good harness engineers spend more time on evals than on prompts.
Seriously. The prompt is the knob; the eval is the ruler. If your
ruler is bad, turning the knob is guesswork.

A defining trait of a production-grade harness is: **you can make any
change with confidence, because the eval suite tells you in minutes
whether it regressed**. Reach that state and the rest of harness
engineering becomes tractable.

## 2. The eval spectrum

Evals come in flavors, each with different cost and signal:

| Type | How it works | Cost | Signal quality |
|---|---|---|---|
| **Unit** | Single call, deterministic expected output | Cheap | High but narrow |
| **Golden** | Expected output matched (exact, fuzzy, or semantic) | Medium | High for regressions |
| **Rubric** | Rubric of criteria scored by human or LLM judge | Medium-high | Good for quality dimensions |
| **LLM-as-judge** | Another LLM scores outputs | Medium | Noisy but scalable |
| **Task success** | Did the agent achieve the goal? (Often via side-effect) | Can be high | Highest, but expensive |
| **Shadow traffic** | Compare new harness to old on real traffic | Very high | Ground-truth for impact |
| **A/B tests** | Random split in production | Highest | Definitive, but slow |

Use them in combination. Unit and golden evals run on every commit.
Rubric and judge evals run nightly. Task-success evals run on major
releases. Shadow and A/B test in production.

## 3. Curating an eval set

A good eval set is small, diverse, and evolves. Build it like this:

1. **Seed with real traces.** Take actual user conversations (with
   privacy review), select the interesting ones, and convert them into
   eval cases. Synthetic seeds miss what real users do.
2. **Cover failure modes.** Every bug report becomes an eval. The eval
   set grows in proportion to the failure modes you have seen.
3. **Cover diversity.** Make sure you have easy cases, hard cases,
   adversarial cases, and "weird but legitimate" cases. Over-indexing
   on any one bucket distorts your decisions.
4. **Balance.** If 80% of your eval cases are easy, improvements on
   hard cases will disappear in the average. Weight your reporting.
5. **Prune.** Evals that never fail teach you nothing. Evals that
   always fail teach you nothing (the model cannot do the thing).
   Keep the ones that discriminate.

Aim for a set that takes minutes, not hours, to run. You will iterate
on it — it must be fast enough to iterate.

## 4. Golden evals: matching done right

Golden evals compare a new output to an expected output. The trap is
"exact match" on non-deterministic systems; it gives you zero signal.

Better matchers:

- **Structured field match.** If the output is JSON, compare the
  fields you care about, ignore the rest.
- **Regex match.** For format checks ("contains an E.164 phone
  number").
- **Semantic match.** Embed both outputs, compare cosine similarity.
  Thresholded. Good for "this is about the right topic."
- **Subset / superset.** The output contains the key facts, maybe
  more.

For agent evals, the golden is often a *trace*, not a single output.
You compare tool call sequences, tool arguments, or the final
side-effect state. Compare what matters for the behavior, not the
whole transcript.

## 5. Rubric and LLM-as-judge

For qualitative dimensions (helpfulness, tone, safety), rubrics are
more honest than match-based evals. Structure:

```
Rubric: Code review quality
  - Identified all the bugs in the PR (0-2)
  - Suggestions are actionable and specific (0-2)
  - No hallucinated concerns (0 or -3)
  - Tone is professional (0-1)
```

Human raters are the gold standard; LLMs as judges are the scalable
stand-in. Caveats for LLM-as-judge:

- **Model self-preference.** A model judging its own outputs scores
  them higher. Use a different model (or the same model with a
  different prompt) for judging.
- **Position bias.** In pairwise judging, the first-presented option
  tends to win. Randomize order; or use calibrated-majority.
- **Prompt sensitivity.** A judge prompt has to be calibrated on a
  small human-labeled set. Budget for this.
- **Disagreement with humans.** Periodically sample 50 cases, have
  humans grade them, check agreement with the judge. If it drops,
  recalibrate.

LLM-as-judge is a tool, not a panacea. Treat it as a noisy signal
to be monitored, not a source of truth.

## 6. Task-success evals

The best eval is: *did the agent complete the task?* For many agent
applications you can build this:

- **Coding agents.** Run the generated tests; if they pass, success.
  SWE-bench is the canonical example. The difficulty is making the
  test runnable deterministically, fast.
- **Browser agents.** Check that a state transition occurred (an item
  in a cart, a form submitted). Requires stable environments, often
  Dockerized websites.
- **Customer support.** "Did this conversation reduce to a resolved
  ticket?" (Noisy; requires labels.)
- **Research agents.** Harder — "is the summary accurate?" usually
  requires human or LLM judging.

Task-success evals are expensive to build (they need environments,
fixtures, deterministic setup), but they are the closest proxy to
"does the harness work." Invest.

## 7. Replay

A replay harness re-runs a past conversation through the current
harness. It is priceless for:

- Debugging: "why did the agent do X in production?" → replay with
  added logging.
- Regression testing: "did our change break this real trace?"
- Analysis: "across 1000 recent traces, where does the agent stall?"

Requirements for replay:

- Every tool call's inputs and outputs are logged deterministically.
- Any non-deterministic tool (time, random, external API) can be
  replayed from the recorded output rather than re-executed.
- The harness version is logged, so you know which code the trace was
  produced by.

Replay is so valuable that you should design for it from day one.
Retrofit is painful.

## 8. The metrics dashboard

A harness in production needs a live dashboard of at minimum:

- **Task success rate** (the top-line).
- **Cost per task** (input + output tokens, by model).
- **Latency per task** (median, p95, p99).
- **Turn count distribution** (a bimodal "fast or stuck" distribution
  is a telltale sign of loop pathologies).
- **Tool failure rate per tool.**
- **Cache hit rate** (see Module 03).
- **Permission denials and user interventions.**
- **Regressions** against your eval set, broken down by category.

Review weekly. Regressions often creep in through dependencies,
prompt edits, model version bumps, or tool upgrades. A weekly eyeball
catches drift before users do.

## 9. Evals are also a design tool

Evals are not just a safety net — they are also how you discover
whether a design works. Typical workflow:

1. Propose a change (new compaction policy, new tool, new prompt).
2. Run evals on the baseline and the change.
3. Look at *which cases changed* and in which direction.
4. If the change helped the overall number but hurt a specific
   category, understand why before merging.
5. Add cases from the hurt category to the eval set if missing.

Evals transform "I think this is better" into "here is evidence, with
trade-offs."

## 10. Anti-patterns

- **Over-fitting.** If you iterate long enough, your harness passes
  every eval in your set. This does not mean it works. Keep a held-out
  set that you evaluate less frequently; when the gap between "dev"
  and "held-out" performance grows, you are overfitting.
- **Eval cases that require knowledge only the author has.** Reviewers
  cannot grade these; judges drift. Write self-contained eval cases.
- **Single-number reporting.** Collapsing a harness's behavior to one
  number hides compensating errors. Break it down.
- **No humans in the loop.** Pure automation on evals reliably drifts.
  Sample and inspect by hand at least weekly.

## Exercises

See [exercises/07-evals.md](../exercises/07-evals.md).

1. Convert your Module 01 harness into something you can eval. Build a
   10-case golden eval set. Run it twice (non-deterministically) and
   see which cases are flaky.
2. Add an LLM-as-judge eval for response quality. Calibrate on a
   hand-labeled subset of 20.
3. Record all tool calls to disk; write a replay harness that can
   re-run any recorded conversation.

## Open questions

- How do we detect "the eval set has stopped being representative"?
  There is no clean signal. Proxies (drift in traffic distribution)
  help but do not suffice.
- How do we eval *long-horizon* agents where a task takes hours and
  touches external state? (Partial answer: simulators; full answer:
  open research.)
- Is LLM-as-judge going to scale with the models? Or does it
  introduce a fundamental self-consistency ceiling?
