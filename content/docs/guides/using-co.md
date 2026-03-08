---
title: Using Spaces Co
toc: true
weight: 4
---

`spaces co` is a shortcut for `spaces checkout-repo` and `spaces checkout`. Instead of typing long command-line arguments, you define your workspaces in a `co.spaces.toml` file and check them out by name. Repos checked out with `new-branch` become [dev branches](/docs/explainers/understanding-dev-branches/) — see [Understanding Dev Branches](/docs/explainers/understanding-dev-branches/) for how `spaces sync` interacts with them.

## File Format

`co.spaces.toml` is a TOML file where each top-level defines a `spaces` checkout. The value is either a `Repo` or `Workflow` entry.

### Repo Entries

A `Repo` entry checks out a single repository using `spaces checkout-repo`:

```toml
[my-project.Repo]
url = "https://github.com/my-org/my-project"  # required
rev = "main"                                    # required
```

Optional fields:

| Field | Description |
|---|---|
| `new-branch` | List of branch names to create as [dev branches](/docs/explainers/understanding-dev-branches/#creating-dev-branches). |
| `rule-name` | Override the checkout rule name (defaults to the workspace name). |
| `env` | List of `KEY=VALUE` strings to set as environment variables during checkout. |
| `store` | Key-value pairs passed to the spaces store configuration. |
| `create-lock-file` | Set to `true` to generate a lock file during checkout. |

Full example:

```toml
[my-project.Repo]
url = "https://github.com/my-org/my-project"
rev = "main"
rule-name = "my-project"
new-branch = ["my-project"]
env = ["SERIAL=unknown", "DEBUG=1"]
create-lock-file = true
```

### Workflow Entries

A `Workflow` entry runs `spaces checkout` with a named workflow or a list of scripts:

```toml
# Use a named workflow (the value is a label — see Labels and Paths)
[zephyr-stm32.Workflow]
workflow = "workflows:zephyr-stm32"

# Use explicit scripts
[ninja-build-dev.Workflow]
script = ["workflows/preload", "workflows/ninja-build"]
new-branch = ["//ninja-build:ninja-build"]
```

| Field | Description |
|---|---|
| `workflow` | A workflow [label](/docs/explainers/labels-and-paths/) to run (mutually exclusive with `script`). |
| `script` | A list of script paths to pass as `--script` arguments (mutually exclusive with `workflow`). Scripts are evaluated in [order](/docs/explainers/checkout-evaluation-order/). |
| `new-branch` | List of branch names to create as [dev branches](/docs/explainers/understanding-dev-branches/#creating-dev-branches). |
| `env` | List of `KEY=VALUE` strings to set as environment variables during checkout. |
| `store` | Key-value pairs passed to the spaces store configuration. |
| `create-lock-file` | Set to `true` to generate a lock file during checkout. |

## Example co.spaces.toml

Here is a `co.spaces.toml` that defines several repo checkouts and workflow checkouts:

```toml
# --- Repo Checkouts ---

[spaces-dev.Repo]
url = "https://github.com/work-spaces/spaces"
rev = "main"
new-branch = ["spaces"]
env = ["SPACES_INSTALL_ROOT=/opt/spaces"]

[printer.Repo]
url = "https://github.com/work-spaces/spaces-printer"
rev = "main"
rule-name = "printer"
new-branch = ["printer"]


# --- Workflow Checkouts ---

[ninja-build.Workflow]
workflow = "workflows:ninja-build"

[ninja-build-dev.Workflow]
script = ["workflows/preload", "workflows/ninja-build"]
new-branch = ["//ninja-build:ninja-build"]
```

Check out any entry by name:

```sh
# Check out the spaces source with a new branch
spaces co spaces-dev do-some-spaces-development

# Run the ninja-build workflow
spaces co ninja-build

# Run the ninja-build-dev workflow with explicit scripts
spaces co ninja-build-dev
```

## When to Use Repo vs Workflow

Use **Repo** when you want to check out a repository that contains its own `*spaces.star` checkout [modules](/docs/explainers/spaces-starlark-lexicon/). The repository's modules are [evaluated automatically](/docs/explainers/checkout-evaluation-order/), pulling in all dependencies, tools, and configuration. This is the most common case.

Use **Workflow** when the checkout is defined by standalone scripts or a named workflow rather than a single repository. This is useful for repos that don't have spaces modules. See [Checkout Evaluation Order](/docs/explainers/checkout-evaluation-order/#checkout-workflow-example) for details on how scripts are processed.
