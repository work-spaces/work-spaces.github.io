---
title: Spaces Starlark Lexicon
toc: true
weight: 4
---

- **Module**: a `*spaces.star` file evaluated when running `spaces`
  - **Function Module**: `.star` file defining functions that can be imported with `load()`
- **Rule**: a definition within a **Module** that specifies a task.
  - `deps` define the inputs to the rule as either files (specified as globs), other **Rules**
  - `targets` defines the outputs of the rule. These will become file deps for dependent rule.
  - `checkout` rules run during `spaces checkout...` and `spaces sync`
  - `run` rules become part of the workspace dependency graph and are executed when running `spaces run <rule>` or if the rule is a dependency of `<rule>`.
- **Label** [More Info](labels-and-paths.md): a workspace path to a file or **Rule**. `//` refers to the workspace root; `:` replaces `spaces.star` when referring to a **Rule** within a **Module**. Canonical forms:
  - **Rule**: `//<path to spaces.star file>:<rule name>`
  - path: `//<path in workspace>`
  - relative labels are converted internally to canonical form
- **Target**: files or directory contentscreated by a **Rule**.
- **Dependencies** (`deps`): inputs to a **Rule**. These can be files (specified as globs), other **Rules**, or specific **Targets** defined by **Rules**
- **Visibility**: rule visibility allows developers to control which rules are exposed to other modules.
  - Private **Visibility**: rules are only visible within the same **Module**.
  - Public **Visibility**: rules are visible to all **Modules**.
  - Rules **Visibility**: rules are available to a list of matching rule prefixes only.
- **Workspace**: the folder that is created when running `spaces checkout...` that is populated from the specified rules.
  - **Member** A repository or achive that is checked out and made available to the workspace.
