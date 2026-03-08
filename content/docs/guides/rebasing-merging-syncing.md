---
title: Rebasing, Merging, and Syncing
toc: true
weight: 4
---

To keep your workspace up to date with the latest changes from `main`, you can rebase or merge your [dev branch](/docs/explainers/understanding-dev-branches/) onto `main`, then run [`spaces sync`](/docs/explainers/understanding-dev-branches/#how-spaces-sync-works).

1. **Create a workspace with a dev branch** for the repo you're working on:

    ```sh
    spaces co my-project fix-the-bug
    cd fix-the-bug
    ```

    See [Using spaces co](/docs/guides/using-co/) for details on `co.spaces.toml`.

2. **Develop normally** — make changes, commit, push on your dev branch.

3. **Rebase or merge and sync** — if a teammate pushes changes that modify the checkout rules (e.g. a pinned SDK version or adds a new dependency), run:

    ```sh
    git fetch origin main
    git rebase origin/main
    spaces sync
    ```

4. **Run builds and tests** as usual:

    ```sh
    spaces run //my-project:build
    spaces run //:test
    ```


## Multiple Dev Branches

You can create [dev branches](/docs/explainers/understanding-dev-branches/#creating-dev-branches) in multiple repos within the same workspace. Pass multiple entries in `new-branch`:

```sh
spaces checkout-repo \
  --url=https://github.com/my-org/my-workspace \
  --rev=main \
  --new-branch=my-lib \
  --new-branch=my-app \
  --name=cross-cutting-change
```

Or in `co.spaces.toml`:

```toml
[cross-cutting.Repo]
url = "https://github.com/my-org/my-workspace"
rev = "main"
new-branch = ["my-lib", "my-app"]
```

Both `my-lib` and `my-app` are treated as dev branches and will be [skipped during `spaces sync`](/docs/explainers/understanding-dev-branches/#how-spaces-sync-works).

## Promoting a Repo to a Dev Branch

Run `spaces sync --dev-branch=<path to the repo in the workspace>` to promote a repo to a dev branch. This will prevent spaces from syncing that repo, treating it as a dev branch for the life of the workspace.
