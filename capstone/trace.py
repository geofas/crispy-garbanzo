"""Trace recording and replay. See Modules 07, 08.

Milestone 8: make every run replayable.
"""

from __future__ import annotations

import json
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class Trace:
    trace_id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    harness_version: str = "0.1.0"
    started_at: float = field(default_factory=time.time)
    events: list[dict] = field(default_factory=list)

    def record(self, event: dict) -> None:
        event = dict(event)
        event["t"] = time.time() - self.started_at
        self.events.append(event)

    def save(self, dir: Path) -> Path:
        dir.mkdir(parents=True, exist_ok=True)
        path = dir / f"{self.trace_id}.jsonl"
        with path.open("w") as f:
            f.write(json.dumps({"meta": {
                "trace_id": self.trace_id,
                "harness_version": self.harness_version,
                "started_at": self.started_at,
            }}) + "\n")
            for e in self.events:
                f.write(json.dumps(e, default=str) + "\n")
        return path

    @classmethod
    def load(cls, path: Path) -> "Trace":
        meta = None
        events = []
        with path.open() as f:
            for line in f:
                obj = json.loads(line)
                if meta is None and "meta" in obj:
                    meta = obj["meta"]
                else:
                    events.append(obj)
        return cls(
            trace_id=meta["trace_id"],
            harness_version=meta["harness_version"],
            started_at=meta["started_at"],
            events=events,
        )
