---
title: Why spaces?
toc: true
weight: 1
---

## The Problem

How do you ensure everyone who checks out your code has the same tools and dependencies?

Most teams cobble together a mix of READMEs, setup scripts, and tribal knowledge. New contributors spend hours (or days) getting a working environment. CI pipelines diverge from local setups. Subtle version mismatches cause bugs that are impossible to reproduce.

## Common Approaches

### Docker / Dev Containers

Containers solve reproducibility by isolating everything in an image. However:

- **Heavy abstraction.** You're running a full Linux userspace, even on macOS and Windows. File I/O through bind mounts is slow, especially on macOS.
- **IDE friction.** Editors need special extensions or remote connections to work inside containers.
- **Not composable.** Combining tools from different images requires building a new image.
- **Linux-only builds.** If you need to build or test natively on macOS or Windows, containers don't help.

### Monorepos (with Bazel, Buck, etc.)

Committing all source to a single repository and using a hermetic build system is powerful but comes with trade-offs:

- **All or nothing.** Every project must adopt the monorepo's build system and conventions.
- **Scaling overhead.** Large monorepos require specialized tooling for checkout, indexing, and CI.
- **Steep learning curve.** Build systems like Bazel have significant complexity — `BUILD` files, `WORKSPACE` rules, toolchain resolution, and remote execution.

### Nix / Guix

Nix provides reproducible environments through a functional package manager:

- **Steep learning curve.** The Nix language and ecosystem are difficult to learn.
- **Large store.** Nix stores every dependency variant, consuming significant disk space.
- **Opaque builds.** Understanding what Nix is doing requires deep knowledge of derivations.
- **Linux-centric.** macOS support exists but is a second-class citizen.

### Package Managers (apt, brew, choco)

System package managers are convenient but problematic for development:

- **Global state.** Installing a package changes system state for all projects, creating conflicts.
- **Version pinning is fragile.** Two projects that need different versions of the same tool clash.
- **Not reproducible.** `brew install cmake` gives you whatever version is current, not what your project requires.

### Build System Dependency Management (CMake FetchContent, Cargo, etc.)

Language-specific tools handle their own ecosystem well but:

- **Single-language scope.** They don't manage tools outside their ecosystem (formatters, linters, code generators).
- **No workspace concept.** They manage build dependencies, not the broader development environment.

## How spaces Is Different

`spaces` is a lightweight workspace manager — a single, statically linked binary — that gives you:

| Capability | How spaces does it |
|---|---|
| **Reproducible tools** | Binary archives are downloaded by SHA256 hash and hard-linked from a content-addressed store into your workspace `sysroot`. |
| **Multi-repo checkout** | Assemble a workspace from multiple git repositories, each at a pinned revision. |
| **Cross-platform** | Works natively on macOS (x86_64, aarch64), Linux (x86_64), and Windows (x86_64). |
| **Task execution** | Run builds, tests, and pre-commit checks through a dependency graph with parallel execution. |
| **Composable** | Starlark rules are just functions. Packages like `rust_add()` and `cmake_add()` encapsulate complex setup behind simple calls. |
| **Efficient storage** | Downloaded artifacts are SHA256-hashed and stored once in `~/.spaces/store`. Multiple workspaces share the same binaries via hard links. |
| **IDE integration** | Checkout rules can populate `.vscode/settings.json`, `.zed/settings.json`, and other config so your IDE works immediately. |

## How It Works

`spaces` executes starlark scripts in two phases:

1. **Checkout**: assemble a workspace — git repos, binary tools, archives, and configuration files.
2. **Run**: execute tasks (build, test, format, deploy) through a dependency graph.

All workflows follow the same pattern:

```sh
spaces checkout-repo \
  --url=<git-repo-url> \
  --name=<workspace-folder-name> \
  --rev=main
cd <workspace-folder-name>
spaces run
```

For example, checking out and building the `spaces` source code:

```sh
spaces checkout-repo \
  --url=https://github.com/work-spaces/spaces \
  --rev=main \
  --new-branch=spaces \
  --name=issue-x-fix-something
cd issue-x-fix-something
spaces run //spaces:check
```

The checkout step creates a self-contained workspace folder. Inside, `sysroot/bin` contains the exact tool versions your project needs — isolated from the system and from other workspaces.
