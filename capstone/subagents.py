"""Router and specialist subagents. See Module 04.

Milestone 4: implement a router that dispatches to coder/researcher
subagents with their own budgets and tool subsets.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable


@dataclass
class SubagentBrief:
    """Self-sufficient brief passed from parent to child.

    Write this as if the child has not seen the conversation: every path,
    constraint, goal, and expected return format must be explicit.
    """
    goal: str
    context: str
    return_format: str
    max_turns: int = 10


@dataclass
class Specialist:
    name: str
    system_prompt: str
    allowed_tools: list[str]


CODER = Specialist(
    name="coder",
    system_prompt=(
        "You are a coding subagent. You receive a well-scoped task with "
        "enough context to act. You use read_file, write_file, list_dir, "
        "run_shell. You return a compact summary: what you did, what you "
        "changed, and any remaining concerns. Do not return full diffs "
        "unless asked."
    ),
    allowed_tools=["read_file", "write_file", "list_dir", "run_shell"],
)

RESEARCHER = Specialist(
    name="researcher",
    system_prompt=(
        "You are a research subagent. You receive a well-scoped question. "
        "You use web_search and read_file. You return a paragraph-length "
        "summary with 2-5 bulleted findings and citations (URLs). Do not "
        "speculate beyond what the sources support."
    ),
    allowed_tools=["web_search", "read_file"],
)


ROUTER_PROMPT = (
    "You are a router. You classify the user's request into exactly one of:\n"
    "  - coder: file / code / shell / build / debug tasks in the local repo\n"
    "  - researcher: questions requiring web search or reading external docs\n"
    "  - direct: trivial requests you can answer without tools\n\n"
    "Respond with a JSON object: {\"route\": \"coder|researcher|direct\", "
    "\"brief\": \"<task brief for the specialist, self-sufficient>\"}"
)


def run_specialist(
    specialist: Specialist,
    brief: SubagentBrief,
    dispatch: Callable[[str, dict], str],
    run_agent: Callable,  # usually agent.run
) -> str:
    """Run a specialist with its restricted tool set and return its summary."""
    # TODO Milestone 4: filter the tool registry down to allowed_tools,
    # apply the brief as the user message, cap budget per SubagentBrief,
    # and return the final assistant text (compressed).
    raise NotImplementedError
