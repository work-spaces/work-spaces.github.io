---
title: What is spaces?
toc: true
weight: 2
---

`spaces` is a tool for building **reproducible workspaces** in a polyrepo environment. It is a single, statically linked binary powered by Rust and configured with Starlark.

You describe your workspace — repos, tools, archives, config files, and tasks — in Starlark [modules](/docs/explainers/spaces-starlark-lexicon/). `spaces` evaluates those modules, assembles a self-contained workspace folder, and executes tasks through a dependency graph. Every contributor, on every platform, gets the exact same environment.

## Rust and Starlark

- **Rust** powers the core runtime: git operations, archive downloads, content-addressed storage, dependency graph resolution, and parallel task execution.
- **[Starlark](/docs/explainers/spaces-starlark-lexicon/)** is the configuration language — a deterministic, hermetic dialect of Python originally designed by Google for Bazel. It's readable and familiar, but intentionally limited (no I/O, no unbounded loops, no mutable global state) so workspace definitions are always reproducible.

You write `*.spaces.star` files that call functions like `checkout.add_repo()` and `run.add_exec()`. `spaces` evaluates them, builds a dependency graph, and executes it.

## Single Statically Linked Binary

`spaces` ships as a **single, statically linked binary** — no runtime, no virtual environment, no container image.

- **Trivial deployment.** Copy the binary to a machine and you're done.
- **No dependencies.** Runs on a fresh OS install.
- **Cross-platform.** Native binaries for macOS (x86_64, aarch64), Linux (x86_64, aarch64), and Windows (x86_64).

## Two Phases: Checkout and Run

`spaces` operates in two phases, each driven by rules that form a dependency graph.

### Checkout Rules — Assembling the Workspace

Checkout rules define **what goes into the workspace**:

- **Repositories** — git repos cloned at pinned revisions.
- **Archives** — tarballs and zip files identified by SHA256 hash.
- **Tools** — platform-specific binaries placed into `<workspace>/sysroot/bin`.
- **Assets** — files generated from Starlark strings (IDE settings, config files, environment scripts).

Rules are evaluated in dependency order. The first checkout module adds the [Starlark SDK](https://github.com/work-spaces/sdk); subsequent modules `load()` functions from it to add tools, archives, and more repos. Each checked-out repo can contain its own checkout modules, creating a recursive, ordered evaluation. See [Checkout Evaluation Order](/docs/explainers/checkout-evaluation-order/) for details.

The result is a workspace folder with pinned source code, exact tool versions in `sysroot/bin`, and configuration files in place — all without modifying anything outside the workspace.

#### The Spaces Store

All downloaded archives and tools live in a **content-addressed store** at `~/.spaces/store`, keyed by SHA256 hash. If an artifact is already in the store, the download is skipped. Artifacts are **hard-linked** into the workspace rather than copied, so assembly is fast and multiple workspaces sharing the same tool version consume disk space only once.

### Run Rules — Executing Tasks

Run rules define **what happens in the workspace**:

- **Build** — compile source code.
- **Test** — validate behavior.
- **Pre-commit** — enforce formatting and linting.
- **Setup** — one-time initialization.
- **Clean** — remove generated artifacts.

`spaces` resolves the dependency graph and executes independent rules **in parallel**. Rules can declare file inputs and targets, enabling caching — unchanged work is skipped automatically.

### The Two Phases Together

```sh
# Checkout — assemble the workspace
spaces checkout-repo \
  --url=https://github.com/my-org/my-project \
  --rev=main \
  --name=my-workspace

cd my-workspace

# Run — execute tasks
spaces run          # all default rules
spaces run //:test  # run tests
```

Checkout and run rules share the same Starlark files and [label system](/docs/explainers/labels-and-paths/). Tools installed during checkout are immediately available to run rules — no `PATH` hacks, no activation scripts.

## At a Glance

| Aspect | Details |
|---|---|
| **Purpose** | Reproducible workspaces for polyrepo environments |
| **Implementation** | Rust core, Starlark configuration |
| **Distribution** | Single statically linked binary |
| **Checkout rules** | Dependency graph assembling repos, tools, archives, and config |
| **Run rules** | Dependency graph executing build, test, and other tasks in parallel |
| **Storage** | Content-addressed store with hard links — fast and deduplicated |
| **Platforms** | macOS, Linux, Windows — native binaries, no containers |
