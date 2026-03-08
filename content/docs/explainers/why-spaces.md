---
title: Why spaces?
toc: true
weight: 1
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
spaces checkout-repo \
  --url=<git-repo-url> \
  --name=<workspace folder name> \
  --rev=main
cd <workspace folder name>
spaces run //<path to rule>:<rule name>
```

Here is an example of checking out and running `cargo check` on the `spaces` source code:

```sh
spaces checkout-repo \
  --url=https://github.com/work-spaces/spaces \
  --rev=main \
  --new-branch=spaces \
  --name=issue-x-fix-something
cd issue-x-fix-something
spaces run //spaces:check
```
