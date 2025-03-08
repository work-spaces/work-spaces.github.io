---
title: Writing Rules
toc: true
weight: 4
---

`spaces` rules are written in `starlark`. `starlark` is a dialect of python. `starlark` symbols originate from three sources:

- The [standard starlark specification](https://github.com/bazelbuild/starlark/blob/master/spec.md)
- [builtins](/docs/builtins/) that call `rust` functions within the `spaces` binary.
  - built-ins have function wrappers defined in the [SDK](/docs/@star/sdk/)
- `load()` statements that import variables or functions from other starlark scripts
  - `load()` paths can either be relative to the current `star` file or prefixed with `//` to refer to the workspace root.

### Understanding Paths

Paths for `load()`, `working_directory` and rule names can be either relative to the spaces file where they are declared or relative to the workspace root. Paths prefixed with `//` are always relative to the workspace.

#### `load()` Paths

By convention, the [SDK](https://github.com/work-spaces/sdk) is loaded into the workspace at `@star/sdk`. Functions can be loaded from the SDK. For example:

```python
load("//@star/sdk/star/info.star", "info_set_minimum_version")

info_set_minimum_version("0.14.6")
```

Within `run.star` which is a sibling of `info.star`, `load()` can use a relative path:

```python
load("info.star", "info_set_minimum_version")
```

#### `working_directory` Paths

The example below shows how `spaces` treats the `working_directory` value in run rules.

```python
load("//@star/sdk/star/run.star", "run_add_exec")

# Run in the same directory as the containing file
run_add_exec(
  "list_directory",
  command = "ls",
  working_directory = "."
)

# To execute in the workspace build folder:
run_add_exec(
  "list_build_directory",
  command = "ls",
  working_directory = "//build"
)

# The default behavior is to execute in the workspace root
run_add_exec(
  "list_workspace_directory",
  command = "ls",
)
```

#### Rule Paths

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

### Adding Checkout Rules

Checkout rules are executing using `spaces checkout`. This command processes multiple scripts. 

The first script processed cannot use any `load()` statements because there is no code in the workspace. The first script is conventionally called `preload` and loads the starlark SDK into the workspace using built-in functions. A typical `preload.spaces.star` script looks like this:

```python

# This is a built-in function. It calls into the rust code.
# There is a wrapper for this function in sdk/star/checkout.star called
# checkout_add_repo()
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

Once the `preload` script is processed, subsequent scripts can use the starlark files that are now available in the workspace. The most common way to add source code is using `checkout_add_repo()`. Here is an example:

```python
load("//@star/sdk/star/checkout.star", "checkout_add_repo", "checkout_clone_blobless")

checkout_add_repo(
  "spaces",                # name of the rule and location of the repo in the workspace
  url = "https://github.com/work-spaces/spaces", # url to clone
  clone = checkout_clone_blobless(),  # use a blobless clone
  rev = "main" 
)
```

### Adding Run Rules

The most common run rule is to execute a shell command using `run_add_exec()`.

```python
load("//@star/sdk/star/run.star", "run_add_exec", "run_log_level_app")

run_add_exec(
  "show",                         # name of the rule
  command = "ls",                 # command to execute in the shell
  args = ["-alt"],                # arguments to pass to ls
  working_directory = ".",        # execute in the directory where this rule is
                                  #   default is to execute at the workspace root
  deps = ["another_rule"],        # run this rule after `another_rule` completes
  log_level = run_log_level_app() # Show the output of the rule to the user
)
```

If you run `spaces run :show` in the same directory that this rule is defined, it will execute the `show` rule after all dependencies have been executed.