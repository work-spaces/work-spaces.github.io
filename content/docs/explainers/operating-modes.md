---
title: Operating Modes
toc: true
weight: 3
---

`spaces` evaluates Starlark modules in two fundamentally different modes: **rules mode** and **execution mode**. The mode determines when and how built-in functions execute, what APIs are available, and whether the system builds a dependency graph or runs code immediately.

## Rules Mode

Rules mode is the default operating model for `spaces`. In this mode, Starlark evaluation constructs a **dependency graph** rather than executing tasks immediately. The graph is built during evaluation, and once evaluation completes, `spaces` resolves dependencies and executes rules based on the graph structure.

### Rules Modules

Modules that end in `spaces.star` are **rules modules**. When `spaces` evaluates a rules module:

1. **Starlark code runs** — variables are assigned, functions are called, control flow executes.
2. **Built-in functions register rules** — calls to functions like `run.add_exec()` or `checkout.add_repo()` do not execute their tasks immediately. Instead, they add nodes to the dependency graph.
3. **The graph is assembled** — once all rules modules have been evaluated, `spaces` has a complete graph of tasks and their dependencies.
4. **Execution follows the graph** — `spaces` walks the graph, respects dependencies, and runs rules in the correct order. Independent rules can run in parallel.

### Available APIs in Rules Mode

Rules modules have access to the **Starlark SDK** functions defined in the `/docs/reference/@star/sdk/star` namespace:

- **`checkout.*`** — register repositories, archives, tools, and assets to be checked out.
- **`run.*`** — define build, test, setup, and other executable rules.
- **`asset.*`** — generate files from Starlark strings.
- **`gh.*`, `oras.*`, `cmake.*`, `gnu.*`** — domain-specific helpers for common tasks.
- **`rules.*`** — utilities for working with rule groups and dependencies.
- **`env.*`, `spaces_env.*`** — manage environment variables.
- **`ws.*`, `info.*`, `visibility.*`** — workspace introspection and rule visibility control.

Rules modules **cannot** use the functions in `/docs/reference/@star/sdk/star/std`. Those APIs execute immediately and are reserved for execution mode.

### Why Rules Mode?

The dependency graph model enables:

- **Parallel execution** — independent rules run concurrently.
- **Incremental builds** — rules with unchanged inputs can be skipped.
- **Reproducibility** — the same graph always produces the same result.

### Example

```python
# This is a rules module — it builds a dependency graph

load("@star/sdk/star/run.star", "run_add_exec")

run_add_exec(
    name = "build",
    command = "cargo",
    args = ["build", "--release"],
)

run_add_exec(
    name = "test",
    command = "cargo",
    args = ["test"],
    deps = [":build"],  # test depends on build
)

```

When this module is evaluated:

1. The `load()` statement imports the `run_add_exec` function.
2. The function `_add_build_rules()` is defined.
3. The function is called, which invokes `run_add_exec()` twice.
4. **Nothing executes yet** — the calls to `run_add_exec()` register two rules in the dependency graph.
5. When `spaces run //<path>:test` is invoked, `spaces` sees that `test` depends on `build`, executes `build` first, then runs `test`.

## Execution Mode

Execution mode treats Starlark as a **shell scripting replacement**. In this mode, built-in functions execute **immediately** as the Starlark module is evaluated. There is no dependency graph — code runs top-to-bottom, just like a shell script.

### Execution Modules

Modules that end in `exec.star` are **execution modules**. When `spaces` evaluates an execution module:

1. **Starlark code runs top-to-bottom** — just like a Python or shell script.
2. **Built-in functions execute immediately** — a call to `sh.capture()` or `process.exec()` runs the command right away and returns the result.
3. **No dependency graph** — there are no rules, no deferred execution, nor parallelism based on dependencies.

### Available APIs in Execution Mode

Execution modules have access to all the APIs in the **`/docs/reference/@star/sdk/star/std`** namespace:

- **`sh.*`** — run shell commands with `sh.capture()`, `sh.run()`, `sh.lines()`, `sh.exit_code()`, and `sh.pipe()`.
- **`process.*`** — execute processes directly with `process.exec()`.
- **`fs.*`** — file system operations (read, write, copy, delete).
- **`path.*`** — path manipulation and resolution.
- **`env.*`** — access and modify environment variables during execution.
- **`json.*`, `yaml.*`, `toml.*`** — parse and serialize structured data.
- **`string.*`** — string manipulation utilities.
- **`hash.*`** — compute checksums.
- **`log.*`** — emit log messages.
- **`args.*`** — parse command-line arguments.
- **`sys.*`, `time.*`, `tmp.*`** — system information, timestamps, and temporary files.

Execution modules **cannot** use the rules APIs from `/docs/reference/@star/sdk/star`. The rules registration functions expect a dependency graph, which does not exist in execution mode.

### Why Execution Mode?

Execution mode is useful for:

- **Scripting tasks** — one-off administrative scripts, setup scripts, CI/CD glue.
- **Interactive workflows** — scripts that need to react to command output immediately.
- **Prototyping** — quick experimentation without the overhead of defining rules.
- **Integration with external tools** — calling shell commands and processing output in real time.

### Example

```python
# This is an execution module — code runs immediately

load("@star/sdk/star/std/sh.star", "sh_capture", "sh_exit_code")
load("@star/sdk/star/std/log.star", "log_info")

# Get the current git branch — this runs NOW
branch = sh_capture("git rev-parse --abbrev-ref HEAD")
log_info("Current branch: " + branch)

# Check if we have uncommitted changes — this runs NOW
status = sh_exit_code("git diff --quiet")
if status != 0:
    log_info("Uncommitted changes detected")
else:
    log_info("Working directory is clean")

# Run a build — this runs NOW
result = sh_capture("cargo build")
log_info("Build complete")
```

When this module is evaluated:

1. The `load()` statements import functions from the `std` namespace.
2. `sh_capture("git rev-parse ...")` executes immediately and returns the branch name.
3. `log_info(...)` prints the message immediately.
4. `sh_exit_code("git diff --quiet")` runs immediately and returns the exit code.
5. The `if` statement evaluates and logs the appropriate message.
6. `sh_capture("cargo build")` runs the build command immediately.

Everything happens during evaluation, top-to-bottom, with no deferred execution.

## Comparison

| Aspect | Rules Mode (`*.spaces.star`) | Execution Mode (`*.exec.star`) |
|--------|------------------------------|--------------------------------|
| **Execution model** | Deferred — builds a dependency graph, then executes it | Immediate — runs code top-to-bottom as evaluated |
| **Parallelism** | Independent rules run in parallel | Sequential execution only |
| **Caching** | Rules can skip execution if inputs are unchanged | No caching — every evaluation runs all code |
| **Available APIs** | `/docs/reference/@star/sdk/star` (rules registration) | `/docs/reference/@star/sdk/star/std` (immediate execution) |
| **Use case** | Declarative build and task definitions | Shell scripting replacement, one-off tasks |
| **Dependency tracking** | Explicit — rules declare dependencies with `deps` | Implicit — order of statements in the file |

## Choosing a Mode

- **Use rules mode** when you need reproducible, parallel, incremental task execution. This is the default and recommended mode for workspace definitions, build systems, and long-lived tasks.
- **Use execution mode** when you need to run commands immediately, process their output interactively, or write quick administrative scripts. This is the Starlark equivalent of a shell script.

The two modes are complementary. A workspace can contain both rules modules (for build and test definitions) and execution modules (for scripting and automation). They serve different purposes and have different strengths.
