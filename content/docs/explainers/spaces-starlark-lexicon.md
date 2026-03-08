---
title: Spaces Starlark Lexicon
toc: true
weight: 4
---

- **Workspace**: the folder created by `spaces checkout` that contains all source code, tools, and configuration for a project.
  - **Member**: a repository or archive checked out into the workspace.
- **Module**: a `*spaces.star` file evaluated by `spaces`.
  - **Function Module**: a `.star` file that defines reusable functions imported with `load()`.
- **Rule**: a named definition within a module that specifies a task.
  - **Checkout rules** run during `spaces checkout` and `spaces sync`.
  - **Run rules** are executed via `spaces run <rule>` or as dependencies of other run rules.
- **Label**: a path that refers to a file or rule in the workspace. `//` is the workspace root; `:` separates a module path from a rule name. See [Labels and Paths](labels-and-paths.md) for details.
- **Dependencies** (`deps`): inputs to a rule. These can be file globs, other rules, or specific targets.
- **Target**: files or directories created by a rule. Targets become file dependencies for downstream rules.
- **Visibility**: controls which rules are allowed to depend on a given rule.
  - **Private**: only visible within the same module.
  - **Public**: visible to all modules.
  - **Rules**: visible only to a specified list of rules.