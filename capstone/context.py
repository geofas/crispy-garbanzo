"""Context management. See Module 03.

Milestone 3: implement compaction and cache breakpoints.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class CompactionConfig:
    keep_last: int = 8          # verbatim turns to keep
    summarize_after: int = 16   # summarize once history exceeds this
    summary_token_cap: int = 500


def should_compact(messages: list[dict], config: CompactionConfig) -> bool:
    return len(messages) > config.summarize_after


def compact(messages: list[dict], config: CompactionConfig, summarizer) -> list[dict]:
    """Summarize older turns into a single synthetic user turn, keep tail verbatim.

    `summarizer` is a callable that takes a list of messages and returns a
    paragraph-length summary string.
    """
    if not should_compact(messages, config):
        return messages

    head = messages[: -config.keep_last]
    tail = messages[-config.keep_last :]

    summary = summarizer(head)
    synthetic = {
        "role": "user",
        "content": [
            {
                "type": "text",
                "text": f"[Conversation summary of {len(head)} prior turns]\n{summary}",
            }
        ],
    }
    return [synthetic] + tail


# --- Cache-friendly prompt shape -------------------------------------------

def shape_system_prompt(layers: list[str]) -> str:
    """Concatenate prompt layers so the static ones come first.

    Order matters for prompt caching: anything before a dynamic byte is
    invalidated the moment that byte changes. Keep dynamic content late.
    """
    return "\n\n".join(layer.strip() for layer in layers if layer.strip())
