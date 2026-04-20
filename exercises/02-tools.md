# Exercises — Module 02: Tools and tool use

## 2.1 — Description surgery

Find five tool descriptions in open-source harnesses. Rewrite them
according to the rules in §2 and §3. For each, run 20 queries where
the tool *should* be used and 20 where it should not. Measure the
precision/recall before and after.

**Deliverable:** a table of before/after precision and recall, plus
the five rewrites.

## 2.2 — One big vs. many small

Design a `database_query` capability two ways:

- **One tool:** `database_query(sql: str)`.
- **Many tools:** `list_tables`, `describe_table`, `select_rows`,
  `aggregate_by`.

Implement both. Run the same 10 questions through each. Which wins?
On what axes? Would your answer change for a non-technical user?

**Deliverable:** side-by-side results and a recommendation.

## 2.3 — Registry from scratch

Implement a tool registry with:

- JSONSchema validation.
- Per-tool timeouts.
- Structured error responses.
- Parallel dispatch.
- A stress test (100 concurrent calls; 30% of handlers fail).

**Deliverable:** code + stress-test output.

## 2.4 — MCP integration

Stand up one MCP server exposing one tool. Integrate it into your
harness. Measure the latency overhead vs. in-process.

**Deliverable:** numbers and a short note on when the overhead is
worth it.

## 2.5 — Anti-pattern hunt

Find a codebase (your own or open-source) that uses tools. Identify
at least three anti-patterns from Module 02 §9. For each, propose a
fix.

**Deliverable:** a short review document.
