---
title: Replace Shell Scripting with Exec Modules
toc: true
weight: 5
---

Shell scripts are ubiquitous but have well-known limitations: inconsistent syntax across shells, poor error handling, limited data structures, and obscure quoting rules. Spaces **execution mode** provides a modern alternative: write scripts in [Starlark](https://github.com/bazelbuild/starlark) (a Python-like language) with immediate execution, structured data, and a rich standard library.

This guide shows you how to create executable Starlark scripts using **exec modules** (`*.exec.star`) as a replacement for Bash, Zsh, or other shell scripts.

## What are Exec Modules?

Exec modules are Starlark files ending in `.exec.star` that run in **execution mode**. Unlike rules modules (`.spaces.star`), which build a dependency graph for deferred execution, exec modules run code **immediately**, top-to-bottom, just like a shell script.

See [Operating Modes](/docs/explainers/operating-modes/) for a detailed comparison of rules mode vs. execution mode.

### Key Differences from Shell Scripts

| Feature | Shell Scripts | Exec Modules |
|---------|---------------|--------------|
| **Language** | Bash/Zsh/sh syntax | Python-like Starlark |
| **Data Structures** | Strings and arrays | Dictionaries, lists, strings, numbers, booleans |
| **Error Handling** | Manual `set -e` / `$?` checking | Automatic error propagation |
| **Parsing** | Fragile quoting, word splitting | Structured function calls |
| **Cross-platform** | POSIX vs. Windows differences | Unified API across platforms |
| **Testing** | Limited tooling | Type-checked, testable functions |

## Creating an Executable Exec Module

### Basic Structure

Create a file named `script.exec.star`:

```python
#!/usr/bin/env spaces

load("@star/sdk/star/std/log.star", "log_info")
load("@star/sdk/star/std/sh.star", "sh_capture")

# This code runs immediately
log_info("Starting script...")

# Capture command output
branch = sh_capture("git rev-parse --abbrev-ref HEAD")
log_info("Current branch: " + branch)
```

### Making it Executable

Add a shebang line and make the file executable:

```bash
chmod +x script.exec.star
```

Now run it directly:

```bash
./script.exec.star
```

Or invoke it with `spaces`:

```bash
spaces exec script.exec.star
```

### Loading Workspace Modules

Exec modules can load other Starlark files from your workspace using `load()` statements with paths starting with `//`. These paths are resolved relative to `$SPACES_WORKSPACE`:

```python
#!/usr/bin/env spaces

load("@star/sdk/star/std/log.star", "log_info")
load("//lib/utils.star", "format_date", "send_notification")

# Use functions from your workspace
date = format_date()
send_notification("Deployment started at " + date)
log_info("Deployment in progress...")
```

**Important**: When running exec modules directly (not within `spaces run`), you **must** set the `SPACES_WORKSPACE` environment variable to your workspace root:

```bash
export SPACES_WORKSPACE=/path/to/your/workspace
./script.exec.star
```

When exec modules are invoked from within Spaces rules (e.g., via `run_add_exec()`), the `SPACES_WORKSPACE` environment variable is automatically provided.

## Building a Command-Line API with Args

The `args` module provides a powerful, type-safe way to parse command-line arguments. It's much more robust than parsing `$1`, `$2`, etc. in shell scripts.

### Simple Flag Example

```python
#!/usr/bin/env spaces

load("@star/sdk/star/std/args.star", "args_parser", "args_flag", "args_opt", "args_parse")
load("@star/sdk/star/std/log.star", "log_info")

# Define the command-line interface
spec = args_parser(
    name = "deploy",
    description = "Deploy application to a target environment",
    options = [
        args_flag("--verbose", "-v", "Enable verbose output"),
        args_flag("--dry-run", "-n", "Show what would be deployed without deploying"),
        args_opt("--env", "-e", "Target environment", default="staging", choices=["dev", "staging", "prod"]),
    ],
)

# Parse arguments (exits on error or --help)
opts = args_parse(spec)

# Use parsed values
if opts.get("verbose", False):
    log_info("Verbose mode enabled")

if opts.get("dry-run", False):
    log_info("Dry-run mode: no changes will be made")

env = opts.get("env", "staging")
log_info("Deploying to: " + env)

# ... deployment logic ...
```

Running with `--help` automatically generates usage documentation:

```bash
./deploy.exec.star --help
```

### Options with Types

```/dev/null/build.exec.star#L1-25
#!/usr/bin/env spaces

load("@star/sdk/star/std/args.star", "args_parser", "args_opt", "args_parse")
load("@star/sdk/star/std/log.star", "log_info")

spec = args_parser(
    name = "build",
    description = "Build the project with configurable options",
    options = [
        args_opt("--jobs", "-j", "Number of parallel jobs", type="int", default=4),
        args_opt("--optimize", "-O", "Enable optimizations", type="bool", default=True),
    ],
)

opts = args_parse(spec)

jobs = opts.get("jobs", 4)  # int
optimize = opts.get("optimize", True)  # bool

log_info("Building with " + str(jobs) + " parallel jobs")
if optimize:
    log_info("Optimizations enabled")
else:
    log_info("Optimizations disabled")
```

### Repeatable Options (Lists)

```/dev/null/tag.exec.star#L1-21
#!/usr/bin/env spaces

load("@star/sdk/star/std/args.star", "args_parser", "args_list", "args_parse")
load("@star/sdk/star/std/log.star", "log_info")

spec = args_parser(
    name = "tag",
    description = "Tag Docker images",
    options = [
        args_list("--tag", "-t", "Add a tag (can be specified multiple times)", type="str"),
    ],
)

opts = args_parse(spec)

tags = opts.get("tag", [])  # list of strings
log_info("Tags: " + str(tags))

for tag in tags:
    log_info("  - " + tag)
```

### Positional Arguments

```/dev/null/copy.exec.star#L1-21
#!/usr/bin/env spaces

load("@star/sdk/star/std/args.star", "args_parser", "args_pos", "args_parse")
load("@star/sdk/star/std/fs.star", "fs_copy")
load("@star/sdk/star/std/log.star", "log_info")

spec = args_parser(
    name = "copy",
    description = "Copy files from source to destination",
    positional = [
        args_pos("source", required=True),
        args_pos("destination", required=True),
    ],
)

opts = args_parse(spec)

src = opts.get("source", "")
dst = opts.get("destination", "")
fs_copy(src, dst, recursive=False, overwrite=True, follow_symlinks=True)
log_info("Copied " + src + " to " + dst)
```

### Variadic Arguments

```/dev/null/concat.exec.star#L1-20
#!/usr/bin/env spaces

load("@star/sdk/star/std/args.star", "args_parser", "args_pos", "args_parse")
load("@star/sdk/star/std/fs.star", "fs_read_text", "fs_write_text")
load("@star/sdk/star/std/log.star", "log_info")

spec = args_parser(
    name = "concat",
    description = "Concatenate multiple files into one",
    positional = [
        args_pos("files", required=True, variadic=True),  # accepts multiple values
    ],
)

opts = args_parse(spec)

files = opts.get("files", [])  # list of file paths
log_info("Concatenating " + str(len(files)) + " files")
# ... concatenation logic ...
```

## Launching Processes

The `process` module provides low-level control over process execution. For simple commands, use the `sh` module (see next section), but `process` is ideal when you need fine-grained control over I/O, timeouts, or background processes.

### Running a Command

```/dev/null/example.exec.star#L1-17
#!/usr/bin/env spaces

load("@star/sdk/star/std/process.star", "process_options", "process_run")
load("@star/sdk/star/std/log.star", "log_info")

# Build command options
opts = process_options(
    command = "cargo",
    args = ["build", "--release"],
    cwd = "my-project",
    check = True,  # Raise error on non-zero exit
)

# Run the command
result = process_run(opts)
log_info("Build completed with exit code: " + str(result["status"]))
log_info("Output: " + result["stdout"])
```

### Capturing Output

```/dev/null/git-info.exec.star#L1-22
#!/usr/bin/env spaces

load("@star/sdk/star/std/process.star", "process_options", "process_run", "process_stdout_capture")
load("@star/sdk/star/std/log.star", "log_info")

# Capture stdout
opts = process_options(
    command = "git",
    args = ["log", "--oneline", "-5"],
    stdout = process_stdout_capture(),
)

result = process_run(opts)
if result["status"] == 0:
    log_info("Recent commits:")
    log_info(result["stdout"])
else:
    log_info("Git log failed")
```

### Redirecting to Files

```/dev/null/build-log.exec.star#L1-18
#!/usr/bin/env spaces

load("@star/sdk/star/std/process.star", "process_options", "process_run", "process_stdout_file", "process_stderr_file")
load("@star/sdk/star/std/log.star", "log_info")

# Redirect stdout and stderr to files
opts = process_options(
    command = "cargo",
    args = ["build"],
    stdout = process_stdout_file("build.log"),
    stderr = process_stderr_file("build.err"),
)

result = process_run(opts)
log_info("Build finished, logs written to build.log and build.err")
```

### Setting Environment Variables

```/dev/null/env-example.exec.star#L1-18
#!/usr/bin/env spaces

load("@star/sdk/star/std/process.star", "process_options", "process_run")
load("@star/sdk/star/std/log.star", "log_info")

opts = process_options(
    command = "node",
    args = ["server.js"],
    env = {
        "NODE_ENV": "production",
        "PORT": "8080",
    },
)

result = process_run(opts)
log_info("Server exited with code: " + str(result["status"]))
```

### Timeouts

```/dev/null/timeout-example.exec.star#L1-19
#!/usr/bin/env spaces

load("@star/sdk/star/std/process.star", "process_options", "process_run")
load("@star/sdk/star/std/log.star", "log_info", "log_error")

opts = process_options(
    command = "slow-command",
    args = ["--task"],
    timeout_ms = 5000,  # 5 second timeout
    check = False,
)

result = process_run(opts)
if result["status"] != 0:
    log_error("Command failed or timed out")
else:
    log_info("Command completed in " + str(result["duration_ms"]) + "ms")
```

### Background Processes

```/dev/null/background.exec.star#L1-30
#!/usr/bin/env spaces

load("@star/sdk/star/std/process.star", "process_options", "process_spawn", "process_wait", "process_is_running")
load("@star/sdk/star/std/log.star", "log_info")
load("@star/sdk/star/std/time.star", "time_sleep")

# Spawn a background process
opts = process_options(
    command = "python",
    args = ["-m", "http.server", "8000"],
)

handle = process_spawn(opts)
log_info("Server started in background")

# Do other work...
time_sleep(2.0)

# Check if still running
if process_is_running(handle):
    log_info("Server is running")

# Wait for completion (or timeout)
result = process_wait(handle, timeout_ms=1000)
log_info("Server exited with status: " + str(result["status"]))
```

### Pipelines

```/dev/null/pipeline.exec.star#L1-22
#!/usr/bin/env spaces

load("@star/sdk/star/std/process.star", "process_options", "process_pipeline")
load("@star/sdk/star/std/log.star", "log_info")

# Create a pipeline: list all Python files, count them
steps = [
    process_options(command = "find", args = [".", "-name", "*.py"]),
    process_options(command = "wc", args = ["-l"]),
]

result = process_pipeline(steps)

if result["status"] == 0:
    count = result["stdout"].strip()
    log_info("Found " + count + " Python files")
else:
    log_info("Pipeline failed")
```

## Shell Commands with `sh`

For simpler use cases where you want shell features (pipes, globbing, redirection), use the `sh` module. It's more convenient than `process` but uses the system shell, so be cautious with untrusted input.

### Capturing Output

```/dev/null/sh-capture.exec.star#L1-14
#!/usr/bin/env spaces

load("@star/sdk/star/std/sh.star", "sh_capture")
load("@star/sdk/star/std/log.star", "log_info")

# Simple command capture
branch = sh_capture("git rev-parse --abbrev-ref HEAD")
log_info("Branch: " + branch)

# With shell features (pipes)
file_count = sh_capture("find . -name '*.py' | wc -l")
log_info("Python files: " + file_count)
```

### Exit Code Checking

```/dev/null/sh-exit.exec.star#L1-17
#!/usr/bin/env spaces

load("@star/sdk/star/std/sh.star", "sh_exit_code")
load("@star/sdk/star/std/log.star", "log_info")

# Check if a file exists
status = sh_exit_code("test -f config.json")
if status == 0:
    log_info("Config file exists")
else:
    log_info("Config file not found")

# Check if git repo has uncommitted changes
if sh_exit_code("git diff --quiet") != 0:
    log_info("Uncommitted changes detected")
```

### Line-by-Line Output

```/dev/null/sh-lines.exec.star#L1-14
#!/usr/bin/env spaces

load("@star/sdk/star/std/sh.star", "sh_lines")
load("@star/sdk/star/std/log.star", "log_info")

# Get list of files
files = sh_lines("ls -1 *.py")
log_info("Found " + str(len(files)) + " Python files:")

for f in files:
    log_info("  - " + f)
```

### Full Control with `sh_run`

```/dev/null/sh-run.exec.star#L1-18
#!/usr/bin/env spaces

load("@star/sdk/star/std/sh.star", "sh_run")
load("@star/sdk/star/std/log.star", "log_info")

# Run and inspect all output
result = sh_run("cargo build 2>&1")

log_info("Exit code: " + str(result["status"]))
log_info("Output: " + result["stdout"])

if result["status"] != 0:
    log_info("Build failed")
else:
    log_info("Build succeeded")
```

## Standard Library Overview

Exec modules have access to all functions in the `@star/sdk/star/std` namespace. Here's a summary of available modules:

### Core Process & Shell

- **[`args`](/docs/reference/@star/sdk/star/std/args/)** — Parse command-line arguments with flags, options, and positional arguments
- **[`process`](/docs/reference/@star/sdk/star/std/process/)** — Low-level process execution with full I/O control, timeouts, and pipelines
- **[`sh`](/docs/reference/@star/sdk/star/std/sh/)** — High-level shell command execution (capture, lines, exit codes)

### File System

- **[`fs`](/docs/reference/@star/sdk/star/std/fs/)** — File and directory operations (read, write, copy, move, delete, metadata)
- **[`path`](/docs/reference/@star/sdk/star/std/path/)** — Path manipulation (join, split, normalize, absolute, relative)

### Data Formats

- **[`json`](/docs/reference/@star/sdk/star/std/json/)** — JSON encoding and decoding
- **[`yaml`](/docs/reference/@star/sdk/star/std/yaml/)** — YAML parsing and serialization
- **[`toml`](/docs/reference/@star/sdk/star/std/toml/)** — TOML parsing and serialization

### Utilities

- **[`env`](/docs/reference/@star/sdk/star/std/env/)** — Environment variables (get, set, PATH manipulation, `which`)
- **[`log`](/docs/reference/@star/sdk/star/std/log/)** — Structured logging (info, warn, error, debug, fatal)
- **[`string`](/docs/reference/@star/sdk/star/std/string/)** — String manipulation (split, join, trim, replace)
- **[`hash`](/docs/reference/@star/sdk/star/std/hash/)** — Compute checksums (SHA256, MD5, etc.)
- **[`time`](/docs/reference/@star/sdk/star/std/time/)** — Time and date utilities
- **[`tmp`](/docs/reference/@star/sdk/star/std/tmp/)** — Temporary file and directory creation
- **[`sys`](/docs/reference/@star/sdk/star/std/sys/)** — System information (OS, architecture, hostname)

## Complete Example: Deployment Script

Here's a realistic deployment script that combines multiple features:

```/dev/null/deploy.exec.star#L1-90
#!/usr/bin/env spaces

load("@star/sdk/star/std/args.star", "args_parser", "args_flag", "args_opt", "args_parse")
load("@star/sdk/star/std/log.star", "log_info", "log_error", "log_fatal", "log_set_level")
load("@star/sdk/star/std/sh.star", "sh_capture", "sh_exit_code", "sh_run")
load("@star/sdk/star/std/fs.star", "fs_exists", "fs_read_json")
load("@star/sdk/star/std/env.star", "env_get")
load("@star/sdk/star/std/process.star", "process_options", "process_run", "process_stdout_capture")

# Parse command-line arguments
spec = args_parser(
    name = "deploy",
    description = "Deploy application to target environment",
    options = [
        args_flag("--verbose", "-v", "Enable verbose output"),
        args_flag("--dry-run", "-n", "Show what would happen without deploying"),
        args_flag("--force", "-f", "Skip safety checks"),
        args_opt("--env", "-e", "Target environment", default="staging", choices=["dev", "staging", "prod"]),
        args_opt("--version", "", "Version to deploy (default: current git commit)"),
    ],
)

opts = args_parse(spec)

# Configure logging
if opts.get("verbose", False):
    log_set_level("debug")

# Get configuration
env_name = opts.get("env", "staging")
log_info("Deploying to: " + env_name)

# Load deployment config
config_path = "deploy/" + env_name + ".json"
if not fs_exists(config_path):
    log_fatal("Config file not found: " + config_path)

config = fs_read_json(config_path)
log_info("Loaded config: " + config_path)

# Determine version
version = opts.get("version")
if not version:
    version = sh_capture("git rev-parse --short HEAD")
    log_info("Using current commit: " + version)

# Safety checks
if not opts.get("force", False):
    # Check for uncommitted changes
    if sh_exit_code("git diff --quiet") != 0:
        log_fatal("Uncommitted changes detected. Commit or use --force")
    
    # Check if on main branch for production
    if env_name == "prod":
        branch = sh_capture("git rev-parse --abbrev-ref HEAD")
        if branch != "main":
            log_fatal("Production deploys must be from 'main' branch. Use --force to override")

# Build the application
log_info("Building application...")
if opts.get("dry-run", False):
    log_info("[DRY RUN] Would run: cargo build --release")
else:
    result = sh_run("cargo build --release", check=True)
    log_info("Build complete")

# Run tests
log_info("Running tests...")
if opts.get("dry-run", False):
    log_info("[DRY RUN] Would run: cargo test")
else:
    result = sh_run("cargo test", check=True)
    log_info("Tests passed")

# Deploy
log_info("Deploying version " + version + " to " + env_name + "...")
if opts.get("dry-run", False):
    log_info("[DRY RUN] Would deploy to: " + config["server"])
else:
    deploy_opts = process_options(
        command = "rsync",
        args = [
            "-avz",
            "target/release/app",
            config["server"] + ":" + config["deploy_path"],
        ],
        stdout = process_stdout_capture(),
    )
    
    result = process_run(deploy_opts)
    if result["status"] == 0:
        log_info("Deployment successful!")
    else:
        log_error("Deployment failed")
        log_fatal(result["stderr"])

log_info("Done!")
```

Run it:

```bash
# Deploy to staging (default)
./deploy.exec.star

# Deploy to production with version tag
./deploy.exec.star --env prod --version v1.2.3

# Dry run
./deploy.exec.star --dry-run

# Verbose output
./deploy.exec.star --verbose
```

## Best Practices

### 1. Use Type-Safe Argument Parsing

Always use the `args` module instead of manual argument parsing. It provides:
- Automatic `--help` generation
- Type validation
- Error messages with usage hints

### 2. Handle Errors Explicitly

Use `check=True` for critical commands that should fail fast:

```/dev/null/error-handling.exec.star#L1-15
load("@star/sdk/star/std/sh.star", "sh_run")
load("@star/sdk/star/std/log.star", "log_error", "log_fatal")

# This raises an error if the command fails
sh_run("cargo build", check=True)

# For optional commands, check manually
result = sh_run("cargo clippy", check=False)
if result["status"] != 0:
    log_error("Clippy failed, but continuing anyway")

# For critical failures, use log_fatal
if not fs_exists("config.json"):
    log_fatal("Config file required but not found")
```

### 3. Prefer `sh` for Simple Commands, `process` for Complex Ones

- Use `sh_capture()` for quick one-liners with shell features
- Use `process` when you need timeouts, background execution, or I/O redirection

### 4. Use Structured Data

Take advantage of Starlark's data structures:

```/dev/null/structured-data.exec.star#L1-18
load("@star/sdk/star/std/fs.star", "fs_read_json", "fs_write_json")

# Read structured config
config = fs_read_json("config.json")

# Modify it
config["version"] = "1.2.3"
config["deployments"] = config.get("deployments", [])
config["deployments"].append({
    "env": "staging",
    "timestamp": "2024-01-15T10:30:00Z",
})

# Write it back
fs_write_json("config.json", config, pretty=True)
```

### 5. Log Generously

Use structured logging to make scripts observable:

```/dev/null/logging.exec.star#L1-12
load("@star/sdk/star/std/log.star", "log_info", "log_debug", "log_error")

log_info("Starting deployment")
log_debug("Config loaded: " + str(config))

result = sh_run("deploy.sh")
if result["status"] == 0:
    log_info("Deployment successful")
else:
    log_error("Deployment failed with exit code: " + str(result["status"]))
    log_error(result["stderr"])
```

## Migrating from Shell Scripts

### Shell Script (Bash)

```bash
#!/bin/bash
set -euo pipefail

ENV=${1:-staging}
VERSION=${2:-$(git rev-parse --short HEAD)}

echo "Deploying $VERSION to $ENV"

if [[ "$ENV" == "prod" ]]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$BRANCH" != "main" ]]; then
        echo "Error: Production deploys must be from main"
        exit 1
    fi
fi

cargo build --release
cargo test

rsync -avz target/release/app server:/var/www/app

echo "Done!"
```

### Exec Module (Starlark)

```/dev/null/deploy-migration.exec.star#L1-41
#!/usr/bin/env spaces

load("@star/sdk/star/std/args.star", "args_parser", "args_opt", "args_parse")
load("@star/sdk/star/std/log.star", "log_info", "log_fatal")
load("@star/sdk/star/std/sh.star", "sh_capture", "sh_run")

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
version = opts.get("version")
if not version:
    version = sh_capture("git rev-parse --short HEAD")

log_info("Deploying " + version + " to " + env)

# Prod safety check
if env == "prod":
    branch = sh_capture("git rev-parse --abbrev-ref HEAD")
    if branch != "main":
        log_fatal("Production deploys must be from main")

# Build and test
sh_run("cargo build --release", check=True)
sh_run("cargo test", check=True)

# Deploy
sh_run("rsync -avz target/release/app server:/var/www/app", check=True)

log_info("Done!")
```

### Benefits of the Migration

- **Type safety**: Arguments are validated automatically
- **Better errors**: Clear error messages with automatic help text
- **Cross-platform**: No Bash-isms, works on Windows, macOS, Linux
- **Testable**: Functions can be loaded and tested independently
- **Maintainable**: Python-like syntax is easier to read and modify

## Next Steps

- Read [Operating Modes](/docs/explainers/operating-modes/) to understand when to use exec vs. rules mode
- Explore the [Standard Library Reference](/docs/reference/@star/sdk/star/std/) for all available functions
- See [Args Reference](/docs/reference/@star/sdk/star/std/args/) for advanced argument parsing patterns
- Check out [Process Reference](/docs/reference/@star/sdk/star/std/process/) for low-level process control
