---
title: Labels and Paths
description: Learn how `spaces` resolves absolute and relative labels for rules, modules, and working directories.
toc: true
weight: 5
---

`spaces` uses label syntax (similar to Bazel) to reference modules, rules, and workspace paths. Once you know how labels resolve, it becomes much easier to write `load()` statements, `deps`, and `spaces run` targets correctly.

{{< callout type="important" >}}
A label has two parts: a **module path** and an optional **rule name** separated by `:`.
{{< /callout >}}

## Label anatomy

| Label | Meaning |
|---|---|
| `//spaces/src` | Workspace path `spaces/src`. |
| `//spaces/src:my_rule` | Rule `my_rule` in `spaces/src/spaces.star`. |
| `//spaces/src/tools:my_tool` | Rule `my_tool` in `spaces/src/tools.spaces.star`. |
| `:my_build_rule` | Rule `my_build_rule` in the current module. |
| `tools:my_tool` | Rule `my_tool` in `tools.spaces.star`, relative to the current module. |

## Absolute vs relative labels

- **Absolute labels** start with `//` and resolve from the workspace root.
- **Relative labels** resolve from the current `*.spaces.star` module.

### Concrete example

Assume you are in `my-project/spaces.star`.

From the workspace root:

```sh
spaces run //my-project:list_here
spaces run //my-project/show:list_here
```

From inside `my-project/`:

```sh
spaces run :list_here
spaces run show:list_here
```

## Where labels are used

You will commonly use labels in:

- `load()` statements
- `working_directory`
- Rule references like `deps` and `visibility`
- CLI targets like `spaces run <rule>` and `spaces inspect <rule>`
- File globs used for rule inputs/dependencies

{{< callout type="warning" >}}
`command`, `args`, and environment variable values are plain strings, not labels.
Use `working_directory` to control where commands execute.
{{< /callout >}}

## `load()` paths

By convention, the SDK is checked out at `@star/sdk`.

```python
load("//@star/sdk/star/info.star", "info_set_minimum_version")
info_set_minimum_version("0.15.28")
```

For sibling files in the same directory, use a relative path:

```python
load("info.star", "info_set_minimum_version")
```

## `working_directory` resolution

```python
load("//@star/sdk/star/run.star", "run_add_exec")

# Relative to this module's directory
run_add_exec("list_here", command = "ls", working_directory = ".")

# Relative path from this module's directory
run_add_exec("list_tools", command = "ls", working_directory = "tools")

# Absolute workspace path
run_add_exec("list_build", command = "ls", working_directory = "//build")

# Default (omitted): workspace root
run_add_exec("list_root", command = "ls")
```

{{< details title="Common mistakes" closed="true" >}}

- Forgetting `//` when you mean a workspace-root absolute label.
- Using `:rule` from the wrong module directory.
- Putting labels in `command` or `args` (they are not label-aware).

{{< /details >}}

## See also

- [Adding Run Rules](/docs/guides/adding-run-rules/)
- [Operating Modes](/docs/explainers/operating-modes/)