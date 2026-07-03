---
title: What is Spaces?
description: Spaces is a Rust-powered tool for building reproducible polyrepo workspaces with Starlark.
toc: true
weight: 2
---

`spaces` is a tool for building **reproducible workspaces** in polyrepo environments. You define repos, tools, archives, config files, and tasks in Starlark modules, and `spaces` assembles and runs everything in a deterministic dependency graph.

{{< callout type="important" icon="sparkles" >}}
Same inputs, same workspace: every contributor on every platform gets a consistent environment.
{{< /callout >}}

## Why teams use Spaces

- **Reproducibility first**: pinned repos, pinned tools, pinned archives.
- **Fast onboarding**: no custom bootstrap scripts or ad-hoc environment setup.
- **Polyrepo-friendly**: compose many repositories into one coherent workspace.
- **Efficient execution**: dependency-aware parallelism and incremental work skipping.

## Rust runtime + Starlark configuration

- **Rust** powers the runtime: git operations, archive downloads, content-addressed storage, graph resolution, and parallel execution.
- **[Starlark](/docs/explainers/spaces-starlark-lexicon/)** is the configuration language: deterministic, hermetic, and readable.

You write `*.spaces.star` files with rules like `checkout.add_repo()` and `run.add_exec()`. `spaces` evaluates those rules, builds a dependency graph, and executes it.

{{< details title="Why Starlark constraints matter" >}}
Starlark intentionally avoids ambient I/O, unbounded loops, and mutable global state. These constraints make workspace definitions predictable and reproducible across machines.
{{< /details >}}

## Single statically linked binary

`spaces` ships as a **single statically linked binary**:

- **Simple deployment**: copy one file and run.
- **No runtime dependencies**: works on a fresh OS install.
- **Cross-platform**: macOS (`x86_64`, `aarch64`), Linux (`x86_64`, `aarch64`), Windows (`x86_64`).

## Two phases: checkout and run

### Checkout phase

Checkout rules define **what enters the workspace**:

- Repositories cloned at pinned revisions.
- Archives (`.tar`, `.zip`) verified by SHA256.
- Platform-specific tools installed into `<workspace>/sysroot/bin`.
- Generated assets (IDE settings, configs, environment scripts).

### Run phase

Run rules define **what happens in the workspace**:

- Build
- Test
- Pre-commit checks
- One-time setup
- Clean tasks

`spaces` executes independent rules in parallel and skips unchanged work when dependencies/targets allow caching.

{{% steps %}}

### Assemble the workspace

Run checkout to materialize pinned repos, tools, archives, and generated assets.

### Enter the workspace

Work inside the generated folder so tools and paths are consistent.

### Execute tasks

Run the default target set or specific labels like test/build.

{{% /steps %}}

```bash {filename="Terminal"}
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

Checkout and run share the same Starlark files and [label system](/docs/explainers/labels-and-paths/). Tools installed during checkout are immediately available to run rules.

## The Spaces store

All downloaded archives and tools are saved in a **content-addressed store** at `~/.spaces/store`, keyed by SHA256.

- If an artifact already exists, download is skipped.
- Artifacts are **hard-linked** into workspaces instead of copied.
- Multiple workspaces can share the same tool/archive bytes without duplicating disk usage.

{{< callout type="info" >}}
Workspace assembly is fast because it reuses verified artifacts from the store whenever possible.
{{< /callout >}}

## At a glance

| Aspect | Details |
|---|---|
| **Purpose** | Reproducible workspaces for polyrepo environments |
| **Implementation** | Rust runtime, Starlark configuration |
| **Distribution** | Single statically linked binary |
| **Checkout rules** | Assemble repos, tools, archives, and config via dependency graph |
| **Run rules** | Execute build/test/automation rules with graph-based parallelism |
| **Storage** | Content-addressed store with hard links for speed and deduplication |
| **Platforms** | macOS, Linux, Windows (native binaries) |
