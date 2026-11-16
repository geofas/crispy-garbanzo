"""CLI entry point for micro-harness. Wire everything together."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from anthropic import Anthropic

import agent
import context
import permissions
import tools
import trace


def load_prompt(version: str = "v1") -> str:
    base = Path(__file__).parent / "prompts" / version
    layers = ["identity", "behavior", "tool_use", "safety"]
    parts = []
    for name in layers:
        f = base / f"{name}.md"
        if f.exists():
            parts.append(f.read_text())
    return context.shape_system_prompt(parts)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("task", help="the user's request")
    parser.add_argument("--scope", default="./workspace", help="directory the agent may touch")
    parser.add_argument("--prompt-version", default="v1")
    parser.add_argument("--model", default="claude-opus-4-7")
    parser.add_argument("--max-turns", type=int, default=20)
    parser.add_argument("--traces", default="./traces")
    args = parser.parse_args()

    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("ERROR: set ANTHROPIC_API_KEY", file=sys.stderr)
        return 1

    client = Anthropic()
    registry = tools.Registry(tools.make_default_tools(args.scope))
    policy = permissions.default_policy()
    tr = trace.Trace()

    def dispatch(name: str, arguments: dict) -> str:
        decision, reason = policy.check(
            permissions.Context(tool=name, arguments=arguments)
        )
        tr.record({"type": "permission", "tool": name, "decision": decision, "reason": reason})
        if decision == "deny":
            return f"DENIED: {reason}"
        if decision == "ask":
            prompt = f"\n[permission] tool={name} args={arguments}\nApprove? [y/N] "
            if input(prompt).strip().lower() != "y":
                return "DENIED: user declined"
        return registry.dispatch(name, arguments)

    result = agent.run(
        client=client,
        model=args.model,
        system=load_prompt(args.prompt_version),
        tools=registry.schemas(),
        dispatch=dispatch,
        user_message=args.task,
        budget=agent.Budget(max_turns=args.max_turns),
        on_event=tr.record,
    )

    tr.save(Path(args.traces))
    print(f"\n[done] stop={result.stop.kind} turns={result.turns} trace={tr.trace_id}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
