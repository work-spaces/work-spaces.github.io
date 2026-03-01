---
title: Writing Rules
toc: true
weight: 4
---

`spaces` rules are written in `starlark`, a dialect of python. `starlark` symbols originate from three sources:

- The [standard starlark specification](https://github.com/bazelbuild/starlark/blob/master/spec.md)
- [Builtins](/docs/builtins/) that call `rust` functions within the `spaces` binary
  - Built-ins have function wrappers defined in the [SDK](/docs/@star/sdk/)
- `load()` statements that import variables or functions from other starlark scripts
  - `load()` paths can either be relative to the current `star` file or prefixed with `//` to refer to the workspace root

## Spaces Starlark Lexicon

- **Module**: a `*spaces.star` file evaluated when running `spaces`, or a `.star` file defining functions that can be imported with `load()`
- **Rule**: a definition within a **Module** that specifies a task. Use `deps` to define inputs and `targets` to define outputs
- **Label**: a workspace path to a file or **Rule**. `//` refers to the workspace root; `:` replaces `spaces.star` when referring to a **Rule** within a **Module**. Canonical forms:
  - **Rule**: `//<path to spaces.star file>:<rule name>`
  - path: `//<path in workspace>`
  - relative labels are converted internally to canonical form
- **Target**: files created by a **Rule**. A **Rule** can have multiple named targets, each defining a set of output files. **Target** names are scoped within the **Rule**
- **Dependencies** (`deps`): inputs to a **Rule**. These can be files (specified as globs), other **Rules**, or specific **Targets** defined by **Rules**

## Understanding Labels and Paths

Paths for `load()`, `working_directory`, and rule names use labels. They can be either relative to the spaces file where they are declared or prefixed with `//` to be relative to the workspace root.

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
  command = "ls",
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

## Adding Checkout Rules

Checkout rules are executed using `spaces checkout-repo`. As described in [Using spaces](/docs/using-spaces/), `spaces` evaluates **module** files in lexicographical order. A typical `0.checkout.spaces.star` script looks like this:

```python
# checkout.add_repo() is a built-in function.
# checkout_add_repo() in sdk/star/checkout.star is a convenience wrapper.
checkout.add_repo(
    rule = {"name": "@star/sdk"},
    repo = {
        "url": "https://github.com/work-spaces/sdk",
        "rev": "v0.3.5",
        "checkout": "Revision",
        "clone": "Default"
    }
)

checkout.add_repo(
    rule = {"name": "@star/packages"},
    repo = {
        "url": "https://github.com/work-spaces/packages",
        "rev": "v0.2.5",
        "checkout": "Revision",
        "clone": "Default"
    }
)
```

Once the initial checkout module is evaluated, subsequent modules can `load` function modules from the workspace. The most common way to add source code is using `checkout_add_repo()`:

```python
load("//@star/sdk/star/checkout.star", "checkout_add_repo", "checkout_clone_blobless")

checkout_add_repo(
  "printer",                # name of the rule and location of the repo in the workspace
  url = "https://github.com/work-spaces/spaces-printer",
  clone = checkout_clone_blobless(),
  rev = "main"
)
```

## Adding Run Rules

The most common run rule is to execute a command using `run_add_exec()`.

```python
load("//@star/sdk/star/run.star", "run_add_exec", "run_log_level_app")

run_add_exec(
  "show",                         # name of the rule
  command = "ls",                 # command to execute in the shell
  args = ["-alt"],                # arguments to pass to ls
  working_directory = ".",        # execute in the directory where this rule is
                                  #   default is to execute at the workspace root
  deps = [":another_rule"],       # another rule in the same module file
  log_level = run_log_level_app() # show the output of the rule to the user
)
```

Running `spaces run :show` in the same directory as this rule will execute the `show` rule after all dependencies have completed.
