"""Tool registry. See Module 02.

Milestone 2: validate, dispatch, and add built-in tools.
"""

from __future__ import annotations

import json
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

import jsonschema


@dataclass
class Tool:
    name: str
    description: str
    input_schema: dict
    handler: Callable[..., str]
    timeout_s: float = 30.0
    version: str = "v1"


class Registry:
    def __init__(self, tools: list[Tool]):
        self.tools: dict[str, Tool] = {t.name: t for t in tools}

    def schemas(self) -> list[dict]:
        return [
            {
                "name": t.name,
                "description": t.description,
                "input_schema": t.input_schema,
            }
            for t in self.tools.values()
        ]

    def dispatch(self, name: str, arguments: dict[str, Any]) -> str:
        tool = self.tools.get(name)
        if tool is None:
            return self._error(
                f"unknown tool: {name!r}",
                hint=f"valid tools: {sorted(self.tools)}",
            )
        try:
            jsonschema.validate(arguments, tool.input_schema)
        except jsonschema.ValidationError as e:
            return self._error(f"invalid arguments for {name}: {e.message}")

        try:
            return str(tool.handler(**arguments))
        except FileNotFoundError as e:
            return self._error(str(e), hint="check the path and try again")
        except Exception as e:
            return self._error(f"{type(e).__name__}: {e}")

    @staticmethod
    def _error(message: str, hint: str | None = None) -> str:
        body: dict[str, Any] = {"error": message}
        if hint:
            body["hint"] = hint
        return json.dumps(body)


# --- Built-in tools ---------------------------------------------------------

def _scoped(root: Path, path: str) -> Path:
    p = (root / path).resolve()
    if not str(p).startswith(str(root.resolve())):
        raise PermissionError(f"path escapes scope: {path}")
    return p


def make_default_tools(scope_dir: str | Path) -> list[Tool]:
    """Make tools scoped to a directory the agent is allowed to touch."""
    root = Path(scope_dir).resolve()
    root.mkdir(parents=True, exist_ok=True)

    def read_file(path: str) -> str:
        return _scoped(root, path).read_text()

    def write_file(path: str, content: str) -> str:
        p = _scoped(root, path)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
        return f"wrote {p.relative_to(root)} ({len(content)} bytes)"

    def list_dir(path: str = ".") -> str:
        p = _scoped(root, path)
        entries = sorted(os.listdir(p))
        return "\n".join(entries) if entries else "(empty)"

    def run_shell(command: str, timeout_s: float = 10.0) -> str:
        # TODO Milestone 5: gate this on permission policy with argument checks.
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout_s,
            cwd=root,
        )
        return json.dumps(
            {
                "exit": result.returncode,
                "stdout": result.stdout[-4000:],
                "stderr": result.stderr[-4000:],
            }
        )

    def web_search(query: str) -> str:
        # Mock tool; replace with a real search in production.
        return json.dumps(
            {
                "query": query,
                "results": [
                    {"title": f"Mock result for {query}", "url": "https://example.com"},
                ],
            }
        )

    return [
        Tool(
            name="read_file",
            description=(
                "Read a UTF-8 text file from the working directory. "
                "Use when you need the contents of a known file. Returns the full "
                "file contents as a string."
            ),
            input_schema={
                "type": "object",
                "properties": {"path": {"type": "string"}},
                "required": ["path"],
            },
            handler=read_file,
        ),
        Tool(
            name="write_file",
            description=(
                "Write (overwrite) a UTF-8 text file in the working directory. "
                "Creates parent directories as needed. Prefer `read_file` first "
                "to avoid clobbering existing work."
            ),
            input_schema={
                "type": "object",
                "properties": {
                    "path": {"type": "string"},
                    "content": {"type": "string"},
                },
                "required": ["path", "content"],
            },
            handler=write_file,
        ),
        Tool(
            name="list_dir",
            description=(
                "List directory entries. Use to discover files before reading. "
                "Defaults to the working directory root."
            ),
            input_schema={
                "type": "object",
                "properties": {"path": {"type": "string", "default": "."}},
            },
            handler=list_dir,
        ),
        Tool(
            name="run_shell",
            description=(
                "Run a shell command in the working directory. Use for running "
                "tests, build commands, or file operations not covered by other "
                "tools. Do NOT use for destructive operations without "
                "confirmation. Returns exit code, stdout (last 4KB), stderr "
                "(last 4KB)."
            ),
            input_schema={
                "type": "object",
                "properties": {
                    "command": {"type": "string"},
                    "timeout_s": {"type": "number", "default": 10.0},
                },
                "required": ["command"],
            },
            handler=run_shell,
        ),
        Tool(
            name="web_search",
            description=(
                "Search the web for a query and return top results. Use when you "
                "need information you do not already have. Returns a JSON list of "
                "{title, url}."
            ),
            input_schema={
                "type": "object",
                "properties": {"query": {"type": "string"}},
                "required": ["query"],
            },
            handler=web_search,
        ),
    ]
