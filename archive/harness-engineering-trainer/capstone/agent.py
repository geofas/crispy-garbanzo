"""The agent loop. See Module 01.

Milestone 1: make the minimal loop work end-to-end.
Later milestones will add compaction (Module 03), subagents (04),
permissions (05), and trace recording (08).
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from typing import Any, Callable

from anthropic import Anthropic


@dataclass
class Budget:
    max_turns: int = 20
    max_wall_clock_s: float = 300.0
    started_at: float = field(default_factory=time.time)

    def elapsed(self) -> float:
        return time.time() - self.started_at

    def turns_remaining(self, used: int) -> int:
        return max(0, self.max_turns - used)

    def is_exhausted(self, used_turns: int) -> bool:
        return used_turns >= self.max_turns or self.elapsed() >= self.max_wall_clock_s


@dataclass
class StopReason:
    kind: str  # "end_turn" | "max_turns" | "wall_clock" | "cancelled" | "error"
    detail: str = ""


@dataclass
class RunResult:
    messages: list[dict]
    stop: StopReason
    turns: int


def run(
    client: Anthropic,
    model: str,
    system: str,
    tools: list[dict],
    dispatch: Callable[[str, dict], str],
    user_message: str,
    budget: Budget | None = None,
    on_event: Callable[[dict], None] | None = None,
    cancel_token: Callable[[], bool] = lambda: False,
) -> RunResult:
    """Run the agent loop.

    TODO Milestone 1:
      - Stream the response instead of waiting for the full block.
      - Check cancel_token between tokens and between tool calls.
      - Distinguish stop reasons in the returned result.

    TODO Milestone 2:
      - Validate tool_calls against schemas before dispatch.

    TODO Milestone 5:
      - Call permissions.check() before dispatch; handle ask / deny.

    TODO Milestone 8:
      - Emit structured events via on_event for replay.
    """
    budget = budget or Budget()
    messages: list[dict] = [{"role": "user", "content": user_message}]
    turns = 0

    while True:
        if cancel_token():
            return RunResult(messages, StopReason("cancelled"), turns)
        if budget.is_exhausted(turns):
            return RunResult(messages, StopReason("max_turns"), turns)

        turns += 1
        response = client.messages.create(
            model=model,
            system=system,
            tools=tools,
            messages=messages,
            max_tokens=4096,
        )

        assistant_content = response.content
        messages.append({"role": "assistant", "content": assistant_content})
        if on_event:
            on_event({"type": "assistant", "turn": turns, "content": assistant_content})

        tool_calls = [b for b in assistant_content if b.type == "tool_use"]
        if not tool_calls:
            return RunResult(messages, StopReason("end_turn"), turns)

        tool_results = []
        for tc in tool_calls:
            try:
                result = dispatch(tc.name, dict(tc.input))
            except Exception as e:
                result = f"ERROR: {type(e).__name__}: {e}"
            tool_results.append(
                {"type": "tool_result", "tool_use_id": tc.id, "content": result}
            )
            if on_event:
                on_event({"type": "tool_result", "name": tc.name, "id": tc.id})

        messages.append({"role": "user", "content": tool_results})
