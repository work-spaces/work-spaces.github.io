---
title: Replace Shell Scripting with Exec Modules
description: Migrate shell scripts to executable Starlark modules with safer argument parsing, structured data, and better process control.
toc: true
weight: 5
---

Shell scripts are great for quick automation, but they get hard to maintain as workflows grow. `spaces` exec modules (`*.exec.star`) give you script-style execution with Python-like syntax, typed argument parsing, and a richer standard library.

{{< callout type="info" >}}
Exec modules run **immediately** (top-to-bottom), unlike `.spaces.star` files which define rules for deferred execution.
{{< /callout >}}

See [Operating Modes](/docs/explainers/operating-modes/) for a deeper comparison.

## Why replace shell scripts?

| Capability | Shell scripts | Exec modules |
|---|---|---|
| Syntax | Shell-specific (`sh`/`bash`/`zsh`) | Starlark (Python-like) |
| Data model | Mostly strings | Lists, dicts, booleans, numbers |
| Error handling | Manual (`set -e`, `$?`) | Structured return values + fail-fast helpers |
| Argument parsing | Positional parsing by hand | `args` module with validation/help |
| Process control | Basic | Timeouts, capture, pipelines, spawn/wait |

## Quick start

{{% steps %}}

### Create an executable module

Create `deploy.exec.star`:

```python
#!/usr/bin/env spaces

load("//@star/prelude/exec/log.star", "log_info")
load("//@star/prelude/exec/sh.star", "sh_capture")

log_info("Starting deployment script")
branch = sh_capture("git rev-parse --abbrev-ref HEAD")
log_info("Current branch: " + branch)
```

### Make it executable

```bash
chmod +x deploy.exec.star
```

### Run it

```bash
./deploy.exec.star
```

```bash
spaces deploy.exec.star
```


{{% /steps %}}

{{< callout type="warning" >}}
If you run an exec module directly (outside `spaces run`), set `SPACES_WORKSPACE` so `load("//...")` paths resolve:

```bash
export SPACES_WORKSPACE=/path/to/workspace
./deploy.exec.star
```

When invoked from rules (for example through `run_add_exec()`), `SPACES_WORKSPACE` is set automatically.
{{< /callout >}}

## Build a proper CLI with `args`

Use the `args` module instead of manual `$1`, `$2` parsing.

```python
#!/usr/bin/env spaces

load("//@star/prelude/exec/args.star", "args_parser", "args_flag", "args_opt", "args_parse")
load("//@star/prelude/exec/log.star", "log_info")

spec = args_parser(
    name = "deploy",
    description = "Deploy application",
    options = [
        args_flag("--verbose", "-v", "Verbose logs"),
        args_flag("--dry-run", "-n", "Print actions without executing"),
        args_opt("--env", "-e", "Target environment", default="staging", choices=["dev", "staging", "prod"]),
    ],
)

opts = args_parse(spec)

if opts.get("verbose", False):
    log_info("Verbose mode enabled")

log_info("Deploying to: " + opts.get("env", "staging"))
```

```bash
./deploy.exec.star --help
```

{{< details title="More argument patterns" closed="true" >}}

### Typed options

```python
args_opt("--jobs", "-j", "Parallel jobs", type="int", default=4)
args_opt("--optimize", "-O", "Enable optimizations", type="bool", default=True)
```

### Repeatable options

```python
load("//@star/prelude/exec/args.star", "args_list")
args_list("--tag", "-t", "Can be repeated", type="str")
```

### Positional and variadic arguments

```python
load("//@star/prelude/exec/args.star", "args_pos")

positional = [
    args_pos("source", required=True),
    args_pos("destination", required=True),
]

# Variadic
args_pos("files", required=True, variadic=True)
```

{{< /details >}}

## Process execution: `sh` vs `process`

Use `sh` for quick shell-style commands; use `process` when you need precise control.

```python
load("//@star/prelude/exec/sh.star", "sh_capture", "sh_exit_code", "sh_run")

branch = sh_capture("git rev-parse --abbrev-ref HEAD")
dirty = sh_exit_code("git diff --quiet") != 0
result = sh_run("cargo build 2>&1", check=False)
```

```python
load("//@star/prelude/exec/process.star", "process_options", "process_run", "process_stdout_capture")

opts = process_options(
    command = "cargo",
    args = ["build", "--release"],
    timeout_ms = 120000,
    stdout = process_stdout_capture(),
    check = False,
)

result = process_run(opts)
```


{{< callout type="important" icon="sparkles" >}}
If command input includes untrusted values, prefer `process` argument lists over shell strings to reduce quoting/injection risk.
{{< /callout >}}

## Migration example

### Before (shell)

```bash
#!/bin/bash
set -euo pipefail

ENV=${1:-staging}
VERSION=${2:-$(git rev-parse --short HEAD)}

echo "Deploying $VERSION to $ENV"
cargo build --release
cargo test
rsync -avz target/release/app server:/var/www/app
```

### After (exec module)

```python
#!/usr/bin/env spaces

load("//@star/prelude/exec/args.star", "args_parser", "args_opt", "args_parse")
load("//@star/prelude/exec/log.star", "log_info", "log_fatal")
load("//@star/prelude/exec/sh.star", "sh_capture", "sh_run")

spec = args_parser(
    name = "deploy",
    description = "Deploy application",
    options = [
        args_opt("--env", "-e", "Environment", default="staging"),
        args_opt("--version", "-v", "Version to deploy"),
    ],
)
opts = args_parse(spec)

env = opts.get("env", "staging")
version = opts.get("version") or sh_capture("git rev-parse --short HEAD")

if env == "prod":
    branch = sh_capture("git rev-parse --abbrev-ref HEAD")
    if branch != "main":
        log_fatal("Production deploys must be from main")

log_info("Deploying " + version + " to " + env)
sh_run("cargo build --release", check=True)
sh_run("cargo test", check=True)
sh_run("rsync -avz target/release/app server:/var/www/app", check=True)
log_info("Done")
```

## Best practices

- Use `args_parse()` for every CLI script.
- Prefer `process` for timeouts, redirection, and safer command composition.
- Keep script state in structured data (dict/list), not ad-hoc string parsing.
- Use `log_info`/`log_error`/`log_fatal` so failures are obvious.
- Split reusable logic into normal `.star` modules and `load()` them.

## Next steps

- [Operating Modes](/docs/explainers/operating-modes/)
- [Standard Library Reference](/docs/reference/@star/sdk/star/std/)
- [Args reference](/docs/reference/@star/sdk/star/std/args/)
- [Process reference](/docs/reference/@star/sdk/star/std/process/)
- [Shell reference](/docs/reference/@star/sdk/star/std/sh/)
