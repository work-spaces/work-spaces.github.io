#!/usr/bin/env spaces
"""
Create builtins page
"""

load("//@star/prelude/exec/fs.star", "fs_write_text")
load("//@star/prelude/exec/log.star", "log_fatal")
load(
    "//@star/prelude/exec/process.star",
    "process_options",
    "process_run",
    "process_stdout_capture",
)
load("//@star/prelude/exec/sys.star", "sys_exit")

HEADER = """---
title: Help Reference
toc: true
weight: 3
---

```sh
$ spaces --help
"""

CHECKOUT_HELP = """

### Checkout Help

```sh
$ spaces checkout --help
"""

RUN_HELP = """

### Run Help

```sh
$ spaces run --help
"""

QUERY_HELP = """

### Query Help

```sh
$ spaces query --help
"""

SYNC_HELP = """

### Sync Help

```sh
$ spaces sync --help
"""

OUTPUT_FILE = "content/docs/reference/help.md"

GETTING_HELP = [
    (HEADER, []),
    (CHECKOUT_HELP, ["checkout"]),
    (RUN_HELP, ["run"]),
    (QUERY_HELP, ["query"]),
    (SYNC_HELP, ["sync"]),
]

def _get_help_output(args: list[str]) -> str:
    options = process_options(
        command = "spaces",
        args = args,
        stdout = process_stdout_capture(),
    )
    result = process_run(options)
    if result["status"] != 0:
        log_fatal("Failed to run {}".format(str(options)))

    return result["stdout"]

def main() -> int:
    # Get output of `spaces docs`

    output = ""
    for help_header, command in GETTING_HELP:
        help = _get_help_output(command + ["--help"])
        output += help_header
        output += help
        output += "```\n"

    # Write output to file
    fs_write_text(OUTPUT_FILE, output)

    return 0

result = main()
sys_exit(result)
