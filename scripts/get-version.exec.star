#!/usr/bin/env spaces
"""
Create builtins page
"""

load("//@star/prelude/exec/fs.star", "fs_write_text")
load(
    "//@star/prelude/exec/sh.star",
    "sh_capture",
)
load("//@star/prelude/exec/sys.star", "sys_exit")

def main() -> int:
    # Get output of `spaces docs`

    spaces_version = sh_capture("spaces --version").replace("spaces ", "v")
    sdk_version = sh_capture("git -C ../@star/sdk describe --tags --abbrev=0")
    packages_version = sh_capture("git -C ../@star/packages describe --tags --abbrev=0")

    output = """---
title: Version
toc: false
weight: 1
---

This documention covers:

- [Spaces](https://github.com/work-spaces/spaces) version: {spaces_version}
- [SDK](https://github.com/work-spaces/sdk) version: {sdk_version}
- [Packages](https://github.com/work-spaces/packages) version: {packages_version}

""".format(
        spaces_version = spaces_version,
        sdk_version = sdk_version,
        packages_version = packages_version,
    )

    # Write output to file
    fs_write_text("content/docs/reference/version.md", output)

    return 0

result = main()
sys_exit(result)
