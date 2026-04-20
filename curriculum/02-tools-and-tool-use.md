# Module 02 — Tools and tool use

## Goals

By the end of this module you should be able to:

1. Design a tool schema that a model can use reliably on the first try.
2. Explain why the same action can be a great tool or a terrible tool
   depending on how it is framed.
3. Implement a tool registry that handles schema validation, dispatch,
   parallel execution, and MCP interop.

## 1. What is a tool, really?

A tool is a function the model can call by emitting a structured output.
From the model's side, a tool is:

- A **name** (short, evocative).
- A **description** (what it does, when to use it, when *not* to use it).
- An **input schema** (JSONSchema).
- A **promise** that calling it will produce a useful result.

From the harness side, a tool is all of the above plus:

- A **handler** (the code that runs when the tool is called).
- A **permission policy** (who can call it, under what conditions).
- A **cost model** (latency, dollars, blast radius).
- An **output shape** (what gets returned to the model).

The model never sees the handler; it only sees the schema and gets back
the handler's output. That asymmetry is the source of every good and bad
design choice in tools.

## 2. Tools are prompts

This is the most important sentence in this module: **a tool's description
is a prompt**. The model decides whether to use the tool, how to use it,
and what arguments to pass based almost entirely on the description you
wrote. Wording that would be acceptable in a docstring for humans can
produce 30-point swings in tool-use accuracy.

Compare:

```
Bad: "search — searches the database"

Good: "search — Query the product catalog by free-text. Use this when the
user asks to find a product by name, description, or SKU. Do NOT use it
for user account lookups (use `get_user` instead). Returns up to 20
matches, ranked by relevance. Prefer specific queries over broad ones."
```

The good version tells the model what the tool *is*, what it *is not*,
what to expect back, and how to call it well. It is a prompt.

Rules of thumb:

- Say what the tool does and what it does *not* do. Models overuse
  general-sounding tools; anti-examples cut that.
- Document the output shape. "Returns a list of {id, title, price}" saves
  a round trip.
- Put the most important information first. Models attend more to the
  start.
- Use the same voice as your system prompt. Inconsistency is noise.

## 3. Schema design

### Name your parameters for comprehension, not brevity

`regex` is worse than `pattern`. `s` is worse than `query`. The model's
prior comes from training data; pick names that humans would pick.

### Prefer enums over free text when the set is small

`"language": "python" | "typescript" | "go"` is dramatically more reliable
than `"language": string`. The model will emit invalid strings just often
enough to ruin your day.

### Use types, defaults, and `required`

Every field should be typed. Optional fields should have explicit
defaults. Required fields should be listed in `required`. The SDK will
enforce this for you; let it.

### Beware of over-constraining

A common anti-pattern: the harness author, knowing too much, creates a
tool with fifteen optional parameters to cover every edge case. The model
flails. Start with the smallest viable interface and add parameters only
when you observe the model struggling without them.

### Output shapes are part of the schema

Tool results are text by default, but structured returns (JSON in a
`content` field, or typed structured outputs where the SDK supports it)
are often better. Structured output means the model does not have to
parse your ad-hoc format. Pick one shape per tool and stick to it.

## 4. Granularity: one big tool vs. many small ones

Consider a "do git operations" capability. You can design it as:

- **One tool**: `git(command: str)` — take any git command.
- **Many tools**: `git_status`, `git_diff`, `git_add`, `git_commit`,
  `git_push`.
- **Mid-grained**: `git(subcommand: enum, args: object)`.

Trade-offs:

- **One big shell.** Maximally flexible. The model will use it to do
  things you did not anticipate (good *and* bad). Hard to sandbox. Hard
  to audit. Hard to tune descriptions.
- **Many small tools.** Each tool has a clear purpose and permission
  envelope. Easier to sandbox and audit. But the tool list gets long;
  the model's attention is finite.
- **Mid-grained.** The common compromise. Still one dispatch point, but
  with a typed subcommand so tests and permissions can target it.

The right grain depends on: (a) how trusted the environment is, (b) how
well-defined the domain is, and (c) how much the model benefits from
composability. There is no universal answer — but committing to one
rather than mixing is important, because the model reasons *about the
tool set as a whole*.

## 5. The tool registry

The tool registry is the harness component that:

1. Stores tool definitions keyed by name.
2. Exposes them in the schema format the model's SDK expects.
3. Validates incoming tool calls against their schemas.
4. Dispatches calls to handlers, with timeouts and permission checks.
5. Normalizes tool results into the format the model expects back.

A simple implementation:

```python
@dataclass
class Tool:
    name: str
    description: str
    input_schema: dict
    handler: Callable
    timeout_s: float = 30.0

class Registry:
    def __init__(self, tools: list[Tool]):
        self.tools = {t.name: t for t in tools}

    def schemas(self) -> list[dict]:
        return [
            {"name": t.name, "description": t.description, "input_schema": t.input_schema}
            for t in self.tools.values()
        ]

    def dispatch(self, name: str, arguments: dict) -> str:
        if name not in self.tools:
            return error_shape(f"unknown tool: {name}", valid=list(self.tools))
        tool = self.tools[name]
        try:
            jsonschema.validate(arguments, tool.input_schema)
        except jsonschema.ValidationError as e:
            return error_shape(f"invalid arguments: {e.message}")
        try:
            with timeout(tool.timeout_s):
                return str(tool.handler(**arguments))
        except Exception as e:
            return error_shape(str(e))
```

Good registries add: retries for transient failures, metrics per tool,
permission hooks (Module 05), and cancellation. They also version tools
(more below).

## 6. Parallel tool calls

Modern models can emit multiple tool calls in one turn. The naive harness
dispatches them serially; a better harness recognizes they are usually
independent and runs them in parallel.

Pitfalls:

- **Shared mutable state.** Two tool handlers writing to the same file
  race. The tool layer is an excellent place to enforce idempotency.
- **Error fan-out.** If one of five parallel tools fails, return *all*
  results to the model (including the failure), not just success. The
  model can reason about partial results better than it can about a
  missing result.
- **Ordering.** If the model emits `read_file` and then `write_file`
  referencing the same file, it expects read-then-write. Detect obvious
  ordering dependencies and serialize them, or document to the model
  that parallel tools are treated as independent.

## 7. The Model Context Protocol (MCP)

MCP is an emerging open standard for talking to tool servers. An MCP
server exposes tools (and resources, prompts, and other primitives) over
JSON-RPC; an MCP client (the harness) discovers and calls them. Benefits:

- **Decoupling.** Tool implementations live outside the harness, can be
  written in any language, and can be updated without redeploying the
  agent.
- **Reuse.** An MCP server written once can be mounted by many agents.
- **Sandboxing.** MCP servers naturally live in separate processes, with
  their own permission surface.

The cost is another hop (latency, operational complexity). For a single
in-process agent, MCP is overkill. For a platform that serves many
agents, MCP becomes essential; you do not want every agent bundling its
own copy of the GitHub tools.

Expect to spend time with the MCP spec as you grow. It will not be the
last tool-integration standard — but it is the one with the most momentum
in 2026.

## 8. Tool versioning

Tools evolve. Schemas change. This is a compatibility problem:

- If your agent keeps the last N conversations in memory, it remembers
  calling `search(query)` — but today's `search(query, filters)` is a
  different tool. How do you migrate?
- If you ship a tool to an eval suite and later change its output shape,
  all your historical evals are invalidated.

Practical strategies:

- Version the tool name (`search_v2`) when breaking schema changes happen.
- Keep the old version available for a deprecation window.
- Include a "tool schema hash" in your eval traces so you can tell which
  version was in effect.
- Never silently change tool behavior. Silent changes are how agents
  regress mysteriously.

## 9. Anti-patterns

Stop doing these:

- **"Swiss army" tools** (`execute(action: str, payload: dict)`) that take
  any action. They always seem like good abstractions until you try to
  sandbox or audit them.
- **Tools that return free-form English** when structured data would do.
  The model then has to re-parse its own tool output.
- **Tools that mutate hidden global state** and do not tell the model.
  The agent's next turn will reason from stale assumptions.
- **Tools whose error messages are stack traces.** Shape errors for the
  model, not the developer.
- **Hundred-tool registries.** If your model has to choose among 100
  tools, you have a routing problem, not a tool problem. Consider tool
  subsetting by task (Module 04 / 08).

## Exercises

See [exercises/02-tools.md](../exercises/02-tools.md).

1. Take a tool description you have written (or the worst one from an
   open-source project) and rewrite it. Measure tool-use accuracy on 20
   queries before and after.
2. Design a `database_query` tool two ways: as one tool, and as a set of
   smaller tools. Argue for one over the other.
3. Implement a tool registry with validation, timeouts, and structured
   error responses. Stress-test it.

## Open questions

- Will tools become more like RPC or more like libraries? (MCP tilts
  toward the former; native structured outputs tilt toward the latter.)
- Is there a theoretical limit to how many tools a model can effectively
  juggle? The empirical number today is "a few dozen," but this number
  is climbing fast.
- How do we express *post-conditions* of tools to the model — "after
  calling this, the system will be in state X"? Nobody has a clean answer.
