---
title: Labels and Paths
toc: true
weight: 5
---

`spaces` uses labels to refer to paths and rules, similar to Bazel. Labels are either:

- **Absolute**: prefixed with `//`, relative to the workspace root.
- **Relative**: resolved from the current spaces module (`*spaces.star` file).

A `:` separates the module path from a rule name within that module.

| Label | Refers to |
|---|---|
| `//spaces/src` | The folder `spaces/src` in the workspace. |
| `//spaces/src:my_rule` | The rule `my_rule` in `spaces/src/spaces.star`. |
| `//spaces/src/tools:my_tool` | The rule `my_tool` in `spaces/src/tools.spaces.star`. |
| `:my_build_rule` | The rule `my_build_rule` in the current module. |
| `tools:my_tool` | The rule `my_tool` in `tools.spaces.star` relative to the current module. |

## Where Labels Apply

Labels are used in:

- `load()` statements
- `working_directory` fields
- Rule references (`deps`, `visibility`, `spaces run <rule>`, `spaces inspect <rule>`)
- File path globs for inputs and dependencies

Labels are **not** used in `command`, `args`, or environment variable values. These are plain strings — use `working_directory` to control where commands execute.

## `load()` Paths

By convention, the [SDK](https://github.com/work-spaces/sdk) is checked out at `@star/sdk`. Load functions from it with an absolute label:

```python
load("//@star/sdk/star/info.star", "info_set_minimum_version")
info_set_minimum_version("0.15.28")
```

Within a sibling file (e.g. `run.star` loading from `info.star` in the same directory), use a relative path:

```python
load("info.star", "info_set_minimum_version")
```

## `working_directory` Labels

```python
load("//@star/sdk/star/run.star", "run_add_exec")

# Relative to the containing module's directory
run_add_exec("list_here", command = "ls", working_directory = ".")

# Absolute — the workspace's build folder
run_add_exec("list_build", command = "ls", working_directory = "//build")

# Default (omitted) — the workspace root
run_add_exec("list_root", command = "ls")
```

## Rule Labels

Given rules defined in `my-project/spaces.star`:

```sh
# from workspace root
spaces run //my-project:list_here
# from within my-project/
spaces run :list_here
```

If the rules are in `my-project/show.spaces.star`:

```sh
# from workspace root
spaces run //my-project/show:list_here
# from within my-project/
spaces run show:list_here
```
