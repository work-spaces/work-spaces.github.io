---
title: Operating Modes
description: Understand when `spaces` builds a dependency graph versus executing Starlark immediately.
toc: true
weight: 3
---

`spaces` evaluates Starlark modules in two different operating modes: **rules mode** and **execution mode**. Choosing the right mode determines whether work is planned as a dependency graph or run immediately, top-to-bottom.

{{< callout type="important" >}}
Use `*.spaces.star` for declarative, dependency-aware workflows. Use `*.exec.star` for imperative scripting.
{{< /callout >}}

## At a glance

| Mode | File pattern | Runtime model | Primary APIs |
|---|---|---|---|
| **Rules mode** | `*.spaces.star` | Build dependency graph first, execute after evaluation | `/docs/reference/@star/sdk/star` |
| **Execution mode** | `*.exec.star` | Execute immediately while evaluating the file | `/docs/reference/@star/prelude/exec` |

## Rules mode (`*.spaces.star`)

In rules mode, evaluation **registers rules** and their dependencies. After evaluation completes, `spaces` executes in dependency order.

{{% steps %}}

### Evaluate module code

Starlark runs normally (`load`, variable assignments, function calls, control flow).

### Register rules

Calls like `run_add_exec(...)` and `checkout_add_repo(...)` register graph nodes instead of executing commands.

### Execute the graph

After all relevant modules are evaluated, `spaces` runs rules in dependency order and can parallelize independent nodes.

{{% /steps %}}

### Rules mode example

```python {filename="build-and-test.spaces.star"}
load("//@star/prelude/rules/run.star", "run_add_exec")

run_add_exec(
    name = "build",
    command = "cargo",
    args = ["build", "--release"],
)

run_add_exec(
    name = "test",
    command = "cargo",
    args = ["test"],
    deps = [":build"],
)
```

When you run `spaces run //<path>:test`, `spaces` executes `build` first, then `test`.

## Execution mode (`*.exec.star`)

In execution mode, built-ins execute **immediately** while the file is evaluated.

{{% steps %}}

### Evaluate top-to-bottom

Statements run in order, like a shell script.

### Execute calls immediately

`sh_capture(...)`, `process_exec(...)`, and similar APIs run now and return values now.

### Continue with returned values

Subsequent logic can branch based on live command output.

{{% /steps %}}

### Execution mode example

```python {filename="status.exec.star"}
load("//@star/prelude/exec/sh.star", "sh_capture", "sh_exit_code")
load("//@star/prelude/exec/log.star", "log_info")

branch = sh_capture("git rev-parse --abbrev-ref HEAD")
log_info("Current branch: " + branch)

if sh_exit_code("git diff --quiet") != 0:
    log_info("Uncommitted changes detected")
else:
    log_info("Working directory is clean")
```

All commands above run during evaluation of `status.exec.star`.

## Comparison

| Aspect | Rules mode (`*.spaces.star`) | Execution mode (`*.exec.star`) |
|---|---|---|
| Execution model | Deferred graph planning, then execution | Immediate execution during evaluation |
| Parallelism | Yes, for independent graph nodes | No graph-driven parallelism |
| Incrementality | Supports dependency-aware reuse/skips | Re-runs each statement each time |
| Primary API namespace | [Rules](/docs/reference/@star/prelude/rules) | [Exec](/docs/reference/@star/prelude/exec) |
| Typical use | Build/test/checkouts and durable workflows | Scripting, probes, and one-off automation |

## Choosing the right mode

- Choose **rules mode** when outcomes should be reproducible, dependency-aware, and scalable across teams.
- Choose **execution mode** when you need direct command execution and immediate control-flow decisions.
- It is normal to use both in one workspace: rules for durable workflows, exec scripts for operational tasks.

{{< details title="Common pitfall: mixing mode-specific APIs" closed="true" >}}
`*.spaces.star` modules should use rules APIs (for example, `run.*`, `checkout.*`).

`*.exec.star` modules should use exec APIs (for example, `sh.*`, `process.*`, `fs.*`).

If you call a rules API in execution mode (or vice versa), `spaces` will error complaining the built-in is missing.
{{< /details >}}

## See also

- [Rules APIs](/docs/reference/@star/sdk/star)
- [Execution APIs](/docs/reference/@star/prelude/exec)
