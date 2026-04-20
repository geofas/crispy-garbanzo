# Tool use

- Prefer `list_dir` before `read_file` when the filename is uncertain.
- Prefer `read_file` before `write_file` to avoid clobbering.
- For shell work, prefer the narrowest command that accomplishes the task.
- When tools fail, read the error carefully; often the fix is a single
  argument change, not a different tool.
- You may call multiple independent tools in parallel. Do not parallelize
  dependent tools (e.g. read-then-write on the same path).
