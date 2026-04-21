"""Permission engine. See Module 05.

Milestone 5: gate tool dispatch on a policy.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Callable, Literal


Decision = Literal["allow", "deny", "ask"]


@dataclass
class Context:
    tool: str
    arguments: dict
    agent: str = "root"
    session_id: str = ""


@dataclass
class Rule:
    tool: str
    predicate: Callable[[dict], bool]
    decision: Decision
    reason: str = ""


@dataclass
class Policy:
    rules: list[Rule] = field(default_factory=list)
    default: Decision = "ask"

    def check(self, ctx: Context) -> tuple[Decision, str]:
        for r in self.rules:
            if r.tool == ctx.tool and r.predicate(ctx.arguments):
                return r.decision, r.reason
        return self.default, ""


# --- Useful predicates ------------------------------------------------------

def always(_: dict) -> bool:
    return True


def arg_matches(field: str, pattern: str) -> Callable[[dict], bool]:
    rx = re.compile(pattern)
    def pred(args: dict) -> bool:
        v = args.get(field, "")
        return isinstance(v, str) and bool(rx.search(v))
    return pred


def path_outside(field: str, allowed_prefix: str) -> Callable[[dict], bool]:
    def pred(args: dict) -> bool:
        v = args.get(field, "")
        return isinstance(v, str) and not v.startswith(allowed_prefix)
    return pred


# --- A reasonable default policy -------------------------------------------

DANGEROUS_SHELL = re.compile(
    r"(\brm\s+-rf\b|\bmkfs\b|\bdd\s+if=|:\(\)\s*\{\s*:\|:&\s*\};:|>\s*/dev/sd|chmod\s+-R\s+777|shutdown\b|reboot\b|\bkill\s+-9\s+1\b)"
)


def default_policy() -> Policy:
    return Policy(
        rules=[
            Rule(
                tool="run_shell",
                predicate=lambda a: bool(DANGEROUS_SHELL.search(a.get("command", ""))),
                decision="deny",
                reason="command matches dangerous-shell denylist",
            ),
            Rule(tool="read_file", predicate=always, decision="allow"),
            Rule(tool="list_dir", predicate=always, decision="allow"),
            Rule(tool="web_search", predicate=always, decision="allow"),
            Rule(tool="run_shell", predicate=always, decision="ask"),
            Rule(tool="write_file", predicate=always, decision="ask"),
        ],
        default="ask",
    )
