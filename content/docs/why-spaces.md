---
title: Why spaces?
toc: true
weight: 2
---

How do you ensure everyone who checks out your code has all the same tools and dependencies?

Some common options include: 

- Docker. Put all the tools and dependencies in a container and you are set.
- Monorepos. Commit all source code to one big repo. 
  - Use additional tools like `nix` or `dotslash` to manage executables.
- Use your build system (e.g. `cmake`) to download and build depedencies
- Package managers such as `apt`, `brew`, or `choco`.
- Metabuild options such as `bitbake` or `buildstream`.

Finding the right one is challenging. 

`spaces` is a lightweight solution that lets you create a workspace with:

- Code you need to develop
- Source and/or binary dependencies
- Executable tools

Downloaded artifacts are hashed and managed in the `spaces` store for efficient sharing across projects.

`spaces` is a single binary. It is powered by `starlark` and `rust`. `starlark` is a python dialect that lets you write expressive rules to:

- `checkout` source code and tools to your workspace
- `run` tasks based on a dependency graph

All workflows use the same commands:

```sh
spaces checkout --workflow=<workflow directory>:<workflow name> --name=<workspace folder name>
cd <workspace folder name>
spaces run //<path to rule>:<rule name>

# you can do inner-loop developement from the command line in the `spaces run` environment using
source ./env
```

Here is an abbreviated example from the spaces [workflows repo](https://github.com/work-spaces/workflows/).

```python
# load the rust script from the sysroot repository
# // indicates the workspace root.
load("//@star/packages/star/rust.star", "rust_add")
load("//@star/sdk/star/checkout.star", "checkout_add_repo")
load("//@star/sdk/star/run.star", "run_add_exec")

# Checkout the spaces repo
checkout_add_repo(
    "spaces",
    url = "https://github.com/work-spaces/spaces",
    rev = "main",
)

# Grab the rust toolchain
rust_add("rust_toolchain", "1.80")

run_add_exec(
    "build_spaces",
    command = "cargo",
    working_directory = "spaces",
    args =  [
        "build",
        "--profile=release",
    ],
)
```