---
title: Using spaces
toc: true
weight: 1
---

`spaces` executes `starlark` scripts in two phases:

- Checkout Phase: collect everything from source code to tools into a workspace folder
  - `git` repos are checked out in the workspace (either direct clones or using worktrees)
  - Archives (including platform binaries) are downloaded to `$HOME/.spaces/store`. Contents are hardlinked to the workspace `sysroot`
- Run Phase: execute user-defined rules to build, test, run and/or deploy your project

## Spaces Starlark SDK

The `spaces` starlark [SDK](https://github.com/work-spaces/sdk) is added via a `preload` script during checkout. `spaces checkout` processes scripts in order. The first script cannot use `load` statements (since the workspace is empty), so it populates the SDK. Subsequent scripts can `load` functions from preceding scripts.

```sh
spaces checkout --script=preload --script=my-project --name=build-my-project
```

```python
# preload.spaces.star

# checkout.add_repo() is a built-in: use `spaces docs` to see documentation of built-in functions.
# checkout_add_repo() is a convenience wrapper defined in the SDK. Scripts that run after this one
# can use `load("//@star/sdk/star/checkout.star", "checkout_add_repo")` instead.
checkout.add_repo(
    rule = {"name": "@star/sdk"},  # stores this repo in the workspace at `@star/sdk`
                                   #   the `@star` folder is a conventional location for
                                   #   common, loadable starlark code
    repo = {
        "url": "https://github.com/work-spaces/sdk",
        "rev": "main",
        "checkout": "Revision",
        "clone": "Blobless"
    }
)
```

```python
# my-project.spaces.star

load("//@star/sdk/star/checkout.star", "checkout_add_repo")

# This is easier to use than checkout.add_repo() but isn't available in the initial script
checkout_add_repo(
  "my-project",
  url = "https://github.com/my-org/my-project",
  rev = "main"
)
```


## Run Phase

Run rules build a dependency graph of targets. Run rules have:

- A Rule:
  - `name`: the way to refer to this task when adding dependencies to other tasks
  - `deps`: explicit dependencies that must run before this task
  - `targets`: named collections of files that the rule creates.
- An Action:
  - For example, `run.add_exec()` adds a process (`command` and `args`) to the dependency graph

By default, `spaces run` executes all rules matching `//:all` plus their dependencies.

```sh
spaces run
# equivalent to
spaces run //:all
```

Execute a specific rule plus dependencies:

```sh
spaces run //my-project:build
```

To enter the `spaces` execution environment used by `spaces run`, use:

```sh
spaces shell
# or with completion for rules
spaces shell --completions
```
