---
title: Labels and Paths
toc: true
weight: 5
---

`spaces` uses labels for paths and rules similar to Bazel. Labels can be relative to the spaces module (`*spaces.star` file) or prefixed with `//` to be relative to the workspace root. Rule labels include a `:` in place of `spaces.star` to indicate a rule within a spaces module.

Examples:

- `//spaces/src` refers to the folder `spaces/src` relative to the workspace root.
- `//spaces/src:my_rule` refers to the rule `my_rule` within the `spaces/src/spaces.star` module.
- `//spaces/src/tools:my_tool` refers to the rule `my_tool` within the `spaces/src/tools.spaces.star` module.
- `:my_build_rule` refers to the rule `my_build_rule` within the spaces module where it is declared.
- `tools:my_tool` refers to the rule `my_tool` within the `tools.spaces.star` module relative to the calling spaces module.

## Where are labels applied?

Labels are always used when:

- `load()` statements
- The `working_directory` field in rules
- Referring to rules
  - dependencies
  - visibility 
  - `spaces run <rule>`
  - `spaces inspect <rule>`
- Specifying file paths or globs for dependencies

Labels are never used:

- The for `command` or `args` fields in exec rules (these should rely on the `working_directory` field instead)
- In environment variables

### `load()` Paths

By convention, the [SDK](https://github.com/work-spaces/sdk) is loaded into the workspace at `@star/sdk`. Functions can be loaded from the SDK. For example:

```python
load("//@star/sdk/star/info.star", "info_set_minimum_version")
info_set_minimum_version("0.15.28")
```

Within `run.star` which is a sibling of `info.star`, `load()` can use a relative path:

```python
load("info.star", "info_set_minimum_version")
```

### `working_directory` Labels

The example below shows how `spaces` treats the `working_directory` value in run rules.

```python
load("//@star/sdk/star/run.star", "run_add_exec")

# Run in the same directory as the containing file
run_add_exec(
  "list_directory",
  command = "ls", # this does NOT use a label
  args = [], # args DO NOT use labels
  working_directory = "."
)

# Execute in the workspace build folder
run_add_exec(
  "list_build_directory",
  command = "ls",
  working_directory = "//build"
)

# The default is to execute in the workspace root
run_add_exec(
  "list_workspace_directory",
  command = "ls",
)
```

### Rule Labels

If the above rules are defined in the workspace at `my-project/spaces.star`, they are run using the commands below. `[.]spaces.star` is converted to `:`.

```sh
# from workspace root
spaces run //my-project:list_directory
cd my-project
spaces run :list_directory
```

If the rules are in `my-project/show.spaces.star`, they are run using:

```sh
# from workspace root
spaces run //my-project/show:list_directory
cd my-project
spaces run show:list_directory
```
