---
title: Repo Checkout and Sync
description: Understand how checkout creates repository state and how sync plans, updates, and reconciles repos over time.
toc: true
weight: 3
---

`spaces checkout-repo` sets up the initial repositories in a workspace. `spaces sync` re-evaluates checkout rules and updates repositories. Users can mark repositorires for development using development branches (**dev-branch**) to allow the branches to diverge from the checkout rules.

## Checkout: Create a New Workspace

`spaces checkout-repo` clones the root repo and evaluates top-level `[*.]spaces.star` files contained in the repo which can add more repos to the workspace.

{{< callout type="info" >}}
See [the checkout evaluation order guide](/docs/explainers/checkout-evaluation-order) for more details on how checkout transitively evaluations spaces starlark modules.
{{< /callout >}}

{{< callout type="info" >}}
`spaces co` is a shortcut that loads checkout settings from `co.spaces.toml`. This allows users to re-create complex workspaces. See [the guide](/docs/guides/using-co).
{{< /callout >}}

### Creating Development Branches

When you pass `--new-branch=<path to repo>`, `spaces` creates a local branch for that repo and treats it as a **dev-branch** in later sync operations.

```sh
spaces checkout-repo \
  --name=fix-parser-bug \
  --url=https://github.com/work-spaces/spaces \
  --rev=main \
  --new-branch=spaces
```

In this example:

- `spaces` is checked out from `main`.
- A local branch named `fix-parser-bug` is created in the workspace for the `spaces` repo.
- That repo is now treated as a **dev-branch** during `sync`.

```mermaid
---
title: New Branch Checkout
---
gitGraph
   commit
   commit id: "checkout-repo commit"
   branch fix-parser-bug
   checkout fix-parser-bug 
   commit
   commit
   checkout main
   commit
```

## Syncing the Workspace with Upstream Changes

For a monorepo, developers use `git pull` with rebase or merge to synchronize to upstream changes. With `spaces`, a `git pull` can affect the checkout rules causing the state of the workspace go go stale. Additionally, the workspace may have multiple repos that all need to be pulled.

`spaces sync` is used in place of `git pull`. `spaces sync` will rebase or merge **dev-branches** in the workspace, re-run the checkout rules, and report the changes.

| Case | Default sync behavior |
|---|---|
| Dev-branch repo | Rebases on target origin. |
| Repo pinned to a branch/tag/commit. | Checkout the rev and pull if a branch. |

```mermaid
---
title: Sync Dev Branch
---
gitGraph
   commit
   commit id: "checkout-repo commit"
   branch fix-parser-bug
   checkout fix-parser-bug 
   commit
   commit
   checkout main
   commit
   commit
   checkout fix-parser-bug
   merge main id: "rebase on sync"
   commit
   commit
   checkout main
   commit
   commit
```

{{< callout type="info" >}}
During sync evalution, a repo's target revision can change based on rules (for example, branch -> tag, or tag/commit -> branch).
{{< /callout >}}


### Dev-branch Controls

By default, **dev-branches** are rebased. You can override this per repo or globally:

- `--merge=<repo-path>`: merge instead of rebase.
- `--no-rebase-repo=<repo-path>`: skip both rebase and merge for that repo.
- `--no-rebase`: skip rebase for all **dev-branch** repos (unless explicitly listed in `--merge`).

{{< callout type="warning" >}}
**Dev-branch** rebases/merges require a valid base reference. If a repo is on a local dev branch but the configured `rev` is a tag/commit (not a branch), pass `--dev-branch-base=<repo-path>=<ref>` so `sync` knows what to rebase or merge against.
{{< /callout >}}

## Sync lifecycle

{{% steps %}}

### Pre-Evaluation Verification

`spaces` collects status for all repos and validates the planned operations.

Validation includes:
- Can **dev-branches** be rebased/merged without conflicts?
- Are all repos clean?
- Are local branches associated with upstream branches?

### Pre-Evaluation Execution

- Stash changes to dirty repos (if `--stash` specified).
- Rebase/merge **dev-branches** to the upstream target branches

### Evaluation: Evaluate and Execute Checkout Rules

Evaluation re-evaluates `spaces` modules file-by-file:

1. Evaluate one module and build/refresh its graph.
2. Execute that graph.
3. Scan any newly checked-out repos for more modules.
4. Repeat for the next module.

### Post-Evalution Execution

`spaces` re-collects repo status and pops stashes (if `--stash`).

If evaluation of the spaces starlark modules removed a repository from the workspace, the repository will be deleted during post-evalution. Repositories are only deleted if they have no local changes or commits.

### Post-Evaluation Reporting

`spaces` prints a report of how all the repos changed in the workspace.

{{% /steps %}}

{{< details title="Customize Sync Behavior" >}}

- Use `--dry-run` to just run the pre-evaluation checks.
- Use `--skip-evaluation` to only run the pre-evaluation checks and execution
  - This is handy for creating a **dev-branch** without doing a full sync.
- Use `--skip-pre-evaluation` to skip pre-evaluation checks and evaluate the starlark rules.
- Use `--dev-branch=<path to repo>` to mark a repository as a **dev-branch**
  - Use `--dev-branch-base=<path to repo>=origin/<target remote branch>` to specify a target remote branch that is different from the `rev` set in the rules.
  - Use `--no-rebase` to skip rebasing of all **dev-branches**
  - Use `--no-repase-repo=<path to repo>` to skip rebasing a specific repo.
  - Use `--merge=<path to repo>` to merge instead of rebase.
- Use `--new-branch=<path to repo>` to mark a repository as a **dev-branch** and create a new branch using the workspace name.
  - If the rules specify a tag/commit for the `rev`, this will fail without also passing `--dev-branch-base=<repo>=origin/<branch>`
- Use `--stash` to stash changes on dirty repos during pre-evaluation execution and pop the changes during post-evaluation execution.

{{< callout type="warning" >}}
If your stashed changes include edits to checkout rules, those edits are **not** part of the sync execution. Sync is executed while the changes are stashed.
{{< /callout >}}

{{< /details >}}

## Sync Flow Chart

```mermaid
flowchart TD
  PPP[Pre-Eval planning] Nominal4@==> PSEC{Any Errors?}
  PSEC Nominal0@==> PSE[Pre-Eval Execution]
  PSE Nominal6@==> ME[Evaluate module]
  PSEC ==> |Error| PSF(Cannot Sync)
  ME Nominal1@==> RE[Execute graph for module]
  RE Nominal2@==> SNR[Scan new repos for modules]
  SNR Nominal3@==> MM{More modules?}
  MM ==>|Yes| ME
  MM Nominal7@==>|No| PSYNCE[Post-sync Execution - pop stashes]
  PSYNCE Nominal5@==> PSR[Report Changes]
  Nominal0@{ animation: fast }
  Nominal1@{ animation: fast }
  Nominal2@{ animation: fast }
  Nominal3@{ animation: fast }
  Nominal4@{ animation: fast }
  Nominal5@{ animation: fast }
  Nominal6@{ animation: fast }
  Nominal7@{ animation: fast }
```

## Practical command patterns

```sh
# Plan only (no repo changes)
spaces sync --dry-run

# Standard sync with auto-stash for dirty working trees
spaces sync --stash

# Dev branch: merge one repo, skip rebase for another
spaces sync \
  --merge=my-lib \
  --no-rebase-repo=my-app

# Dev branch created from a non-branch rev: provide explicit base
spaces sync --dev-branch=my-lib --dev-branch-base=my-lib=origin/main
```

## More Info

- Check live options with:

```sh
spaces co --help
spaces checkout-repo --help
spaces sync --help
```
