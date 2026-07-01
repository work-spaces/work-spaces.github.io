#!/usr/bin/env spaces
"""
Create builtins page
"""

load("//@star/prelude/exec/fs.star", "fs_write_text")
load(
    "//@star/prelude/exec/process.star",
    "process_options",
    "process_run",
    "process_stdout_capture",
)
load("//@star/prelude/exec/sys.star", "sys_exit")

CONTENT = """---
title: Builtin Functions
toc: true
weight: 2
---

The contents of this page can be generated using:

```sh
spaces docs
```

"""

OUTPUT_FILE = "content/docs/reference/builtins.md"

def main() -> int:
    # Get output of `spaces docs`
    result = process_run(process_options(
        command = "spaces",
        args = ["docs"],
        stdout = process_stdout_capture(),
    ))
    if result["status"] != 0:
        return result["return_code"]
    output = CONTENT + result["stdout"]

    # Write output to file
    fs_write_text(OUTPUT_FILE, output)

    return 0

result = main()
sys_exit(result)
